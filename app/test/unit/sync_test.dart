import 'package:flutter_test/flutter_test.dart';
import 'package:ride_journal/core/network/api_exceptions.dart';
import 'package:ride_journal/data/datasources/local/ride_local_data_source.dart';
import 'package:ride_journal/data/datasources/local/sync_local_data_source.dart';
import 'package:ride_journal/data/datasources/remote/ride_remote_data_source.dart';
import 'package:ride_journal/data/models/ride_model.dart';
import 'package:ride_journal/data/repositories/ride_repository_impl.dart';

/// In-memory stand-in for the Hive-backed ride store.
class _FakeRideLocal implements RideLocalDataSource {
  final Map<String, RideModel> rides = {};
  final Set<String> tombstones = {};

  @override
  Future<void> addTombstone(String id) async => tombstones.add(id);

  @override
  Future<void> clearAll() async => rides.clear();

  @override
  Future<void> clearTombstones() async => tombstones.clear();

  @override
  Future<void> deleteRide(String id) async => rides.remove(id);

  @override
  Future<List<RideModel>> getAllRides() async => rides.values.toList();

  @override
  Future<RideModel?> getRideById(String id) async => rides[id];

  @override
  Future<List<RideModel>> getPendingRides() async {
    final pending = rides.values.where((r) => r.isPendingSync).toList();
    pending.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return pending;
  }

  @override
  Future<List<String>> getTombstones() async => tombstones.toList();

  @override
  Future<void> removeTombstone(String id) async => tombstones.remove(id);

  @override
  Future<void> saveRide(RideModel ride) async => rides[ride.id] = ride;
}

/// Scriptable remote: queue up responses, or make a call throw.
class _FakeRideRemote implements RideRemoteDataSource {
  final List<SyncResponse> queuedResponses = [];
  final List<List<String>> pushedBatches = [];
  final List<DateTime?> sentCursors = [];
  final List<String> deletedIds = [];

  ApiException? syncError;
  ApiException? deleteError;

  /// Fails only on the Nth sync call (1-based); used to prove the cursor is not
  /// advanced on partial failure.
  int? failOnSyncCall;
  int syncCallCount = 0;

  @override
  Future<SyncResponse> syncRides(
    List<RideModel> localRides,
    DateTime? lastSyncAt,
  ) async {
    syncCallCount++;
    sentCursors.add(lastSyncAt);
    if (localRides.isNotEmpty) {
      pushedBatches.add(localRides.map((r) => r.id).toList());
    }
    if (syncError != null) throw syncError!;
    if (failOnSyncCall == syncCallCount) {
      throw ApiException('boom', statusCode: 500);
    }
    if (queuedResponses.isEmpty) {
      return SyncResponse(
        syncedAt: DateTime.utc(2026, 8, 3, 12),
        updatedRides: const [],
        deletedRideIds: const [],
        hasMore: false,
      );
    }
    return queuedResponses.removeAt(0);
  }

  @override
  Future<void> deleteRide(String id) async {
    if (deleteError != null) throw deleteError!;
    deletedIds.add(id);
  }

  @override
  Future<List<RideModel>> getAllRides() async => [];

  @override
  Future<RideModel?> getRideById(String id) async => null;

  @override
  Future<List<RideModel>> getFeed({int skip = 0, int limit = 20}) async => [];

  @override
  Future<List<RideModel>> getPublicRides(
    String userId, {
    int skip = 0,
    int limit = 20,
  }) async =>
      [];

  @override
  Future<void> saveRide(RideModel ride) async {}

  @override
  Future<void> updateRide(RideModel ride) async {}
}

RideModel buildRide({
  required String id,
  DateTime? updatedAt,
  DateTime? syncedAt,
  int routePointCount = 0,
}) {
  final updated = updatedAt ?? DateTime(2026, 8, 3, 10);
  return RideModel(
    id: id,
    name: 'Ride $id',
    distanceMeters: 1000,
    duration: const Duration(minutes: 10),
    avgSpeedKmh: 6,
    maxSpeedKmh: 12,
    elevationGainMeters: 0,
    startTime: DateTime(2026, 8, 3, 9),
    endTime: DateTime(2026, 8, 3, 9, 10),
    routePoints: const [],
    updatedAt: updated,
    syncedAt: syncedAt,
  );
}

void main() {
  late _FakeRideLocal local;
  late _FakeRideRemote remote;
  late RideRepositoryImpl repository;

  /// The sync-meta box is a plain map here; SyncLocalDataSource needs Hive, so
  /// the repository is given a tiny fake instead.
  late _FakeSyncLocal syncLocal;

  setUp(() {
    local = _FakeRideLocal();
    remote = _FakeRideRemote();
    syncLocal = _FakeSyncLocal();
    repository = RideRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      syncLocalDataSource: syncLocal,
      currentUserId: () async => 'user-1',
    );
  });

  group('saveRide', () {
    test('stores the ride even when the push fails (offline guarantee)',
        () async {
      remote.syncError = ApiException('No internet connection');
      await syncLocal.saveRidesOwnerUserId('user-1');

      await repository.saveRide(buildRide(id: 'r1').toEntity());
      // Let the fire-and-forget push settle.
      await Future<void>.delayed(Duration.zero);

      expect(local.rides.containsKey('r1'), isTrue);
      expect(local.rides['r1']!.isPendingSync, isTrue);
    });
  });

  group('syncRides', () {
    test('refuses to push when local rides belong to another account',
        () async {
      await syncLocal.saveRidesOwnerUserId('someone-else');
      local.rides['r1'] = buildRide(id: 'r1');

      final outcome = await repository.syncRides();

      expect(outcome.succeeded, isFalse);
      expect(remote.pushedBatches, isEmpty);
    });

    test('marks pushed rides synced using updatedAt, not now()', () async {
      await syncLocal.saveRidesOwnerUserId('user-1');
      final updatedAt = DateTime(2026, 8, 3, 10, 30);
      local.rides['r1'] = buildRide(id: 'r1', updatedAt: updatedAt);

      final outcome = await repository.syncRides();

      expect(outcome.succeeded, isTrue);
      expect(outcome.pushed, 1);
      // Equality with updatedAt is what makes "pending" immune to clock skew
      // against the server.
      expect(local.rides['r1']!.syncedAt, updatedAt);
      expect(local.rides['r1']!.isPendingSync, isFalse);
    });

    test('sends lastSyncAt so the server can do a delta pull', () async {
      await syncLocal.saveRidesOwnerUserId('user-1');
      final cursor = DateTime.utc(2026, 8, 1, 8);
      await syncLocal.saveLastSyncAt('user-1', cursor);

      await repository.syncRides();

      expect(remote.sentCursors, isNotEmpty);
      expect(remote.sentCursors.first, cursor);
    });

    test('does not advance the cursor when a push chunk fails', () async {
      await syncLocal.saveRidesOwnerUserId('user-1');
      final original = DateTime.utc(2026, 8, 1, 8);
      await syncLocal.saveLastSyncAt('user-1', original);
      local.rides['r1'] = buildRide(id: 'r1');
      remote.failOnSyncCall = 1;

      final outcome = await repository.syncRides();

      expect(outcome.succeeded, isFalse);
      // Advancing here would permanently skip anything the server changed in
      // between.
      expect(await syncLocal.getLastSyncAt('user-1'), original);
    });

    test('follows hasMore and applies every page', () async {
      await syncLocal.saveRidesOwnerUserId('user-1');
      remote.queuedResponses.addAll([
        SyncResponse(
          syncedAt: DateTime.utc(2026, 8, 2),
          updatedRides: [buildRide(id: 'server-1')],
          deletedRideIds: const [],
          hasMore: true,
        ),
        SyncResponse(
          syncedAt: DateTime.utc(2026, 8, 3),
          updatedRides: [buildRide(id: 'server-2')],
          deletedRideIds: const [],
          hasMore: false,
        ),
      ]);

      final outcome = await repository.syncRides();

      expect(outcome.succeeded, isTrue);
      expect(local.rides.keys, containsAll(['server-1', 'server-2']));
      expect(await syncLocal.getLastSyncAt('user-1'), DateTime.utc(2026, 8, 3));
    });

    test('pulled rides are not immediately pending again', () async {
      await syncLocal.saveRidesOwnerUserId('user-1');
      remote.queuedResponses.add(
        SyncResponse(
          syncedAt: DateTime.utc(2026, 8, 3),
          updatedRides: [buildRide(id: 'server-1')],
          deletedRideIds: const [],
          hasMore: false,
        ),
      );

      await repository.syncRides();

      expect(local.rides['server-1']!.isPendingSync, isFalse);
    });

    test('applies remote deletions locally', () async {
      await syncLocal.saveRidesOwnerUserId('user-1');
      local.rides['gone'] = buildRide(
        id: 'gone',
        syncedAt: DateTime(2026, 8, 3, 10),
      );
      remote.queuedResponses.add(
        SyncResponse(
          syncedAt: DateTime.utc(2026, 8, 3),
          updatedRides: const [],
          deletedRideIds: const ['gone'],
          hasMore: false,
        ),
      );

      await repository.syncRides();

      expect(local.rides.containsKey('gone'), isFalse);
    });

    test('drops a tombstone the server says is already gone', () async {
      await syncLocal.saveRidesOwnerUserId('user-1');
      await local.addTombstone('already-gone');
      remote.deleteError = ApiException('Not found', statusCode: 404);

      final outcome = await repository.syncRides();

      expect(outcome.succeeded, isTrue);
      expect(local.tombstones, isEmpty);
    });

    test('keeps a tombstone when the delete fails for another reason',
        () async {
      await syncLocal.saveRidesOwnerUserId('user-1');
      await local.addTombstone('retry-me');
      remote.deleteError = ApiException('Server error', statusCode: 500);

      final outcome = await repository.syncRides();

      expect(outcome.succeeded, isFalse);
      expect(local.tombstones, contains('retry-me'));
    });

    test('is single-flight: concurrent callers share one run', () async {
      await syncLocal.saveRidesOwnerUserId('user-1');

      await Future.wait([
        repository.syncRides(),
        repository.syncRides(),
        repository.syncRides(),
      ]);

      // One pull round trip, not three.
      expect(remote.syncCallCount, 1);
    });
  });

  group('deleteRide', () {
    test('records a tombstone before removing the local row', () async {
      await syncLocal.saveRidesOwnerUserId('user-1');
      local.rides['r1'] = buildRide(id: 'r1');
      remote.deleteError = ApiException('No internet connection');

      await repository.deleteRide('r1');
      await Future<void>.delayed(Duration.zero);

      expect(local.rides.containsKey('r1'), isFalse);
      // Something is left to retry from, unlike the old fire-and-forget delete.
      expect(local.tombstones, contains('r1'));
    });
  });

  group('bindToUser', () {
    test('wipes rides when the account changes', () async {
      await syncLocal.saveRidesOwnerUserId('other-user');
      local.rides['theirs'] = buildRide(id: 'theirs');

      await repository.bindToUser('user-1');

      expect(local.rides, isEmpty);
      expect(await syncLocal.getRidesOwnerUserId(), 'user-1');
    });

    test('wipes an unmarked store, covering the crash-before-logout case',
        () async {
      local.rides['unknown-owner'] = buildRide(id: 'unknown-owner');

      await repository.bindToUser('user-1');

      expect(local.rides, isEmpty);
    });

    test('keeps rides when the same user signs back in', () async {
      await syncLocal.saveRidesOwnerUserId('user-1');
      local.rides['mine'] = buildRide(id: 'mine');

      await repository.bindToUser('user-1');

      expect(local.rides.containsKey('mine'), isTrue);
    });
  });
}

/// Minimal SyncLocalDataSource replacement (the real one needs a Hive box).
class _FakeSyncLocal implements SyncLocalDataSource {
  String? _owner;
  final Map<String, DateTime> _cursors = {};

  @override
  Future<void> clear() async {
    _owner = null;
    _cursors.clear();
  }

  @override
  Future<void> clearLastSyncAt(String userId) async => _cursors.remove(userId);

  @override
  Future<DateTime?> getLastSyncAt(String userId) async => _cursors[userId];

  @override
  Future<String?> getRidesOwnerUserId() async => _owner;

  @override
  Future<void> saveLastSyncAt(String userId, DateTime syncedAt) async =>
      _cursors[userId] = syncedAt;

  @override
  Future<void> saveRidesOwnerUserId(String userId) async => _owner = userId;
}
