import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ride_journal/core/network/api_client.dart';
import 'package:ride_journal/core/services/connectivity_service.dart';
import 'package:ride_journal/core/services/location_service.dart';
import 'package:ride_journal/core/services/screen_wake_service.dart';
import 'package:ride_journal/data/datasources/local/active_ride_local_data_source.dart';
import 'package:ride_journal/data/datasources/local/auth_local_data_source.dart';
import 'package:ride_journal/data/datasources/local/ride_local_data_source.dart';
import 'package:ride_journal/data/datasources/local/sync_local_data_source.dart';
import 'package:ride_journal/data/datasources/remote/auth_remote_data_source.dart';
import 'package:ride_journal/data/datasources/remote/ride_remote_data_source.dart';
import 'package:ride_journal/data/models/ride_model.dart';
import 'package:ride_journal/data/models/route_point_model.dart';
import 'package:ride_journal/data/repositories/auth_repository_impl.dart';
import 'package:ride_journal/data/repositories/ride_repository_impl.dart';
import 'package:ride_journal/domain/repositories/auth_repository.dart';
import 'package:ride_journal/domain/repositories/ride_repository.dart';
import 'package:ride_journal/domain/usecases/delete_ride.dart';
import 'package:ride_journal/domain/usecases/get_all_rides.dart';
import 'package:ride_journal/domain/usecases/get_pending_ride_count.dart';
import 'package:ride_journal/domain/usecases/get_ride_by_id.dart';
import 'package:ride_journal/domain/usecases/save_ride.dart';
import 'package:ride_journal/domain/usecases/sync_rides.dart';
import 'package:ride_journal/data/datasources/remote/user_remote_data_source.dart';
import 'package:ride_journal/presentation/providers/auth_provider.dart';
import 'package:ride_journal/presentation/providers/feed_provider.dart';
import 'package:ride_journal/presentation/providers/record_ride_provider.dart';
import 'package:ride_journal/presentation/providers/ride_detail_provider.dart';
import 'package:ride_journal/presentation/providers/ride_list_provider.dart';
import 'package:ride_journal/presentation/providers/sync_provider.dart';
import 'package:ride_journal/presentation/providers/user_profile_provider.dart';
import 'package:ride_journal/presentation/providers/user_search_provider.dart';
import 'package:ride_journal/presentation/widgets/web_recording_notice.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // Hive initialization
  await Hive.initFlutter();
  Hive.registerAdapter(RideAdapter());
  Hive.registerAdapter(RoutePointAdapter());

  final rideBox = await Hive.openBox<RideModel>(RideLocalDataSourceImpl.boxName);
  // Untyped boxes: Hive handles String/int/bool/List/Map natively, so these need
  // no adapters and no schema migration.
  final tombstoneBox =
      await Hive.openBox<dynamic>(RideLocalDataSourceImpl.tombstoneBoxName);
  final syncMetaBox = await Hive.openBox<dynamic>(SyncLocalDataSource.boxName);
  final activeRideBox =
      await Hive.openBox<dynamic>(ActiveRideLocalDataSourceImpl.boxName);
  final prefsBox = await Hive.openBox<dynamic>(WebRecordingNotice.boxName);

  WebRecordingNotice.bindBox(prefsBox);

  // Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // Data sources
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSource());
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<RideLocalDataSource>(
    () => RideLocalDataSourceImpl(rideBox, tombstoneBox),
  );
  sl.registerLazySingleton<SyncLocalDataSource>(
    () => SyncLocalDataSource(syncMetaBox, sl<AuthLocalDataSource>()),
  );
  sl.registerLazySingleton<ActiveRideLocalDataSource>(
    () => ActiveRideLocalDataSourceImpl(activeRideBox),
  );
  sl.registerLazySingleton<RideRemoteDataSource>(
    () => RideRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSource(sl<ApiClient>()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      apiClient: sl<ApiClient>(),
    ),
  );
  sl.registerLazySingleton<RideRepository>(
    () => RideRepositoryImpl(
      localDataSource: sl<RideLocalDataSource>(),
      remoteDataSource: sl<RideRemoteDataSource>(),
      syncLocalDataSource: sl<SyncLocalDataSource>(),
      // A callback rather than an AuthRepository dependency, so the ride data
      // layer does not depend on auth.
      currentUserId: () async =>
          (await sl<AuthLocalDataSource>().getUser())?.id,
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllRides(sl<RideRepository>()));
  sl.registerLazySingleton(() => GetRideById(sl<RideRepository>()));
  sl.registerLazySingleton(() => SaveRide(sl<RideRepository>()));
  sl.registerLazySingleton(() => DeleteRide(sl<RideRepository>()));
  sl.registerLazySingleton(() => SyncRides(sl<RideRepository>()));
  sl.registerLazySingleton(() => GetPendingRideCount(sl<RideRepository>()));

  // Services
  sl.registerLazySingleton<LocationService>(() => LocationServiceImpl());
  sl.registerLazySingleton<ScreenWakeService>(() => ScreenWakeServiceImpl());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityServiceImpl());

  // Providers
  sl.registerFactory(
    () => AuthProvider(sl<AuthRepository>(), sl<ApiClient>()),
  );
  sl.registerFactory(
    () => RideListProvider(
      getAllRides: sl<GetAllRides>(),
      deleteRide: sl<DeleteRide>(),
      syncRides: sl<SyncRides>(),
    ),
  );
  sl.registerFactory(() => RideDetailProvider(getRideById: sl<GetRideById>()));
  sl.registerFactory(
    () => RecordRideProvider(
      saveRide: sl<SaveRide>(),
      locationService: sl<LocationService>(),
      screenWakeService: sl<ScreenWakeService>(),
      activeRideStore: sl<ActiveRideLocalDataSource>(),
    ),
  );
  sl.registerFactory(() => SyncProvider(
        sl<RideRepository>(),
        onConnectivityRestored: sl<ConnectivityService>().onRestored,
      ));
  sl.registerFactory(() => FeedProvider(sl<RideRemoteDataSource>()));
  sl.registerFactory(() => UserSearchProvider(sl<UserRemoteDataSource>()));
  sl.registerFactory(() => UserProfileProvider(sl<UserRemoteDataSource>()));
}
