import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_journal/core/utils/format_utils.dart';
import 'package:ride_journal/presentation/providers/ride_detail_provider.dart';
import 'package:ride_journal/presentation/widgets/ride_map_widget.dart';
import 'package:ride_journal/presentation/widgets/stat_tile.dart';

class RideDetailPage extends StatefulWidget {
  final String rideId;

  const RideDetailPage({super.key, required this.rideId});

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideDetailProvider>().loadRide(widget.rideId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride Details')),
      body: Consumer<RideDetailProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                provider.error!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final ride = provider.ride;
          if (ride == null) {
            return const Center(child: Text('Ride not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ride name and date
                Text(
                  ride.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  FormatUtils.formatDateTime(ride.startTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),

                // Map
                RideMapWidget(
                  routePoints: ride.routePoints,
                  height: 250,
                  expandable: true,
                  title: ride.name,
                ),
                const SizedBox(height: 24),

                // Stats grid
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StatTile(
                              icon: Icons.straighten,
                              label: 'Distance',
                              value: FormatUtils.formatDistance(
                                ride.distanceMeters,
                              ),
                            ),
                            StatTile(
                              icon: Icons.timer,
                              label: 'Duration',
                              value: FormatUtils.formatDuration(ride.duration),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StatTile(
                              icon: Icons.speed,
                              label: 'Avg Speed',
                              value: FormatUtils.formatSpeed(ride.avgSpeedKmh),
                            ),
                            StatTile(
                              icon: Icons.flash_on,
                              label: 'Max Speed',
                              value: FormatUtils.formatSpeed(ride.maxSpeedKmh),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StatTile(
                              icon: Icons.terrain,
                              label: 'Elevation',
                              value: FormatUtils.formatElevation(
                                ride.elevationGainMeters,
                              ),
                            ),
                            StatTile(
                              icon: Icons.route,
                              label: 'Points',
                              value: '${ride.routePoints.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _TimeRow(
                          label: 'Start Time',
                          value: FormatUtils.formatTime(ride.startTime),
                        ),
                        if (ride.endTime != null) ...[
                          const Divider(height: 20),
                          _TimeRow(
                            label: 'End Time',
                            value: FormatUtils.formatTime(ride.endTime!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;

  const _TimeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
