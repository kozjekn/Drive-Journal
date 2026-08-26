import 'package:flutter/material.dart';
import 'package:ride_journal/core/utils/format_utils.dart';
import 'package:ride_journal/domain/entities/ride.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onTap;
  final VoidCallback? onDismissed;

  const RideCard({
    super.key,
    required this.ride,
    required this.onTap,
    this.onDismissed,
  });

  /// A false/null return springs the card back with nothing deleted.
  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ride?'),
        content: Text(
          '"${ride.name}" will be permanently deleted from this device and '
          'from the cloud. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(ride.id),
      direction: onDismissed != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      // The delete is permanent on this device *and* writes a server tombstone,
      // with no undo — too much to hang off a stray swipe.
      confirmDismiss: onDismissed == null ? null : (_) => _confirmDelete(context),
      onDismissed: (_) => onDismissed?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ride.name,
                        style: theme.textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ride.isPendingSync) ...[
                      // Makes a failed upload self-diagnosing instead of silent.
                      Tooltip(
                        message: 'Not uploaded yet',
                        child: Icon(
                          Icons.cloud_off,
                          size: 14,
                          semanticLabel: 'Not uploaded yet',
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      FormatUtils.formatDate(ride.startTime),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                      icon: Icons.straighten,
                      value: FormatUtils.formatDistance(ride.distanceMeters),
                    ),
                    _StatChip(
                      icon: Icons.timer,
                      value: FormatUtils.formatDuration(ride.duration),
                    ),
                    _StatChip(
                      icon: Icons.speed,
                      value: FormatUtils.formatSpeed(ride.avgSpeedKmh),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
