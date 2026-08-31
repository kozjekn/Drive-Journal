import 'package:flutter/material.dart';
import 'package:ride_journal/domain/entities/route_point.dart';
import 'package:ride_journal/presentation/widgets/ride_map_widget.dart';

/// The ride route filling the whole screen.
///
/// No AppBar, so the map is genuinely full-bleed; the close button and system
/// back both land on the same [Navigator.pop].
class FullscreenMapPage extends StatelessWidget {
  final List<RoutePoint> routePoints;
  final String? title;

  const FullscreenMapPage({
    super.key,
    required this.routePoints,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        // A Stack only takes constraints.biggest when EVERY child is positioned,
        // and Scaffold hands its body loose constraints (min height 0). The
        // overlay below used to be non-positioned, which collapsed the whole page
        // to the height of the close button and left the map a thin strip.
        // Positioning the overlay is the fix; the expand fit keeps a future
        // non-positioned child from quietly bringing the bug back.
        fit: StackFit.expand,
        children: [
          // Square corners and no fixed height: the map is the page. The camera
          // refits the route to this larger viewport on its own.
          Positioned.fill(
            child: RideMapWidget(
              routePoints: routePoints,
              height: null,
              borderRadius: 0,
            ),
          ),

          // Top-anchored so it never covers — and never steals gestures from —
          // the rest of the map.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            title!,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    const Spacer(),
                    FloatingActionButton.small(
                      heroTag: 'close-fullscreen-map',
                      tooltip: 'Close fullscreen map',
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
