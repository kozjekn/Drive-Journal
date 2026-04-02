import 'package:dio/dio.dart';
import 'package:ride_journal/core/network/api_client.dart';
import 'package:ride_journal/core/network/api_exceptions.dart';
import 'package:ride_journal/domain/entities/user_profile.dart';

class UserRemoteDataSource {
  final ApiClient _apiClient;

  UserRemoteDataSource(this._apiClient);

  Future<UserProfile> getProfile(String userId) async {
    try {
      final response = await _apiClient.dio.get('/api/users/$userId');
      return _parseProfile(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? profilePictureBase64,
  }) async {
    try {
      await _apiClient.dio.put('/api/users/profile', data: {
        'displayName': ?displayName,
        'profilePictureBase64': ?profilePictureBase64,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/users/search',
        queryParameters: {'q': query},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => _parseProfile(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> followUser(String userId) async {
    try {
      await _apiClient.dio.post('/api/users/$userId/follow');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      await _apiClient.dio.delete('/api/users/$userId/follow');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<UserProfile>> getFollowers(String userId) async {
    try {
      final response =
          await _apiClient.dio.get('/api/users/$userId/followers');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => _parseProfile(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<UserProfile>> getFollowing(String userId) async {
    try {
      final response =
          await _apiClient.dio.get('/api/users/$userId/following');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => _parseProfile(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  UserProfile _parseProfile(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      profilePictureBase64: data['profilePictureBase64'] as String?,
      followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
      isFollowing: data['isFollowing'] as bool? ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }
}
