import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// One-time explanation of the browser's screen-off limitation.
///
/// This is not a workaround we chose not to build — no web API can read GPS
/// while the page is hidden. Service workers have no `geolocation` at all, and
/// Background Sync (Chromium-only, absent from Safari) runs in the worker
/// anyway. Keeping the screen awake is the whole of what is possible, so the
/// user has to know the rule.
class WebRecordingNotice {
  WebRecordingNotice._();

  static const String boxName = 'app_prefs';
  static const String _ackKey = 'web_recording_notice_ack';

  static Box<dynamic>? _box;

  /// Called during DI setup once the box is open.
  static void bindBox(Box<dynamic> box) => _box = box;

  static Future<bool> hasAcknowledged() async =>
      (_box?.get(_ackKey) as bool?) ?? false;

  static Future<void> _acknowledge() async =>
      _box?.put(_ackKey, true);

  /// Returns true if the user wants to go ahead and record.
  static Future<bool> show(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Recording in the browser has a limit'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your phone\'s browser stops giving apps your location as soon '
                'as the screen turns off. That is a rule of the operating '
                'system, not something Ride Journal can change.',
              ),
              SizedBox(height: 12),
              Text(
                'While recording, we\'ll try to keep your screen awake. Don\'t '
                'lock your phone or switch apps — if you do, recording pauses '
                'and you\'ll lose that part of the ride.',
              ),
              SizedBox(height: 12),
              Text(
                'Keeping the screen on for a long ride uses a lot of battery, '
                'so bring a charger. For rides where you want to pocket your '
                'phone, install the Android or iOS app.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Got it'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await _acknowledge();
      return true;
    }
    return false;
  }
}

/// Persistent strip shown while recording on web.
///
/// Reports the *verified* wake-lock state. On an installed iOS PWA below iOS
/// 18.4 the request succeeds but holds nothing (Apple bug), so claiming success
/// here would make the user trust the app and lose a ride.
class WebWakeLockStrip extends StatelessWidget {
  final bool held;

  const WebWakeLockStrip({super.key, required this.held});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: held ? theme.colorScheme.surface : Colors.orange.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            held ? Icons.lock_open : Icons.warning_amber,
            size: 16,
            color: held ? theme.colorScheme.primary : Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              held
                  ? 'Screen kept awake · keep the app open'
                  : 'Can\'t keep your screen awake on this device — locking it '
                      'will pause recording',
              style: TextStyle(
                fontSize: 12,
                color: held ? theme.colorScheme.onSurface : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
