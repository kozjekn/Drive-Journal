import 'package:drive_journal/data/datasources/local/ride_local_data_source.dart';
import 'package:drive_journal/data/datasources/remote/ride_remote_data_source.dart';
import 'package:drive_journal/data/models/ride_model.dart';
import 'package:drive_journal/domain/entities/ride.dart';
import 'package:drive_journal/domain/repositories/ride_repository.dart';

class RideRepositoryImpl implements RideRepository {
  final RideLocalDataSource localDataSource;
  final RideRemoteDataSource remoteDataSource;

  RideRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<Ride>> getAllRides() async {
    // TODO: When backend is connected, try remote first, fall back to local
    // try {
    //   final remoteRides = await remoteDataSource.getAllRides();
    //   for (final ride in remoteRides) {
    //     await localDataSource.saveRide(ride);
    //   }
    //   return remoteRides.map((m) => m.toEntity()).toList();
    // } catch (_) {
    //   // Offline fallback
    // }
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
    final model = RideModel.fromEntity(ride);
    await localDataSource.saveRide(model);

    // TODO: When backend is connected, sync to remote
    // try {
    //   await remoteDataSource.saveRide(model);
    // } catch (_) {
    //   // Queue for later sync
    // }
  }

  @override
  Future<void> deleteRide(String id) async {
    await localDataSource.deleteRide(id);

    // TODO: When backend is connected, delete from remote
    // try {
    //   await remoteDataSource.deleteRide(id);
    // } catch (_) {
    //   // Queue for later sync
    // }
  }
}
