import 'package:hive/hive.dart';
import 'package:ride_journal/core/error/exceptions.dart';
import 'package:ride_journal/data/models/ride_model.dart';

abstract class RideLocalDataSource {
  Future<List<RideModel>> getAllRides();
  Future<RideModel?> getRideById(String id);
  Future<void> saveRide(RideModel ride);
  Future<void> deleteRide(String id);

  /// Rides with local changes the server has not acknowledged, oldest change
  /// first so a partial push still makes forward progress.
  Future<List<RideModel>> getPendingRides();

  Future<void> clearAll();

  /// Deletes that still need to reach the server. Written *before* the local row
  /// is removed, so a failed remote delete has something left to retry from.
  Future<void> addTombstone(String id);
  Future<List<String>> getTombstones();
  Future<void> removeTombstone(String id);
  Future<void> clearTombstones();
}

class RideLocalDataSourceImpl implements RideLocalDataSource {
  static const String boxName = 'rides';
  static const String tombstoneBoxName = 'ride_tombstones';

  final Box<RideModel> _rideBox;
  final Box<dynamic> _tombstoneBox;

  RideLocalDataSourceImpl(this._rideBox, this._tombstoneBox);

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

  @override
  Future<List<RideModel>> getPendingRides() async {
    try {
      final pending =
          _rideBox.values.where((r) => r.isPendingSync).toList();
      pending.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      return pending;
    } catch (e) {
      throw DatabaseException('Failed to get pending rides: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _rideBox.clear();
    } catch (e) {
      throw DatabaseException('Failed to clear rides: $e');
    }
  }

  @override
  Future<void> addTombstone(String id) async {
    try {
      await _tombstoneBox.put(id, DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      throw DatabaseException('Failed to record deletion: $e');
    }
  }

  @override
  Future<List<String>> getTombstones() async {
    try {
      return _tombstoneBox.keys.whereType<String>().toList();
    } catch (e) {
      throw DatabaseException('Failed to read deletions: $e');
    }
  }

  @override
  Future<void> removeTombstone(String id) async {
    try {
      await _tombstoneBox.delete(id);
    } catch (e) {
      throw DatabaseException('Failed to clear deletion: $e');
    }
  }

  @override
  Future<void> clearTombstones() async {
    try {
      await _tombstoneBox.clear();
    } catch (e) {
      throw DatabaseException('Failed to clear deletions: $e');
    }
  }
}
