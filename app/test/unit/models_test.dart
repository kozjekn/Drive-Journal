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

  group('wire format (JSON)', () {
    RideModel buildRide() => RideModel(
          id: 'ride-1',
          name: 'Morning Ride',
          distanceMeters: 12400,
          duration: const Duration(minutes: 42),
          avgSpeedKmh: 17.7,
          maxSpeedKmh: 38.2,
          elevationGainMeters: 120,
          startTime: DateTime(2026, 8, 3, 9, 15),
          endTime: DateTime(2026, 8, 3, 9, 57),
          routePoints: [
            RoutePoint(
              latitude: 46.0569,
              longitude: 14.5058,
              altitude: 295,
              speed: 12.5,
              timestamp: DateTime(2026, 8, 3, 9, 15),
            ),
          ],
          updatedAt: DateTime(2026, 8, 3, 9, 57),
          syncedAt: DateTime(2026, 8, 3, 10),
        );

    test('emits UTC timestamps with a trailing Z', () {
      // Local time with no offset was parsed as Unspecified by the server and
      // compared against DateTime.UtcNow, which is what sync ordering is built on.
      final json = buildRide().toJson();

      expect(json['startTime'] as String, endsWith('Z'));
      expect(json['endTime'] as String, endsWith('Z'));
      expect(json['updatedAt'] as String, endsWith('Z'));
      expect(
        (json['routePoints'] as List).first['timestamp'] as String,
        endsWith('Z'),
      );
    });

    test('omits device-local and server-owned fields', () {
      final json = buildRide().toJson();

      expect(json.containsKey('syncedAt'), isFalse);
      expect(json.containsKey('userId'), isFalse);
    });

    test('round-trips through JSON back to local time', () {
      final original = buildRide();
      final decoded = RideModel.fromJson(original.toJson());

      expect(decoded.id, original.id);
      expect(decoded.startTime.isUtc, isFalse);
      expect(decoded.startTime, original.startTime);
      expect(decoded.endTime, original.endTime);
      expect(decoded.updatedAt, original.updatedAt);
      expect(
        decoded.routePoints.single.timestamp,
        original.routePoints.single.timestamp,
      );
      expect(decoded.distanceMeters, original.distanceMeters);
    });

    test('parses visibility from the server\'s string form', () {
      final json = buildRide().toJson()..['visibility'] = 'Public';
      expect(RideModel.fromJson(json).visibility, RideVisibility.public_);
    });
  });

  group('Ride.isPendingSync', () {
    Ride rideWith({DateTime? syncedAt, DateTime? updatedAt}) => Ride(
          id: '1',
          name: 'Ride',
          distanceMeters: 0,
          duration: Duration.zero,
          avgSpeedKmh: 0,
          maxSpeedKmh: 0,
          elevationGainMeters: 0,
          startTime: DateTime(2026, 8, 3, 9),
          routePoints: const [],
          updatedAt: updatedAt ?? DateTime(2026, 8, 3, 10),
          syncedAt: syncedAt,
        );

    test('a never-synced ride is pending', () {
      expect(rideWith().isPendingSync, isTrue);
    });

    test('a ride synced at its updatedAt is not pending', () {
      final at = DateTime(2026, 8, 3, 10);
      expect(rideWith(updatedAt: at, syncedAt: at).isPendingSync, isFalse);
    });

    test('a ride edited after its last sync is pending again', () {
      expect(
        rideWith(
          updatedAt: DateTime(2026, 8, 3, 11),
          syncedAt: DateTime(2026, 8, 3, 10),
        ).isPendingSync,
        isTrue,
      );
    });
  });

  group('Ride.copyWith', () {
    Ride base() => Ride(
          id: '1',
          name: 'Ride',
          distanceMeters: 0,
          duration: Duration.zero,
          avgSpeedKmh: 0,
          maxSpeedKmh: 0,
          elevationGainMeters: 0,
          startTime: DateTime(2026, 8, 3, 9),
          endTime: DateTime(2026, 8, 3, 10),
          routePoints: const [],
          updatedAt: DateTime(2026, 8, 3, 10),
          syncedAt: DateTime(2026, 8, 3, 10),
        );

    test('preserves nullable fields when they are not passed', () {
      final copy = base().copyWith(name: 'Renamed');
      expect(copy.endTime, isNotNull);
      expect(copy.syncedAt, isNotNull);
    });

    test('can clear nullable fields explicitly', () {
      // `?? this.x` on every field meant these could only ever be set.
      final copy = base().copyWith(endTime: null, syncedAt: null);
      expect(copy.endTime, isNull);
      expect(copy.syncedAt, isNull);
    });
  });
}
