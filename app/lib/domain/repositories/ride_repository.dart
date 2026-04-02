import 'package:drive_journal/domain/entities/ride.dart';

abstract class RideRepository {
  Future<List<Ride>> getAllRides();
  Future<Ride?> getRideById(String id);
  Future<void> saveRide(Ride ride);
  Future<void> deleteRide(String id);
  Future<void> syncRides();
}
