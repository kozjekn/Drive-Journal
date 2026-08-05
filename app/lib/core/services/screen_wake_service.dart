import 'package:flutter/foundation.dart' show debugPrint;
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen from turning off while recording.
///
/// On web this is the *only* mechanism available: no browser API can read GPS
/// while the document is hidden, so the best we can do is stop the screen from
/// sleeping in the first place. On Android and iOS it is a nice-to-have on top
/// of the real background tracking (stops the screen dimming on a handlebar
/// mount).
abstract class ScreenWakeService {
  /// Requests the lock and returns whether it is **actually** held.
  ///
  /// Do not assume success: the system may refuse or revoke the lock under
  /// battery saver, a non-secure context fails outright, and on an installed
  /// iOS PWA below iOS 18.4 the request resolves without holding anything
  /// (Apple bug — and the NoSleep.js video fallback is never reached, because
  /// `'wakeLock' in navigator` is already true from 16.4).
  Future<bool> acquire();

  Future<void> release();

  Future<bool> get isHeld;
}

class ScreenWakeServiceImpl implements ScreenWakeService {
  @override
  Future<bool> acquire() async {
    try {
      await WakelockPlus.enable();
      // Report the verified state, never the fact that enable() was called.
      return await WakelockPlus.enabled;
    } catch (e) {
      debugPrint('Screen wake lock unavailable: $e');
      return false;
    }
  }

  @override
  Future<void> release() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Failed to release screen wake lock: $e');
    }
  }

  @override
  Future<bool> get isHeld async {
    try {
      return await WakelockPlus.enabled;
    } catch (_) {
      return false;
    }
  }
}
