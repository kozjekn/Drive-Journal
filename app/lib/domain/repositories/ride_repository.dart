import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/entities/sync_outcome.dart';

abstract class RideRepository {
  Future<List<Ride>> getAllRides();
  Future<Ride?> getRideById(String id);

  /// Saves locally (durable, never lost) and pushes in the background.
  Future<void> saveRide(Ride ride);

  Future<void> deleteRide(String id);

  /// Pushes pending rides and deletions, then pulls server changes. Single-flight:
  /// concurrent callers share one in-progress sync.
  Future<SyncOutcome> syncRides();

  Future<int> pendingRideCount();

  Future<SyncStatus> syncStatus();

  /// Associates the local ride store with [userId], clearing it first if it
  /// belonged to someone else. Must be called on every authentication.
  Future<void> bindToUser(String userId);

  /// Wipes all local ride data. Called on sign-out.
  Future<void> clearLocalData();
}
