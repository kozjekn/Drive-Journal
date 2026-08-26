import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:ride_journal/core/services/location_service.dart';
import 'package:ride_journal/core/utils/format_utils.dart';
import 'package:ride_journal/di/injection.dart';
import 'package:ride_journal/presentation/providers/record_ride_provider.dart';
import 'package:ride_journal/presentation/widgets/web_recording_notice.dart';

/// Starts the recording, gated on web by the one-time screen-off explanation.
///
/// Shared by the auto-start in [_RecordRidePageState.initState] and the manual
/// start/retry buttons, so both paths behave identically.
Future<void> _beginRecording(
  BuildContext context,
  RecordRideProvider provider,
) async {
  // One-time explanation of the browser's screen-off limitation before the
  // first web recording.
  if (kIsWeb && !await WebRecordingNotice.hasAcknowledged()) {
    if (!context.mounted) return;
    final proceed = await WebRecordingNotice.show(context);
    if (!proceed || !context.mounted) return;
  }
  await provider.startRecording();
}

class RecordRidePage extends StatefulWidget {
  /// Begins recording as soon as the map is on screen, so "Start Ride" on the
  /// list is a single tap. False when arriving with a recording already running
  /// — resuming a recovered ride, for instance.
  final bool autoStart;

  const RecordRidePage({super.key, this.autoStart = true});

  @override
  State<RecordRidePage> createState() => _RecordRidePageState();
}

class _RecordRidePageState extends State<RecordRidePage> {
  @override
  void initState() {
    super.initState();
    if (!widget.autoStart) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<RecordRideProvider>();
      // Only from a standing start: a page opened over a live or recovered
      // recording must not restart it.
      if (provider.state != RecordingState.idle) return;
      _beginRecording(context, provider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Ride'),
        leading: Consumer<RecordRideProvider>(
          builder: (context, provider, _) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (provider.state == RecordingState.recording) {
                  final shouldLeave = await _showExitConfirmation(context);
                  if (shouldLeave && context.mounted) {
                    await provider.stopRecording();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
            );
          },
        ),
      ),
      body: Column(
        children: [
          // The map is intentionally OUTSIDE the Consumer below: it subscribes to
          // the provider itself, so the 1-second duration tick no longer rebuilds
          // the whole FlutterMap subtree.
          const Expanded(child: _LiveMap()),

          Consumer<RecordRideProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  if (provider.warning != null)
                    _WarningBanner(
                      message: provider.warning!,
                      onDismiss: provider.clearWarning,
                    ),

                  // Web can't track with the screen off. Say so, truthfully,
                  // based on whether the wake lock is actually held.
                  if (kIsWeb && provider.state == RecordingState.recording)
                    WebWakeLockStrip(held: provider.wakeLockHeld),

                  if (provider.state == RecordingState.recording)
                    _StatsBar(provider: provider),

                  _ControlButton(provider: provider),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Recording?'),
        content: const Text(
          'You have an active ride recording. '
          'Do you want to stop and save it before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop & Save'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// The live tracking map.
///
/// Stateful and owning a [MapController], because `MapOptions.initialCenter` is
/// read exactly once when flutter_map creates its state — the previous
/// stateless version recomputed a centre on every rebuild and threw it away,
/// leaving the camera pinned wherever it started.
class _LiveMap extends StatefulWidget {
  const _LiveMap();

  @override
  State<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<_LiveMap> {
  static const LatLng _fallbackCenter = LatLng(46.0569, 14.5058); // Ljubljana
  static const double _followZoom = 16.0;

  final MapController _mapController = MapController();

  /// Auto-follow, disabled as soon as the user pans so the camera stops
  /// fighting them, and restored by the re-centre button.
  bool _following = true;
  bool _mapReady = false;
  LatLng? _initialCenter;
  LatLng? _lastCentered;

  @override
  void initState() {
    super.initState();
    _seedInitialCenter();
  }

  /// Opens the map on the rider's actual position instead of the hardcoded
  /// fallback. The provider's stream has not produced a fix yet at this point.
  Future<void> _seedInitialCenter() async {
    final provider = context.read<RecordRideProvider>();
    final known = provider.lastPosition;
    if (known != null) {
      _applyCenter(LatLng(known.latitude, known.longitude));
      return;
    }
    try {
      final locationService = sl<LocationService>();
      // Auto-start requests permissions at the same moment; without waiting for
      // the grant this call loses the race, throws, and pins the camera on the
      // fallback. ensurePermissions only re-prompts while still denied.
      await locationService.ensurePermissions();
      final position = await locationService.getCurrentPosition();
      if (!mounted) return;
      _applyCenter(LatLng(position.latitude, position.longitude));
    } catch (_) {
      // No fix available (permission refused, indoors, web prompt pending).
      // Stay on the fallback; the stream will move us once it starts.
      if (!mounted) return;
      setState(() => _initialCenter ??= _fallbackCenter);
    }
  }

  /// `MapOptions.initialCenter` is read exactly once, so a fix that lands after
  /// the map is built has to move the camera explicitly.
  void _applyCenter(LatLng center) {
    setState(() => _initialCenter = center);
    if (!_mapReady || !_following) return;
    _lastCentered = null; // force the move
    _recenter(center);
  }

  void _recenter(LatLng target) {
    if (!_mapReady) return;
    // Skip no-op moves so a stationary rider doesn't churn the camera.
    if (_lastCentered == target) return;
    _lastCentered = target;
    _mapController.move(target, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordRideProvider>();

    final points = provider.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // Driven by the live position, not the thinned track, so the marker and
    // camera keep up even while points are being dropped.
    final live = provider.lastPosition;
    final livePoint = live != null
        ? LatLng(live.latitude, live.longitude)
        : (points.isNotEmpty ? points.last : null);

    if (_following && livePoint != null) {
      // Camera moves are side effects; defer past this build.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _recenter(livePoint));
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter ?? _fallbackCenter,
            initialZoom: _followZoom,
            keepAlive: true,
            onMapReady: () => _mapReady = true,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture && _following) {
                setState(() => _following = false);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dev.kozjek.ride',
            ),
            if (points.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    strokeWidth: 4.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            if (livePoint != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: livePoint,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        if (!_following)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              tooltip: 'Center on my location',
              onPressed: () {
                setState(() => _following = true);
                if (livePoint != null) {
                  _lastCentered = null; // force the move
                  _recenter(livePoint);
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _WarningBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.white),
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final RecordRideProvider provider;

  const _StatsBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LiveStat(
            label: 'Distance',
            value: FormatUtils.formatDistance(provider.distanceMeters),
          ),
          _LiveStat(
            label: 'Duration',
            value: FormatUtils.formatDuration(provider.elapsed),
          ),
          _LiveStat(
            label: 'Speed',
            value: FormatUtils.formatSpeed(provider.currentSpeedKmh),
          ),
        ],
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  final String label;
  final String value;

  const _LiveStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final RecordRideProvider provider;

  const _ControlButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: _buildButton(context),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    switch (provider.state) {
      case RecordingState.idle:
        return ElevatedButton.icon(
          onPressed: () => _beginRecording(context, provider),
          icon: const Icon(Icons.play_arrow, size: 28),
          label: const Text('Start Ride', style: TextStyle(fontSize: 18)),
        );
      case RecordingState.recording:
        return ElevatedButton.icon(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final ride = await provider.stopRecording();
            if (ride == null) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  ride.isPendingSync
                      ? 'Ride saved — will upload when you\'re online'
                      : 'Ride saved and uploaded',
                ),
              ),
            );
            navigator.pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.stop, size: 28),
          label: const Text('Stop Ride', style: TextStyle(fontSize: 18)),
        );
      case RecordingState.saving:
        return const Center(child: CircularProgressIndicator());
      case RecordingState.error:
        return ElevatedButton.icon(
          onPressed: () => _beginRecording(context, provider),
          icon: const Icon(Icons.refresh, size: 28),
          label: Text(
            provider.error ?? 'Error - Tap to retry',
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        );
    }
  }
}
