import 'package:hive/hive.dart';
import 'package:ride_journal/core/error/exceptions.dart';
import 'package:ride_journal/data/models/ride_model.dart';

abstract class RideLocalDataSource {
  Future<List<RideModel>> getAllRides();
  Future<RideModel?> getRideById(String id);
  Future<void> saveRide(RideModel ride);
  Future<void> deleteRide(String id);
}

class RideLocalDataSourceImpl implements RideLocalDataSource {
  static const String boxName = 'rides';

  final Box<RideModel> _rideBox;

  RideLocalDataSourceImpl(this._rideBox);

  @override
  Future<List<RideModel>> getAllRides() async {
    try {
      final rides = _rideBox.values.toList();
      // Sort by start time, newest first
      rides.sort((a, b) => b.startTime.compareTo(a.startTime));
      return rides;
    } catch (e) {
      throw DatabaseException('Failed to get rides: $e');
    }
  }

  @override
  Future<RideModel?> getRideById(String id) async {
    try {
      return _rideBox.get(id);
    } catch (e) {
      throw DatabaseException('Failed to get ride by id: $e');
    }
  }

  @override
  Future<void> saveRide(RideModel ride) async {
    try {
      await _rideBox.put(ride.id, ride);
    } catch (e) {
      throw DatabaseException('Failed to save ride: $e');
    }
  }

  @override
  Future<void> deleteRide(String id) async {
    try {
      await _rideBox.delete(id);
    } catch (e) {
      throw DatabaseException('Failed to delete ride: $e');
    }
  }
}
