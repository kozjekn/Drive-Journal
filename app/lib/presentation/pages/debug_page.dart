import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final List<_LogEntry> _log = [];
  StreamSubscription<Position>? _streamSub;
  int _positionCount = 0;
  Position? _lastPosition;
  bool _streamActive = false;

  @override
  void initState() {
    super.initState();
    _runInitialChecks();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  void _addLog(String message, {bool isError = false}) {
    setState(() {
      _log.insert(0, _LogEntry(message: message, isError: isError));
    });
  }

  Future<void> _runInitialChecks() async {
    _addLog('Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');

    // Check location service
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _addLog('Location service enabled: $serviceEnabled', isError: !serviceEnabled);
    } catch (e) {
      _addLog('Location service check failed: $e', isError: true);
    }

    // Check permission
    try {
      final permission = await Geolocator.checkPermission();
      _addLog('Current permission: ${permission.name}',
          isError: permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever);
    } catch (e) {
      _addLog('Permission check failed: $e', isError: true);
    }
  }

  Future<void> _requestPermission() async {
    _addLog('Requesting permission...');
    try {
      final permission = await Geolocator.requestPermission();
      _addLog('Permission result: ${permission.name}',
          isError: permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever);
    } catch (e) {
      _addLog('Request permission failed: $e', isError: true);
    }
  }

  Future<void> _getCurrentPosition() async {
    _addLog('Getting current position...');
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      setState(() => _lastPosition = position);
      _addLog(
        'Position: ${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)} '
        '| alt: ${position.altitude.toStringAsFixed(1)}m '
        '| speed: ${position.speed.toStringAsFixed(1)}m/s '
        '| accuracy: ${position.accuracy.toStringAsFixed(1)}m',
      );
    } catch (e) {
      _addLog('getCurrentPosition failed: $e', isError: true);
    }
  }

  void _startBasicStream() {
    _stopStream();
    _addLog('Starting BASIC stream (LocationSettings, distanceFilter: 0)...');
    _positionCount = 0;
    _streamActive = true;

    _streamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen(
      (position) {
        _positionCount++;
        setState(() => _lastPosition = position);
        _addLog(
          '#$_positionCount | '
          '${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)} '
          '| spd: ${position.speed.toStringAsFixed(1)} '
          '| acc: ${position.accuracy.toStringAsFixed(1)}m',
        );
      },
      onError: (dynamic error) {
        _addLog('Basic stream ERROR: $error', isError: true);
      },
      onDone: () {
        _addLog('Basic stream DONE (closed)');
        setState(() => _streamActive = false);
      },
    );

    setState(() {});
  }

  void _startPlatformStream() {
    _stopStream();
    _addLog('Starting PLATFORM stream (${Platform.operatingSystem} settings)...');
    _positionCount = 0;
    _streamActive = true;

    LocationSettings settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Debug: GPS stream active',
          notificationTitle: 'Ride Tracker Debug',
          enableWakeLock: true,
        ),
      );
      _addLog('Using AndroidSettings with ForegroundNotificationConfig');
    } else if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
      _addLog('Using AppleSettings');
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      );
      _addLog('Using basic LocationSettings (unknown platform)');
    }

    try {
      _streamSub = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (position) {
          _positionCount++;
          setState(() => _lastPosition = position);
          _addLog(
            '#$_positionCount | '
            '${position.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)} '
            '| spd: ${position.speed.toStringAsFixed(1)} '
            '| acc: ${position.accuracy.toStringAsFixed(1)}m',
          );
        },
        onError: (dynamic error) {
          _addLog('Platform stream ERROR: $error', isError: true);
          setState(() => _streamActive = false);
        },
        onDone: () {
          _addLog('Platform stream DONE (closed)');
          setState(() => _streamActive = false);
        },
      );
    } catch (e) {
      _addLog('Platform stream FAILED to start: $e', isError: true);
      setState(() => _streamActive = false);
    }

    setState(() {});
  }

  void _stopStream() {
    if (_streamSub != null) {
      _streamSub?.cancel();
      _streamSub = null;
      _addLog('Stream stopped. Total positions: $_positionCount');
      setState(() => _streamActive = false);
    }
  }

  void _clearLog() {
    setState(() {
      _log.clear();
      _positionCount = 0;
      _lastPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLog,
            tooltip: 'Clear log',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status card
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _streamActive ? Icons.gps_fixed : Icons.gps_off,
                        color: _streamActive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _streamActive
                            ? 'Stream active — $_positionCount positions'
                            : 'Stream inactive',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  if (_lastPosition != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last: ${_lastPosition!.latitude.toStringAsFixed(6)}, '
                      '${_lastPosition!.longitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Alt: ${_lastPosition!.altitude.toStringAsFixed(1)}m | '
                      'Speed: ${_lastPosition!.speed.toStringAsFixed(1)}m/s | '
                      'Accuracy: ${_lastPosition!.accuracy.toStringAsFixed(1)}m',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _ActionChip(
                  label: 'Check Permission',
                  icon: Icons.shield,
                  onPressed: _requestPermission,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  label: 'Get Position',
                  icon: Icons.my_location,
                  onPressed: _getCurrentPosition,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  label: 'Basic Stream',
                  icon: Icons.play_arrow,
                  onPressed: _streamActive ? null : _startBasicStream,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  label: 'Platform Stream',
                  icon: Icons.play_circle,
                  onPressed: _streamActive ? null : _startPlatformStream,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  label: 'Stop',
                  icon: Icons.stop,
                  onPressed: _streamActive ? _stopStream : null,
                  color: Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Event log
          Expanded(
            child: _log.isEmpty
                ? Center(
                    child: Text(
                      'No events yet',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _log.length,
                    itemBuilder: (context, index) {
                      final entry = _log[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${entry.timestamp} ${entry.message}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: entry.isError
                                ? Colors.redAccent
                                : Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const _ActionChip({
    required this.label,
    required this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onPressed,
    );
  }
}

class _LogEntry {
  final String message;
  final bool isError;
  final String timestamp;

  _LogEntry({required this.message, this.isError = false})
      : timestamp = _formatTime(DateTime.now());

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}
