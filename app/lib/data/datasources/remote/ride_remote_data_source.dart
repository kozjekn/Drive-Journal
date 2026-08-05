import 'package:dio/dio.dart';
import 'package:ride_journal/core/network/api_client.dart';
import 'package:ride_journal/core/network/api_exceptions.dart';
import 'package:ride_journal/data/models/ride_model.dart';

abstract class RideRemoteDataSource {
  Future<List<RideModel>> getAllRides();
  Future<RideModel?> getRideById(String id);
  Future<void> saveRide(RideModel ride);
  Future<void> updateRide(RideModel ride);
  Future<void> deleteRide(String id);

  /// Pushes [localRides] and pulls anything written after [lastSyncAt].
  /// Pass an empty list to pull only.
  Future<SyncResponse> syncRides(
    List<RideModel> localRides,
    DateTime? lastSyncAt,
  );

  Future<List<RideModel>> getFeed({int skip, int limit});
  Future<List<RideModel>> getPublicRides(String userId, {int skip, int limit});
}

/// Mirrors the backend `SyncRidesResponse`.
class SyncResponse {
  /// Cursor for the next pull. Server clock — never compared against a local one.
  final DateTime syncedAt;
  final List<RideModel> updatedRides;
  final List<String> deletedRideIds;
  final bool hasMore;

  const SyncResponse({
    required this.syncedAt,
    required this.updatedRides,
    required this.deletedRideIds,
    required this.hasMore,
  });
}

class RideRemoteDataSourceImpl implements RideRemoteDataSource {
  final ApiClient _apiClient;

  RideRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<RideModel>> getAllRides() async {
    try {
      final response = await _apiClient.dio.get('/api/rides');
      return _parseRideList(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<RideModel?> getRideById(String id) async {
    try {
      final response = await _apiClient.dio.get('/api/rides/$id');
      return RideModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> saveRide(RideModel ride) async {
    try {
      await _apiClient.dio.post('/api/rides', data: ride.toJson());
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> updateRide(RideModel ride) async {
    try {
      await _apiClient.dio.put('/api/rides/${ride.id}', data: ride.toJson());
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteRide(String id) async {
    try {
      await _apiClient.dio.delete('/api/rides/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<SyncResponse> syncRides(
    List<RideModel> localRides,
    DateTime? lastSyncAt,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/rides/sync',
        data: {
          // Previously never sent, so the server could not do a delta pull.
          'lastSyncAt': lastSyncAt?.toUtc().toIso8601String(),
          'rides': localRides.map((r) => r.toJson()).toList(),
        },
        // The global 30s receiveTimeout would kill a large first pull, and a
        // full push of long rides can take a while to upload.
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      final data = response.data as Map<String, dynamic>? ?? const {};

      // Null-safe throughout: the old code read a non-existent `serverRides` key
      // and cast null to List, throwing a TypeError that escaped the DioException
      // catch entirely.
      final updated = (data['updatedRides'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RideModel.fromJson)
          .toList();

      final deleted = (data['deletedRideIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList();

      final syncedAtRaw = data['syncedAt'] as String?;

      return SyncResponse(
        syncedAt: syncedAtRaw != null
            ? DateTime.parse(syncedAtRaw)
            : DateTime.now().toUtc(),
        updatedRides: updated,
        deletedRideIds: deleted,
        hasMore: data['hasMore'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<RideModel>> getFeed({int skip = 0, int limit = 20}) async {
    try {
      // skip/limit, not page/pageSize: the controller binds these names, so the
      // old params were dropped and every page returned the same first rows.
      final response = await _apiClient.dio.get(
        '/api/rides/feed',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return _parseRideList(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<RideModel>> getPublicRides(
    String userId, {
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/rides/user/$userId/public',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return _parseRideList(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  static List<RideModel> _parseRideList(dynamic data) {
    final list = data as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(RideModel.fromJson)
        .toList();
  }
}
