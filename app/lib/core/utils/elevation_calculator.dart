import 'package:drive_journal/domain/entities/route_point.dart';

class ElevationCalculator {
  /// Calculates total elevation gain in meters from route points.
  ///
  /// TODO: GPS altitude is unreliable. For accurate elevation data, consider:
  /// - Using a barometric altimeter sensor (if available on device)
  /// - Querying an elevation API (e.g., Open-Elevation, Google Elevation API)
  ///   after the ride is complete to correct altitude values
  /// - Applying a smoothing algorithm to reduce GPS altitude noise
  static double totalElevationGain(List<RoutePoint> points) {
    if (points.length < 2) return 0.0;

    var gain = 0.0;
    for (var i = 1; i < points.length; i++) {
      final diff = points[i].altitude - points[i - 1].altitude;
      if (diff > 0) {
        gain += diff;
      }
    }
    return gain;
  }
}
