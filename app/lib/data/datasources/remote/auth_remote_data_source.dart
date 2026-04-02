import 'package:dio/dio.dart';
import 'package:ride_journal/core/network/api_client.dart';
import 'package:ride_journal/core/network/api_exceptions.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _apiClient.dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'displayName': displayName,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> googleAuth({required String idToken}) async {
    try {
      final response = await _apiClient.dio.post('/api/auth/google', data: {
        'idToken': idToken,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> refreshToken({required String refreshToken}) async {
    try {
      final response = await _apiClient.dio.post('/api/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
