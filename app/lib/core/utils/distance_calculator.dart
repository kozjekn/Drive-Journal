import 'dart:math';

import 'package:ride_journal/domain/entities/route_point.dart';

class DistanceCalculator {
  /// Calculates the total distance in meters from a list of route points
  /// using the Haversine formula.
  static double totalDistance(List<RoutePoint> points) {
    if (points.length < 2) return 0.0;

    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += _haversine(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return total;
  }

  /// Haversine formula to calculate distance between two GPS coordinates.
  /// Returns distance in meters.
  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
