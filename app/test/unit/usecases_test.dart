import 'package:flutter_test/flutter_test.dart';
import 'package:drive_journal/domain/entities/ride.dart';
import 'package:drive_journal/domain/usecases/delete_ride.dart';
import 'package:drive_journal/domain/usecases/get_all_rides.dart';
import 'package:drive_journal/domain/usecases/get_ride_by_id.dart';
import 'package:drive_journal/domain/usecases/save_ride.dart';

import '../mocks.dart';

void main() {
  late MockRideRepository repository;

  final testRide = Ride(
    id: 'test-1',
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

  setUp(() {
    repository = MockRideRepository();
  });

  group('GetAllRides', () {
    test('returns empty list when no rides', () async {
      final useCase = GetAllRides(repository);
      final result = await useCase();
      expect(result, isEmpty);
    });

    test('returns all rides', () async {
      repository.addRide(testRide);
      final useCase = GetAllRides(repository);
      final result = await useCase();
      expect(result, hasLength(1));
      expect(result.first.id, 'test-1');
    });
  });

  group('GetRideById', () {
    test('returns ride when it exists', () async {
      repository.addRide(testRide);
      final useCase = GetRideById(repository);
      final result = await useCase('test-1');
      expect(result, isNotNull);
      expect(result!.name, 'Test Ride');
    });

    test('returns null when ride does not exist', () async {
      final useCase = GetRideById(repository);
      final result = await useCase('nonexistent');
      expect(result, isNull);
    });
  });

  group('SaveRide', () {
    test('saves ride to repository', () async {
      final useCase = SaveRide(repository);
      await useCase(testRide);
      final rides = await repository.getAllRides();
      expect(rides, hasLength(1));
      expect(rides.first.id, 'test-1');
    });
  });

  group('DeleteRide', () {
    test('deletes ride from repository', () async {
      repository.addRide(testRide);
      final useCase = DeleteRide(repository);
      await useCase('test-1');
      final rides = await repository.getAllRides();
      expect(rides, isEmpty);
    });
  });
}
