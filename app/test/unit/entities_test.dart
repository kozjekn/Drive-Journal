import 'package:flutter_test/flutter_test.dart';
import 'package:drive_journal/domain/entities/ride.dart';
import 'package:drive_journal/domain/entities/route_point.dart';

void main() {
  group('RoutePoint', () {
    test('two RoutePoints with same values are equal', () {
      final timestamp = DateTime(2025, 3, 15, 10, 0);
      final point1 = RoutePoint(
        latitude: 46.0569,
        longitude: 14.5058,
        altitude: 295.0,
        speed: 12.5,
        timestamp: timestamp,
      );
      final point2 = RoutePoint(
        latitude: 46.0569,
        longitude: 14.5058,
        altitude: 295.0,
        speed: 12.5,
        timestamp: timestamp,
      );

      expect(point1, equals(point2));
    });

    test('two RoutePoints with different values are not equal', () {
      final timestamp = DateTime(2025, 3, 15, 10, 0);
      final point1 = RoutePoint(
        latitude: 46.0569,
        longitude: 14.5058,
        altitude: 295.0,
        speed: 12.5,
        timestamp: timestamp,
      );
      final point2 = RoutePoint(
        latitude: 46.0570,
        longitude: 14.5058,
        altitude: 295.0,
        speed: 12.5,
        timestamp: timestamp,
      );

      expect(point1, isNot(equals(point2)));
    });
  });

  group('Ride', () {
    test('isActive returns true when endTime is null', () {
      final ride = Ride(
        id: '1',
        name: 'Test Ride',
        distanceMeters: 0,
        duration: Duration.zero,
        avgSpeedKmh: 0,
        maxSpeedKmh: 0,
        elevationGainMeters: 0,
        startTime: DateTime.now(),
        endTime: null,
        routePoints: const [],
      );

      expect(ride.isActive, isTrue);
    });

    test('isActive returns false when endTime is set', () {
      final now = DateTime.now();
      final ride = Ride(
        id: '1',
        name: 'Test Ride',
        distanceMeters: 1000,
        duration: const Duration(minutes: 10),
        avgSpeedKmh: 30,
        maxSpeedKmh: 50,
        elevationGainMeters: 20,
        startTime: now,
        endTime: now.add(const Duration(minutes: 10)),
        routePoints: const [],
      );

      expect(ride.isActive, isFalse);
    });

    test('copyWith creates new instance with updated values', () {
      final ride = Ride(
        id: '1',
        name: 'Test Ride',
        distanceMeters: 1000,
        duration: const Duration(minutes: 10),
        avgSpeedKmh: 30,
        maxSpeedKmh: 50,
        elevationGainMeters: 20,
        startTime: DateTime(2025, 3, 15),
        routePoints: const [],
      );

      final updated = ride.copyWith(name: 'Updated Ride', distanceMeters: 2000);

      expect(updated.name, 'Updated Ride');
      expect(updated.distanceMeters, 2000);
      expect(updated.id, '1'); // unchanged
      expect(updated.avgSpeedKmh, 30); // unchanged
    });

    test('two Rides with same values are equal', () {
      final startTime = DateTime(2025, 3, 15);
      final ride1 = Ride(
        id: '1',
        name: 'Test',
        distanceMeters: 100,
        duration: const Duration(minutes: 5),
        avgSpeedKmh: 20,
        maxSpeedKmh: 30,
        elevationGainMeters: 10,
        startTime: startTime,
        routePoints: const [],
      );
      final ride2 = Ride(
        id: '1',
        name: 'Test',
        distanceMeters: 100,
        duration: const Duration(minutes: 5),
        avgSpeedKmh: 20,
        maxSpeedKmh: 30,
        elevationGainMeters: 10,
        startTime: startTime,
        routePoints: const [],
      );

      expect(ride1, equals(ride2));
    });
  });
}
