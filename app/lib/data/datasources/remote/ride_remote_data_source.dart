import 'package:drive_journal/data/models/ride_model.dart';

/// Remote data source for syncing rides with a backend API.
///
/// TODO: Implement actual API calls when backend is available.
/// This stub allows the app to work fully offline. When a backend
/// is connected, implement each method to:
/// - POST rides to the server
/// - GET rides from the server
/// - Handle conflict resolution for offline/online sync
/// - Add authentication headers
abstract class RideRemoteDataSource {
  Future<List<RideModel>> getAllRides();
  Future<RideModel?> getRideById(String id);
  Future<void> saveRide(RideModel ride);
  Future<void> deleteRide(String id);
  Future<void> syncRides(List<RideModel> localRides);
}

class RideRemoteDataSourceImpl implements RideRemoteDataSource {
  // TODO: Inject HTTP client (e.g., dio or http package) when backend is ready
  // final Dio _dio;
  // final String _baseUrl;

  RideRemoteDataSourceImpl();

  @override
  Future<List<RideModel>> getAllRides() async {
    // TODO: GET /api/rides
    return [];
  }

  @override
  Future<RideModel?> getRideById(String id) async {
    // TODO: GET /api/rides/:id
    return null;
  }

  @override
  Future<void> saveRide(RideModel ride) async {
    // TODO: POST /api/rides
  }

  @override
  Future<void> deleteRide(String id) async {
    // TODO: DELETE /api/rides/:id
  }

  @override
  Future<void> syncRides(List<RideModel> localRides) async {
    // TODO: POST /api/rides/sync
    // Implement conflict resolution strategy:
    // - Compare timestamps
    // - Server wins / client wins / manual merge
  }
}
