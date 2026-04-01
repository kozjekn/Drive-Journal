import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:drive_journal/core/utils/format_utils.dart';
import 'package:drive_journal/presentation/providers/record_ride_provider.dart';

class RecordRidePage extends StatelessWidget {
  const RecordRidePage({super.key});

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
      body: Consumer<RecordRideProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Live map
              Expanded(child: _LiveMap(provider: provider)),

              // Stats bar
              if (provider.state == RecordingState.recording)
                _StatsBar(provider: provider),

              // Control button
              _ControlButton(provider: provider),
            ],
          );
        },
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

class _LiveMap extends StatelessWidget {
  final RecordRideProvider provider;

  const _LiveMap({required this.provider});

  @override
  Widget build(BuildContext context) {
    final points = provider.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final center = points.isNotEmpty
        ? points.last
        : const LatLng(46.0569, 14.5058); // Default: Ljubljana

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 15),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.drivejournal.drive_journal',
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
        if (points.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: points.last,
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
          onPressed: () => provider.startRecording(),
          icon: const Icon(Icons.play_arrow, size: 28),
          label: const Text('Start Ride', style: TextStyle(fontSize: 18)),
        );
      case RecordingState.recording:
        return ElevatedButton.icon(
          onPressed: () async {
            final ride = await provider.stopRecording();
            if (ride != null && context.mounted) {
              Navigator.of(context).pop();
            }
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
          onPressed: () => provider.startRecording(),
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
