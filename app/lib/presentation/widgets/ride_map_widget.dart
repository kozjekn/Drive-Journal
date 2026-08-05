import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ride_journal/domain/entities/route_point.dart';

class RideMapWidget extends StatelessWidget {
  final List<RoutePoint> routePoints;
  final bool interactive;
  final double height;

  const RideMapWidget({
    super.key,
    required this.routePoints,
    this.interactive = true,
    this.height = 300,
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

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}
