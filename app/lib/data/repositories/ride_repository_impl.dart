import 'package:ride_journal/data/datasources/local/ride_local_data_source.dart';
import 'package:ride_journal/data/datasources/remote/ride_remote_data_source.dart';
import 'package:ride_journal/data/models/ride_model.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/repositories/ride_repository.dart';

class RideRepositoryImpl implements RideRepository {
  final RideLocalDataSource localDataSource;
  final RideRemoteDataSource remoteDataSource;

  RideRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<Ride>> getAllRides() async {
    final models = await localDataSource.getAllRides();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Ride?> getRideById(String id) async {
    final model = await localDataSource.getRideById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveRide(Ride ride) async {
    final model = RideModel.fromEntity(
      ride.copyWith(updatedAt: DateTime.now()),
    );
    await localDataSource.saveRide(model);
  }

  @override
  Future<void> deleteRide(String id) async {
    await localDataSource.deleteRide(id);
    try {
      await remoteDataSource.deleteRide(id);
    } catch (_) {
      // Will be cleaned up on next sync
    }
  }

  @override
  Future<void> syncRides() async {
    final localModels = await localDataSource.getAllRides();

    // Send unsynced or updated-since-last-sync rides
    final ridesToSync = localModels.where((r) {
      if (r.syncedAt == null) return true;
      return r.updatedAt.isAfter(r.syncedAt!);
    }).toList();

    final result = await remoteDataSource.syncRides(ridesToSync);

    // Save server rides locally
    final now = DateTime.now();
    for (final serverRide in result.serverRides) {
      final withSync = RideModel.fromEntity(
        serverRide.toEntity().copyWith(syncedAt: now),
      );
      await localDataSource.saveRide(withSync);
    }

    // Mark synced rides
    for (final ride in ridesToSync) {
      final synced = RideModel.fromEntity(
        ride.toEntity().copyWith(syncedAt: now),
      );
      await localDataSource.saveRide(synced);
    }
  }
}
