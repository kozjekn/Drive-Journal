import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_journal/presentation/pages/debug_page.dart';
import 'package:drive_journal/presentation/pages/record_ride_page.dart';
import 'package:drive_journal/presentation/pages/ride_detail_page.dart';
import 'package:drive_journal/presentation/providers/ride_list_provider.dart';
import 'package:drive_journal/presentation/widgets/ride_card.dart';

class RideListPage extends StatefulWidget {
  const RideListPage({super.key});

  @override
  State<RideListPage> createState() => _RideListPageState();
}

class _RideListPageState extends State<RideListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideListProvider>().loadRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'GPS Diagnostics',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const DebugPage())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RideListProvider>().loadRides(),
          ),
        ],
      ),
      body: Consumer<RideListProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadRides(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.rides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.two_wheeler,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No rides yet',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to start your first ride!',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadRides(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: provider.rides.length,
              itemBuilder: (context, index) {
                final ride = provider.rides[index];
                return RideCard(
                  ride: ride,
                  onTap: () => _navigateToDetail(ride.id),
                  onDismissed: () => provider.deleteRide(ride.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRecord,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Ride'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _navigateToDetail(String rideId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RideDetailPage(rideId: rideId)),
    );
  }

  Future<void> _navigateToRecord() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RecordRidePage()));
    // Refresh rides list when returning from recording
    if (mounted) {
      await context.read<RideListProvider>().loadRides();
    }
  }
}
