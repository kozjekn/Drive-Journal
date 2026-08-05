import 'package:flutter/material.dart';
import 'package:ride_journal/core/utils/distance_calculator.dart';
import 'package:ride_journal/core/utils/format_utils.dart';
import 'package:ride_journal/data/datasources/local/active_ride_local_data_source.dart';

/// Offers a recording that was interrupted by a process kill.
///
/// Non-modal on purpose: it works the same on every platform, cannot hijack
/// launch, and survives being interrupted itself.
class UnfinishedRideCard extends StatelessWidget {
  final ActiveRideSnapshot snapshot;
  final Future<void> Function() onResume;
  final Future<void> Function() onSave;
  final Future<void> Function() onDiscard;

  const UnfinishedRideCard({
    super.key,
    required this.snapshot,
    required this.onResume,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = DistanceCalculator.totalDistance(snapshot.points);
    final lastPoint = snapshot.lastPointTime;
    final recorded = lastPoint != null
        ? lastPoint.difference(snapshot.startTime)
        : Duration.zero;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Unfinished ride', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Started ${FormatUtils.formatTime(snapshot.startTime)} · '
              '${FormatUtils.formatDistance(distance)} · '
              '${FormatUtils.formatDuration(recorded)} recorded',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'The app closed before this ride was saved.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: onResume,
                  child: const Text('Resume'),
                ),
                OutlinedButton(
                  onPressed: onSave,
                  child: const Text('Save as-is'),
                ),
                TextButton(
                  onPressed: () => _confirmDiscard(context),
                  child: const Text('Discard'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished ride?'),
        content: const Text('This recording will be deleted permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onDiscard();
  }
}
