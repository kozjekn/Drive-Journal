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
  Future<SyncResult> syncRides(List<RideModel> localRides);
  Future<List<RideModel>> getFeed({int page, int pageSize});
  Future<List<RideModel>> getPublicRides(String userId);
}

class SyncResult {
  final List<RideModel> serverRides;

  SyncResult({required this.serverRides});
}

class RideRemoteDataSourceImpl implements RideRemoteDataSource {
  final ApiClient _apiClient;

  RideRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<RideModel>> getAllRides() async {
    try {
      final response = await _apiClient.dio.get('/api/rides');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
  Future<SyncResult> syncRides(List<RideModel> localRides) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/rides/sync',
        data: {'rides': localRides.map((r) => r.toJson()).toList()},
      );
      final serverRidesJson = response.data['serverRides'] as List<dynamic>;
      final serverRides = serverRidesJson
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return SyncResult(serverRides: serverRides);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<RideModel>> getFeed({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/rides/feed',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<RideModel>> getPublicRides(String userId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/rides/user/$userId/public',
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
