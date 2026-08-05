import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_journal/presentation/pages/debug_page.dart';
import 'package:ride_journal/presentation/pages/record_ride_page.dart';
import 'package:ride_journal/presentation/pages/ride_detail_page.dart';
import 'package:ride_journal/presentation/providers/record_ride_provider.dart';
import 'package:ride_journal/presentation/providers/ride_list_provider.dart';
import 'package:ride_journal/presentation/widgets/ride_card.dart';
import 'package:ride_journal/presentation/widgets/unfinished_ride_card.dart';

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
      // Local read for instant first paint; sync happens via SyncProvider and
      // pull-to-refresh.
      context.read<RideListProvider>().loadRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Diagnostics',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const DebugPage())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync now',
            onPressed: () => context.read<RideListProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<RideListProvider>(
        builder: (context, provider, child) {
          // Only take over the screen on a genuinely empty first load — the old
          // unconditional spinner replaced the list on every refresh and hid the
          // RefreshIndicator.
          if (provider.isLoading && provider.rides.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.rides.isEmpty) {
            return _ErrorState(
              message: provider.error!,
              onRetry: provider.refresh,
            );
          }

          // RefreshIndicator wraps BOTH states. Previously the empty state had no
          // refresh affordance at all — which is exactly the situation on a second
          // device that has no local rides yet.
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _RecoveryBanner()),
                SliverToBoxAdapter(child: _SyncBanner(provider: provider)),
                if (provider.rides.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    sliver: SliverList.builder(
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
                  ),
              ],
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
    final provider = context.read<RecordRideProvider>();
    if (provider.hasRecoverableRide) {
      // Don't let a new recording orphan the unfinished one.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finish or discard the unfinished ride first.'),
        ),
      );
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RecordRidePage()));
    if (mounted) {
      await context.read<RideListProvider>().loadRides();
    }
  }
}

/// "N rides not uploaded yet" / sync error. Without this the upload failure was
/// completely invisible.
class _SyncBanner extends StatelessWidget {
  final RideListProvider provider;

  const _SyncBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = provider.pendingCount;
    final syncError = provider.syncError;

    if (pending == 0 && syncError == null) return const SizedBox.shrink();

    final isError = syncError != null;
    final message = isError
        ? 'Sync failed: $syncError'
        : pending == 1
            ? '1 ride not uploaded yet'
            : '$pending rides not uploaded yet';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isError
            ? theme.colorScheme.error.withValues(alpha: 0.15)
            : theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.cloud_upload_outlined,
            size: 18,
            color: isError ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: theme.textTheme.bodySmall),
          ),
          if (provider.isRefreshing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: provider.refresh,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Offers a recording that survived a process kill.
class _RecoveryBanner extends StatelessWidget {
  const _RecoveryBanner();

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordRideProvider>(
      builder: (context, provider, _) {
        final snapshot = provider.recoverable;
        if (snapshot == null) return const SizedBox.shrink();
        return UnfinishedRideCard(
          snapshot: snapshot,
          onResume: () async {
            await provider.resumeRecoveredRide();
            if (!context.mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RecordRidePage()),
            );
            if (context.mounted) {
              await context.read<RideListProvider>().loadRides();
            }
          },
          onSave: () async {
            final ride = await provider.saveRecoveredRide();
            if (!context.mounted) return;
            if (ride != null) {
              await context.read<RideListProvider>().loadRides();
            }
          },
          onDiscard: () => provider.discardRecoveredRide(),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.two_wheeler,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('No rides yet', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Start a ride below, or pull down to load rides from your other '
              'devices.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
