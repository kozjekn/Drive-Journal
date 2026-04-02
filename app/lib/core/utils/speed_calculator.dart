import 'package:ride_journal/domain/entities/route_point.dart';

class SpeedCalculator {
  /// Returns average speed in km/h from route points based on
  /// total distance and total time.
  static double averageSpeed({
    required double distanceMeters,
    required Duration duration,
  }) {
    if (duration.inSeconds == 0) return 0.0;
    final hours = duration.inSeconds / 3600.0;
    final km = distanceMeters / 1000.0;
    return km / hours;
  }

  /// Returns max speed in km/h from the route points.
  /// Uses the speed reported by the GPS sensor on each point.
  static double maxSpeed(List<RoutePoint> points) {
    if (points.isEmpty) return 0.0;
    var max = 0.0;
    for (final point in points) {
      if (point.speed > max) {
        max = point.speed;
      }
    }
    // GPS speed is in m/s, convert to km/h
    return max * 3.6;
  }
}
