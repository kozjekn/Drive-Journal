import 'package:hive/hive.dart';
import 'package:ride_journal/core/error/exceptions.dart';
import 'package:ride_journal/data/datasources/local/auth_local_data_source.dart';

/// Sync bookkeeping: the pull cursor and which account the local ride store
/// belongs to.
///
/// The owner marker lives in Hive rather than secure storage because it has to be
/// readable before auth resolves and has to survive alongside the `rides` box —
/// including the case where the app was killed before `logout()` ran.
class SyncLocalDataSource {
  static const String boxName = 'sync_meta';
  static const String _ownerKey = 'rides_owner_user_id';

  final Box<dynamic> _box;
  final AuthLocalDataSource _authLocalDataSource;

  SyncLocalDataSource(this._box, this._authLocalDataSource);

  Future<String?> getRidesOwnerUserId() async =>
      _box.get(_ownerKey) as String?;

  Future<void> saveRidesOwnerUserId(String userId) async =>
      _box.put(_ownerKey, userId);

  /// Per-user key, so re-logging in as a different account cannot inherit a
  /// stale cursor and silently skip that account's rides.
  Future<DateTime?> getLastSyncAt(String userId) async {
    try {
      final scoped = _box.get(_lastSyncKey(userId)) as String?;
      if (scoped != null) return DateTime.parse(scoped);
      // Falls back to the pre-scoping location so an existing install keeps its
      // cursor instead of re-pulling everything once.
      return await _authLocalDataSource.getLastSyncAt();
    } catch (e) {
      throw DatabaseException('Failed to read last sync time: $e');
    }
  }

  Future<void> saveLastSyncAt(String userId, DateTime syncedAt) async {
    try {
      await _box.put(_lastSyncKey(userId), syncedAt.toUtc().toIso8601String());
      await _authLocalDataSource.saveLastSyncAt(syncedAt);
    } catch (e) {
      throw DatabaseException('Failed to save last sync time: $e');
    }
  }

  Future<void> clearLastSyncAt(String userId) async =>
      _box.delete(_lastSyncKey(userId));

  Future<void> clear() async => _box.clear();

  static String _lastSyncKey(String userId) => 'last_sync_at:$userId';
}
