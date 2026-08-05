/// Result of one sync attempt. Reported to the UI so a failed upload is visible
/// instead of silent.
class SyncOutcome {
  final int pushed;
  final int pulled;
  final int deleted;
  final DateTime? syncedAt;
  final String? error;

  const SyncOutcome({
    this.pushed = 0,
    this.pulled = 0,
    this.deleted = 0,
    this.syncedAt,
    this.error,
  });

  const SyncOutcome.failed(String message) : this(error: message);

  bool get succeeded => error == null;

  bool get didAnything => pushed > 0 || pulled > 0 || deleted > 0;

  @override
  String toString() => succeeded
      ? 'SyncOutcome(pushed: $pushed, pulled: $pulled, deleted: $deleted)'
      : 'SyncOutcome(error: $error)';
}

/// Snapshot of what sync still has to do. Surfaced on the diagnostics page.
class SyncStatus {
  final List<String> pendingRideIds;
  final List<String> tombstoneIds;
  final DateTime? lastSyncAt;
  final String? ridesOwnerUserId;

  const SyncStatus({
    required this.pendingRideIds,
    required this.tombstoneIds,
    required this.lastSyncAt,
    required this.ridesOwnerUserId,
  });
}
