import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:drive_journal/domain/entities/route_point.dart';

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

  LatLngBounds? get _bounds {
    if (_latLngPoints.isEmpty) return null;
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

    final center = _bounds != null ? _bounds!.center : _latLngPoints.first;

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            interactionOptions: InteractionOptions(
              flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.drivejournal.drive_journal',
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
