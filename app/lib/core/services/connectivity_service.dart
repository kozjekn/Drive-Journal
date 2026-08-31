import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports when the device regains network access.
///
/// Deliberately narrow: callers get a bare "you are online again" tick rather
/// than the platform's connectivity enum, so nothing outside this file has to
/// know about connectivity_plus or reason about which transports count.
abstract class ConnectivityService {
  /// Emits on an offline -> online transition, and only on the transition.
  ///
  /// Edge-triggered on purpose: the platform re-emits the current state on
  /// subscribe and again on transport changes (Wi-Fi -> mobile, VPN up), none of
  /// which mean connectivity was restored.
  Stream<void> get onRestored;

  Future<void> dispose();
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;

  final StreamController<void> _restored = StreamController<void>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Assume online until told otherwise, so the first event after start-up only
  /// fires when the device genuinely came back from being offline.
  bool _offline = false;

  ConnectivityServiceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _sub = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  void _onChanged(List<ConnectivityResult> results) {
    // An empty list and an explicit `none` both mean no usable transport; the
    // plugin reports the former on some platforms and the latter on others.
    final offline = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);

    if (_offline && !offline) _restored.add(null);
    _offline = offline;
  }

  @override
  Stream<void> get onRestored => _restored.stream;

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _restored.close();
  }
}
