import 'package:hive/hive.dart';
import 'package:ride_journal/core/error/exceptions.dart';
import 'package:ride_journal/data/models/route_point_model.dart';
import 'package:ride_journal/domain/entities/route_point.dart';

/// A recording that was in progress when the app died.
class ActiveRideSnapshot {
  final String id;
  final String name;
  final DateTime startTime;
  final List<RoutePoint> points;

  /// How many `p$n` chunks were read. A resumed recording continues numbering
  /// from here so it never overwrites a chunk it just loaded.
  final int chunkCount;

  const ActiveRideSnapshot({
    required this.id,
    required this.name,
    required this.startTime,
    required this.points,
    required this.chunkCount,
  });

  /// The last fix we managed to persist. Used as `endTime` when saving as-is —
  /// `DateTime.now()` would inflate the duration by however long the app was
  /// closed.
  DateTime? get lastPointTime =>
      points.isEmpty ? null : points.last.timestamp;
}

/// Persists an in-progress recording so a process kill costs a few seconds
/// instead of the whole ride.
///
/// Deliberately a separate box from `rides`, written **append-only**:
///
/// * `RideAdapter.write` serialises the entire `routePoints` list, so flushing a
///   partial ride into `rides` would rewrite the whole growing track on every
///   flush — a full IndexedDB object rewrite each time on web.
/// * `RideLocalDataSource.getAllRides()` does no filtering and the sync push
///   picks up everything unsynced, so a partial ride would show in the list and
///   upload mid-ride.
/// * It means zero schema change to `Ride`/`RideModel`/the type adapters, so
///   existing stored rides carry no migration risk.
abstract class ActiveRideLocalDataSource {
  Future<void> begin({
    required String id,
    required String name,
    required DateTime startTime,
    int startingChunk = 0,
  });

  /// Appends one chunk. Exactly two `put`s, and never rewrites earlier chunks.
  Future<void> appendPoints(List<RoutePoint> points);

  Future<ActiveRideSnapshot?> load();

  Future<void> clear();
}

class ActiveRideLocalDataSourceImpl implements ActiveRideLocalDataSource {
  static const String boxName = 'active_ride';
  static const String _metaKey = 'meta';
  static const int _schemaVersion = 1;

  final Box<dynamic> _box;

  ActiveRideLocalDataSourceImpl(this._box);

  @override
  Future<void> begin({
    required String id,
    required String name,
    required DateTime startTime,
    int startingChunk = 0,
  }) async {
    try {
      if (startingChunk == 0) {
        await _box.clear();
      }
      await _box.put(_metaKey, <String, dynamic>{
        'v': _schemaVersion,
        'id': id,
        'name': name,
        'startTimeMs': startTime.millisecondsSinceEpoch,
        'chunkCount': startingChunk,
      });
    } catch (e) {
      throw DatabaseException('Failed to begin active ride: $e');
    }
  }

  @override
  Future<void> appendPoints(List<RoutePoint> points) async {
    if (points.isEmpty) return;
    try {
      final meta = _box.get(_metaKey) as Map<dynamic, dynamic>?;
      if (meta == null) return; // begin() was never called; nothing to append to.

      final chunkCount = (meta['chunkCount'] as int?) ?? 0;
      final serialised = points
          .map((p) => RoutePointModel.fromEntity(p).toMap())
          .toList(growable: false);

      // Order matters for crash safety: write the chunk BEFORE bumping the
      // count. A crash between the two loses the newest chunk but never leaves
      // a dangling reference.
      await _box.put('p$chunkCount', serialised);
      await _box.put(_metaKey, <String, dynamic>{
        ...Map<String, dynamic>.from(meta),
        'chunkCount': chunkCount + 1,
      });
    } catch (e) {
      throw DatabaseException('Failed to append active ride points: $e');
    }
  }

  @override
  Future<ActiveRideSnapshot?> load() async {
    try {
      final meta = _box.get(_metaKey) as Map<dynamic, dynamic>?;
      if (meta == null) return null;

      final id = meta['id'] as String?;
      final startMs = meta['startTimeMs'] as int?;
      if (id == null || startMs == null) return null;

      final points = <RoutePoint>[];
      // Walk chunks rather than trusting chunkCount, and stop at the first gap:
      // a crash mid-append can leave the count one behind the chunks on disk.
      var readChunks = 0;
      for (var i = 0;; i++) {
        final raw = _box.get('p$i');
        if (raw is! List) break;
        for (final entry in raw) {
          if (entry is Map) {
            points.add(RoutePointModel.fromMap(entry).toEntity());
          }
        }
        readChunks = i + 1;
      }

      return ActiveRideSnapshot(
        id: id,
        name: (meta['name'] as String?) ?? 'Recovered Ride',
        startTime: DateTime.fromMillisecondsSinceEpoch(startMs),
        points: points,
        chunkCount: readChunks,
      );
    } catch (e) {
      throw DatabaseException('Failed to load active ride: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.clear();
    } catch (e) {
      throw DatabaseException('Failed to clear active ride: $e');
    }
  }
}
