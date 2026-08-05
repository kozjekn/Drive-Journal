import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ride_journal/core/network/api_exceptions.dart';
import 'package:ride_journal/data/datasources/local/ride_local_data_source.dart';
import 'package:ride_journal/data/datasources/local/sync_local_data_source.dart';
import 'package:ride_journal/data/datasources/remote/ride_remote_data_source.dart';
import 'package:ride_journal/data/models/ride_model.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/entities/sync_outcome.dart';
import 'package:ride_journal/domain/repositories/ride_repository.dart';

class RideRepositoryImpl implements RideRepository {
  /// Rough JSON size of a ride, used to bound a push chunk. Ride size varies by
  /// three orders of magnitude (a 3h ride at 1Hz is ~11k points ≈ 1.6 MB), so
  /// chunking by a fixed count is not safe.
  static const int _bytesPerRoutePoint = 150;
  static const int _bytesPerRideOverhead = 400;
  static const int _maxChunkBytes = 4 * 1024 * 1024;

  /// Also the server's per-request cap (SyncRidesCommandValidator).
  static const int _maxChunkRides = 25;

  /// Backstop against a server that always reports `hasMore`.
  static const int _maxPullPages = 200;

  final RideLocalDataSource localDataSource;
  final RideRemoteDataSource remoteDataSource;
  final SyncLocalDataSource syncLocalDataSource;

  /// Resolves the signed-in user id. Injected as a callback rather than an
  /// AuthRepository dependency, which would point the data layer at auth.
  final Future<String?> Function() currentUserId;

  RideRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.syncLocalDataSource,
    required this.currentUserId,
  });

  Future<SyncOutcome>? _inFlight;

  @override
  Future<List<Ride>> getAllRides() async {
    final models = await localDataSource.getAllRides();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Ride?> getRideById(String id) async {
    final model = await localDataSource.getRideById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveRide(Ride ride) async {
    final model = RideModel.fromEntity(
      ride.copyWith(updatedAt: DateTime.now()),
    );
    // Local write first and it must succeed: this is what guarantees the ride is
    // never lost, online or off.
    await localDataSource.saveRide(model);

    // Best effort. A failure leaves syncedAt null, so the ride stays pending and
    // any later sync trigger retries it.
    unawaited(_pushBestEffort());
  }

  @override
  Future<void> deleteRide(String id) async {
    // Tombstone before the local delete, so a failed remote delete still has
    // something to retry from.
    await localDataSource.addTombstone(id);
    await localDataSource.deleteRide(id);
    unawaited(_pushBestEffort());
  }

  Future<void> _pushBestEffort() async {
    try {
      final outcome = await syncRides();
      if (!outcome.succeeded) {
        debugPrint('Background sync did not complete: ${outcome.error}');
      }
    } catch (e) {
      debugPrint('Background sync threw: $e');
    }
  }

  @override
  Future<int> pendingRideCount() async =>
      (await localDataSource.getPendingRides()).length;

  @override
  Future<SyncStatus> syncStatus() async {
    final owner = await syncLocalDataSource.getRidesOwnerUserId();
    return SyncStatus(
      pendingRideIds:
          (await localDataSource.getPendingRides()).map((r) => r.id).toList(),
      tombstoneIds: await localDataSource.getTombstones(),
      lastSyncAt:
          owner == null ? null : await syncLocalDataSource.getLastSyncAt(owner),
      ridesOwnerUserId: owner,
    );
  }

  @override
  Future<void> bindToUser(String userId) async {
    final stored = await syncLocalDataSource.getRidesOwnerUserId();
    if (stored == userId) return;

    // Covers both a normal account switch and the crash case where sign-out never
    // ran: an unmarked-but-non-empty store cannot be proven to belong to this
    // user, so it is not kept.
    await localDataSource.clearAll();
    await localDataSource.clearTombstones();
    if (stored != null) {
      await syncLocalDataSource.clearLastSyncAt(stored);
    }
    await syncLocalDataSource.clearLastSyncAt(userId);
    await syncLocalDataSource.saveRidesOwnerUserId(userId);
  }

  @override
  Future<void> clearLocalData() async {
    await localDataSource.clearAll();
    await localDataSource.clearTombstones();
    await syncLocalDataSource.clear();
  }

  @override
  Future<SyncOutcome> syncRides() {
    // Single-flight. Several triggers can fire at once (save, app resume,
    // pull-to-refresh), and overlapping runs would double-push and race on the
    // cursor.
    final existing = _inFlight;
    if (existing != null) return existing;

    final run = _syncImpl().whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<SyncOutcome> _syncImpl() async {
    final userId = await currentUserId();
    if (userId == null) {
      return const SyncOutcome.failed('Not signed in.');
    }

    final owner = await syncLocalDataSource.getRidesOwnerUserId();
    if (owner != userId) {
      // Refuse rather than upload rides that may belong to another account.
      return const SyncOutcome.failed(
        'Local rides are not bound to the signed-in account.',
      );
    }

    var pushed = 0;
    var pulled = 0;
    var deleted = 0;

    try {
      final startCursor = await syncLocalDataSource.getLastSyncAt(userId);

      // 1. Push deletions.
      for (final id in await localDataSource.getTombstones()) {
        try {
          await remoteDataSource.deleteRide(id);
          await localDataSource.removeTombstone(id);
          deleted++;
        } on ApiException catch (e) {
          if (e.statusCode == 404 || e.statusCode == 403) {
            // Already gone, or never ours. Nothing left to retry.
            await localDataSource.removeTombstone(id);
          } else {
            rethrow;
          }
        }
      }

      // 2. Push pending rides in size-bounded chunks.
      final pending = await localDataSource.getPendingRides();
      for (final chunk in _chunkForPush(pending)) {
        final response = await remoteDataSource.syncRides(chunk, startCursor);
        pulled += await _applyPull(response);
        for (final ride in chunk) {
          // The same response may have reported this ride as deleted elsewhere,
          // in which case _applyPull just removed it — re-saving it here would
          // resurrect it locally.
          if (await localDataSource.getRideById(ride.id) == null) {
            pushed++;
            continue;
          }
          // syncedAt = the pushed updatedAt, NOT now(): both then come from this
          // device's clock, so "pending" is immune to server clock skew.
          await localDataSource.saveRide(
            RideModel.fromEntity(
              ride.toEntity().copyWith(syncedAt: ride.updatedAt),
            ),
          );
          pushed++;
        }
      }

      // 3. Pull, following the server's cursor until it says there is no more.
      var cursor = startCursor;
      var pages = 0;
      while (pages < _maxPullPages) {
        final response = await remoteDataSource.syncRides(const [], cursor);
        pulled += await _applyPull(response);
        deleted += response.deletedRideIds.length;
        cursor = response.syncedAt;
        pages++;
        if (!response.hasMore) break;
      }

      // Advanced once, at the end. Advancing per page would mean a mid-sequence
      // failure permanently skips whatever the server changed in between.
      if (cursor != null) {
        await syncLocalDataSource.saveLastSyncAt(userId, cursor);
      }

      return SyncOutcome(
        pushed: pushed,
        pulled: pulled,
        deleted: deleted,
        syncedAt: cursor,
      );
    } on ApiException catch (e) {
      return SyncOutcome(
        pushed: pushed,
        pulled: pulled,
        deleted: deleted,
        error: e.message,
      );
    } catch (e) {
      return SyncOutcome(
        pushed: pushed,
        pulled: pulled,
        deleted: deleted,
        error: e.toString(),
      );
    }
  }

  /// Writes pulled rides and removes remotely-deleted ones. Returns how many
  /// rides were written.
  Future<int> _applyPull(SyncResponse response) async {
    for (final model in response.updatedRides) {
      await localDataSource.saveRide(
        RideModel.fromEntity(
          model.toEntity().copyWith(syncedAt: model.updatedAt),
        ),
      );
    }
    for (final id in response.deletedRideIds) {
      await localDataSource.deleteRide(id);
      // Our own tombstone for the same ride is now redundant.
      await localDataSource.removeTombstone(id);
    }
    return response.updatedRides.length;
  }

  static List<List<RideModel>> _chunkForPush(List<RideModel> rides) {
    final chunks = <List<RideModel>>[];
    var current = <RideModel>[];
    var currentBytes = 0;

    for (final ride in rides) {
      final size =
          ride.routePoints.length * _bytesPerRoutePoint + _bytesPerRideOverhead;
      final wouldExceed = current.isNotEmpty &&
          (currentBytes + size > _maxChunkBytes ||
              current.length >= _maxChunkRides);
      if (wouldExceed) {
        chunks.add(current);
        current = <RideModel>[];
        currentBytes = 0;
      }
      current.add(ride);
      currentBytes += size;
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }
}
