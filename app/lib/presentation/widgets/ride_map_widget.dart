import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ride_journal/domain/entities/route_point.dart';
import 'package:ride_journal/presentation/pages/fullscreen_map_page.dart';

class RideMapWidget extends StatelessWidget {
  final List<RoutePoint> routePoints;
  final bool interactive;

  /// Null fills the parent — that is how [FullscreenMapPage] renders it.
  final double? height;

  final double borderRadius;

  /// Shows an expand button in the top-right corner that opens the route in
  /// [FullscreenMapPage].
  final bool expandable;

  /// Ride name, shown as a label on the fullscreen page.
  final String? title;

  const RideMapWidget({
    super.key,
    required this.routePoints,
    this.interactive = true,
    this.height = 300,
    this.borderRadius = 16,
    this.expandable = false,
    this.title,
  });

  List<LatLng> get _latLngPoints =>
      routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

  /// Null for a single-point track: degenerate bounds would ask the camera to
  /// fit a zero-area box.
  LatLngBounds? get _bounds {
    if (_latLngPoints.length < 2) return null;
    return LatLngBounds.fromPoints(_latLngPoints);
  }

  @override
  Widget build(BuildContext context) {
    if (routePoints.isEmpty) {
      // No expand button here — there is nothing to enlarge.
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No route data available',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final bounds = _bounds;

    Widget map = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: FlutterMap(
          options: MapOptions(
            // Fit the whole route. A fixed zoom around the centre made any ride
            // longer than a few km overflow the viewport.
            initialCameraFit: bounds != null
                ? CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(24),
                  )
                : null,
            initialCenter: bounds?.center ?? _latLngPoints.first,
            initialZoom: 14,
            interactionOptions: InteractionOptions(
              flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dev.kozjek.ride',
            ),
            if (_latLngPoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _latLngPoints,
                    strokeWidth: 4.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (_latLngPoints.isNotEmpty)
                  Marker(
                    point: _latLngPoints.first,
                    width: 20,
                    height: 20,
                    child: const Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
                if (_latLngPoints.length > 1)
                  Marker(
                    point: _latLngPoints.last,
                    width: 20,
                    height: 20,
                    child: Icon(
                      Icons.circle,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

    if (expandable) {
      map = Stack(
        children: [
          Positioned.fill(child: map),
          Positioned(
            top: 8,
            right: 8,
            child: FloatingActionButton.small(
              heroTag: 'expand-map',
              tooltip: 'Expand map',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FullscreenMapPage(
                    routePoints: routePoints,
                    title: title,
                  ),
                ),
              ),
              child: const Icon(Icons.fullscreen),
            ),
          ),
        ],
      );
    }

    return height == null ? map : SizedBox(height: height, child: map);
  }
}
