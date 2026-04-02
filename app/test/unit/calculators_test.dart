import 'package:flutter_test/flutter_test.dart';
import 'package:ride_journal/core/utils/distance_calculator.dart';
import 'package:ride_journal/core/utils/elevation_calculator.dart';
import 'package:ride_journal/core/utils/speed_calculator.dart';
import 'package:ride_journal/domain/entities/route_point.dart';

void main() {
  group('DistanceCalculator', () {
    test('returns 0 for empty list', () {
      expect(DistanceCalculator.totalDistance([]), 0.0);
    });

    test('returns 0 for single point', () {
      final points = [
        RoutePoint(
          latitude: 46.0569,
          longitude: 14.5058,
          altitude: 295,
          speed: 0,
          timestamp: DateTime.now(),
        ),
      ];
      expect(DistanceCalculator.totalDistance(points), 0.0);
    });

    test('calculates distance between two known points', () {
      // Ljubljana to Maribor is approximately 113 km
      final points = [
        RoutePoint(
          latitude: 46.0569,
          longitude: 14.5058,
          altitude: 295,
          speed: 0,
          timestamp: DateTime.now(),
        ),
        RoutePoint(
          latitude: 46.5547,
          longitude: 15.6459,
          altitude: 275,
          speed: 0,
          timestamp: DateTime.now(),
        ),
      ];
      final distance = DistanceCalculator.totalDistance(points);
      // Should be roughly 113 km (113000 m) - allow 10% tolerance
      expect(distance, greaterThan(100000));
      expect(distance, lessThan(130000));
    });
  });

  group('SpeedCalculator', () {
    test('returns 0 when duration is zero', () {
      expect(
        SpeedCalculator.averageSpeed(
          distanceMeters: 1000,
          duration: Duration.zero,
        ),
        0.0,
      );
    });

    test('calculates correct average speed', () {
      // 10 km in 30 minutes = 20 km/h
      final result = SpeedCalculator.averageSpeed(
        distanceMeters: 10000,
        duration: const Duration(minutes: 30),
      );
      expect(result, closeTo(20.0, 0.1));
    });

    test('returns 0 max speed for empty list', () {
      expect(SpeedCalculator.maxSpeed([]), 0.0);
    });

    test('finds maximum speed from points', () {
      final now = DateTime.now();
      final points = [
        RoutePoint(
          latitude: 46.0,
          longitude: 14.5,
          altitude: 295,
          speed: 10.0, // 36 km/h
          timestamp: now,
        ),
        RoutePoint(
          latitude: 46.1,
          longitude: 14.6,
          altitude: 295,
          speed: 25.0, // 90 km/h
          timestamp: now.add(const Duration(seconds: 10)),
        ),
        RoutePoint(
          latitude: 46.2,
          longitude: 14.7,
          altitude: 295,
          speed: 15.0, // 54 km/h
          timestamp: now.add(const Duration(seconds: 20)),
        ),
      ];

      // Max speed is 25 m/s = 90 km/h
      expect(SpeedCalculator.maxSpeed(points), closeTo(90.0, 0.1));
    });
  });

  group('ElevationCalculator', () {
    test('returns 0 for empty list', () {
      expect(ElevationCalculator.totalElevationGain([]), 0.0);
    });

    test('returns 0 for single point', () {
      final points = [
        RoutePoint(
          latitude: 46.0,
          longitude: 14.5,
          altitude: 295,
          speed: 0,
          timestamp: DateTime.now(),
        ),
      ];
      expect(ElevationCalculator.totalElevationGain(points), 0.0);
    });

    test('calculates only positive elevation gain', () {
      final now = DateTime.now();
      final points = [
        RoutePoint(
          latitude: 46.0,
          longitude: 14.5,
          altitude: 100,
          speed: 0,
          timestamp: now,
        ),
        RoutePoint(
          latitude: 46.0,
          longitude: 14.5,
          altitude: 150, // +50
          speed: 0,
          timestamp: now.add(const Duration(seconds: 10)),
        ),
        RoutePoint(
          latitude: 46.0,
          longitude: 14.5,
          altitude: 120, // -30 (ignored)
          speed: 0,
          timestamp: now.add(const Duration(seconds: 20)),
        ),
        RoutePoint(
          latitude: 46.0,
          longitude: 14.5,
          altitude: 200, // +80
          speed: 0,
          timestamp: now.add(const Duration(seconds: 30)),
        ),
      ];

      // Total gain: 50 + 80 = 130 meters
      expect(
        ElevationCalculator.totalElevationGain(points),
        closeTo(130.0, 0.1),
      );
    });
  });
}
