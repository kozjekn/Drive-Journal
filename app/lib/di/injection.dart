import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:drive_journal/core/services/location_service.dart';
import 'package:drive_journal/data/datasources/local/ride_local_data_source.dart';
import 'package:drive_journal/data/datasources/remote/ride_remote_data_source.dart';
import 'package:drive_journal/data/models/ride_model.dart';
import 'package:drive_journal/data/models/route_point_model.dart';
import 'package:drive_journal/data/repositories/ride_repository_impl.dart';
import 'package:drive_journal/domain/repositories/ride_repository.dart';
import 'package:drive_journal/domain/usecases/delete_ride.dart';
import 'package:drive_journal/domain/usecases/get_all_rides.dart';
import 'package:drive_journal/domain/usecases/get_ride_by_id.dart';
import 'package:drive_journal/domain/usecases/save_ride.dart';
import 'package:drive_journal/presentation/providers/record_ride_provider.dart';
import 'package:drive_journal/presentation/providers/ride_detail_provider.dart';
import 'package:drive_journal/presentation/providers/ride_list_provider.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // Hive initialization
  await Hive.initFlutter();
  Hive.registerAdapter(RideAdapter());
  Hive.registerAdapter(RoutePointAdapter());

  final rideBox = await Hive.openBox<RideModel>('rides');

  // Data sources
  sl.registerLazySingleton<RideLocalDataSource>(
    () => RideLocalDataSourceImpl(rideBox),
  );
  sl.registerLazySingleton<RideRemoteDataSource>(
    () => RideRemoteDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<RideRepository>(
    () => RideRepositoryImpl(
      localDataSource: sl<RideLocalDataSource>(),
      remoteDataSource: sl<RideRemoteDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllRides(sl<RideRepository>()));
  sl.registerLazySingleton(() => GetRideById(sl<RideRepository>()));
  sl.registerLazySingleton(() => SaveRide(sl<RideRepository>()));
  sl.registerLazySingleton(() => DeleteRide(sl<RideRepository>()));

  // Services
  sl.registerLazySingleton<LocationService>(() => LocationServiceImpl());

  // Providers
  sl.registerFactory(
    () => RideListProvider(
      getAllRides: sl<GetAllRides>(),
      deleteRide: sl<DeleteRide>(),
    ),
  );
  sl.registerFactory(() => RideDetailProvider(getRideById: sl<GetRideById>()));
  sl.registerFactory(
    () => RecordRideProvider(
      saveRide: sl<SaveRide>(),
      locationService: sl<LocationService>(),
    ),
  );
}
