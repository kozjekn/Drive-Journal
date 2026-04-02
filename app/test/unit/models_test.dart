import 'package:flutter_test/flutter_test.dart';
import 'package:ride_journal/data/models/ride_model.dart';
import 'package:ride_journal/data/models/route_point_model.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/entities/route_point.dart';

void main() {
  group('RoutePointModel', () {
    test('converts from entity', () {
      final entity = RoutePoint(
        latitude: 46.0569,
        longitude: 14.5058,
        altitude: 295.0,
        speed: 12.5,
        timestamp: DateTime(2025, 3, 15, 10, 0),
      );

      final model = RoutePointModel.fromEntity(entity);
      expect(model.latitude, 46.0569);
      expect(model.longitude, 14.5058);
      expect(model.altitude, 295.0);
      expect(model.speed, 12.5);
    });

    test('serializes to map and back', () {
      final model = RoutePointModel(
        latitude: 46.0569,
        longitude: 14.5058,
        altitude: 295.0,
        speed: 12.5,
        timestamp: DateTime(2025, 3, 15, 10, 0),
      );

      final map = model.toMap();
      final restored = RoutePointModel.fromMap(map);

      expect(restored.latitude, model.latitude);
      expect(restored.longitude, model.longitude);
      expect(restored.altitude, model.altitude);
      expect(restored.speed, model.speed);
      expect(
        restored.timestamp.millisecondsSinceEpoch,
        model.timestamp.millisecondsSinceEpoch,
      );
    });

    test('converts to entity', () {
      final model = RoutePointModel(
        latitude: 46.0569,
        longitude: 14.5058,
        altitude: 295.0,
        speed: 12.5,
        timestamp: DateTime(2025, 3, 15, 10, 0),
      );

      final entity = model.toEntity();
      expect(entity, isA<RoutePoint>());
      expect(entity.latitude, 46.0569);
    });
  });

  group('RideModel', () {
    test('converts from entity', () {
      final entity = Ride(
        id: '1',
        name: 'Test Ride',
        distanceMeters: 5000,
        duration: const Duration(minutes: 20),
        avgSpeedKmh: 15,
        maxSpeedKmh: 30,
        elevationGainMeters: 50,
        startTime: DateTime(2025, 3, 15, 10, 0),
        endTime: DateTime(2025, 3, 15, 10, 20),
        routePoints: const [],
        updatedAt: DateTime(2025, 3, 15, 10, 20),
      );

      final model = RideModel.fromEntity(entity);
      expect(model.id, '1');
      expect(model.name, 'Test Ride');
      expect(model.distanceMeters, 5000);
    });

    test('serializes to map and back', () {
      final model = RideModel(
        id: '1',
        name: 'Test Ride',
        distanceMeters: 5000,
        duration: const Duration(minutes: 20),
        avgSpeedKmh: 15,
        maxSpeedKmh: 30,
        elevationGainMeters: 50,
        startTime: DateTime(2025, 3, 15, 10, 0),
        endTime: DateTime(2025, 3, 15, 10, 20),
        updatedAt: DateTime(2025, 3, 15, 10, 20),
        routePoints: [
          RoutePoint(
            latitude: 46.0569,
            longitude: 14.5058,
            altitude: 295.0,
            speed: 12.5,
            timestamp: DateTime(2025, 3, 15, 10, 0),
          ),
        ],
      );

      final map = model.toMap();
      final restored = RideModel.fromMap(map);

      expect(restored.id, model.id);
      expect(restored.name, model.name);
      expect(restored.distanceMeters, model.distanceMeters);
      expect(restored.duration.inMilliseconds, model.duration.inMilliseconds);
      expect(restored.routePoints, hasLength(1));
      expect(restored.routePoints.first.latitude, 46.0569);
    });

    test('handles null endTime in serialization', () {
      final model = RideModel(
        id: '1',
        name: 'Active Ride',
        distanceMeters: 1000,
        duration: const Duration(minutes: 5),
        avgSpeedKmh: 12,
        maxSpeedKmh: 20,
        elevationGainMeters: 10,
        startTime: DateTime(2025, 3, 15, 10, 0),
        endTime: null,
        routePoints: const [],
        updatedAt: DateTime(2025, 3, 15, 10, 0),
      );

      final map = model.toMap();
      expect(map['endTime'], isNull);

      final restored = RideModel.fromMap(map);
      expect(restored.endTime, isNull);
    });

    test('converts to entity', () {
      final model = RideModel(
        id: '1',
        name: 'Test',
        distanceMeters: 100,
        duration: const Duration(minutes: 5),
        avgSpeedKmh: 20,
        maxSpeedKmh: 30,
        elevationGainMeters: 10,
        startTime: DateTime(2025, 3, 15),
        routePoints: const [],
        updatedAt: DateTime(2025, 3, 15),
      );

      final entity = model.toEntity();
      expect(entity, isA<Ride>());
      expect(entity.id, '1');
    });
  });
}
