import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:ride_journal/domain/entities/sync_outcome.dart';
import 'package:ride_journal/domain/repositories/ride_repository.dart';

enum SyncState { idle, syncing, success, error }

/// Owns every sync trigger, so there is exactly one place that decides when to
/// talk to the server. The repository's own single-flight guard makes overlapping
/// triggers harmless.
class SyncProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// A resume shortly after a completed sync is not worth another round trip.
  static const Duration _resumeDebounce = Duration(seconds: 60);

  /// Backgrounding is the last chance to upload before the OS suspends us, so
  /// it gets a much shorter window — just long enough to absorb the
  /// hidden-then-paused double-fire some platforms emit.
  static const Duration _backgroundDebounce = Duration(seconds: 5);

  final RideRepository _rideRepository;

  SyncProvider(
    this._rideRepository, {
    bool observeLifecycle = true,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
  }

  /// Injectable so the debounce windows can be exercised without real waits.
  final DateTime Function() _now;

  bool _observingLifecycle = false;

  /// Set by [onSignedIn]. While null there is no account to sync, so lifecycle
  /// triggers stay quiet instead of reporting a "not signed in" error.
  String? _boundUserId;

  SyncState _state = SyncState.idle;
  int _pendingCount = 0;
  DateTime? _lastSyncAt;
  DateTime? _lastAttemptCompletedAt;
  String? _lastError;

  SyncState get state => _state;
  bool get isSyncing => _state == SyncState.syncing;
  int get pendingCount => _pendingCount;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastError => _lastError;

  /// Called on every authentication — including app start — so a device that
  /// still holds another account's rides is cleaned before anything is uploaded.
  Future<void> onSignedIn(String userId) async {
    _boundUserId = userId;
    await _rideRepository.bindToUser(userId);
    await refreshPendingCount();
    await sync(force: true);
  }

  Future<void> onSignedOut() async {
    _boundUserId = null;
    await _rideRepository.clearLocalData();
    _pendingCount = 0;
    _lastSyncAt = null;
    _lastError = null;
    _state = SyncState.idle;
    notifyListeners();
  }

  Future<void> refreshPendingCount() async {
    try {
      _pendingCount = await _rideRepository.pendingRideCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to count pending rides: $e');
    }
  }

  /// [debounce] overrides how recently a completed attempt suppresses this one;
  /// [force] skips the check entirely.
  Future<SyncOutcome> sync({bool force = false, Duration? debounce}) async {
    if (_boundUserId == null) return const SyncOutcome();

    if (!force && _lastAttemptCompletedAt != null) {
      final since = _now().difference(_lastAttemptCompletedAt!);
      if (since < (debounce ?? _resumeDebounce)) {
        return const SyncOutcome();
      }
    }

    _state = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    final outcome = await _rideRepository.syncRides();
    _lastAttemptCompletedAt = _now();

    if (outcome.succeeded) {
      _state = SyncState.success;
      _lastSyncAt = outcome.syncedAt ?? _now();
    } else {
      _state = SyncState.error;
      _lastError = outcome.error;
    }

    await refreshPendingCount();
    notifyListeners();
    return outcome;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        sync();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Best effort: the OS may suspend us mid-request. Nothing is lost if it
        // does — the ride stays in Hive marked pending and the next resume or
        // sign-in picks it up.
        sync(debounce: _backgroundDebounce);
      case AppLifecycleState.inactive:
        // Fires on every notification-shade pull and incoming call. Not a
        // signal that we are going away.
        break;
    }
  }

  @override
  void dispose() {
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}
