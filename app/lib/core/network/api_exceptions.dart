import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timed out');
      case DioExceptionType.connectionError:
        return ApiException('No internet connection');
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        final message = data is Map ? data['message'] ?? 'Server error' : 'Server error';
        return ApiException(message, statusCode: error.response?.statusCode);
      default:
        return ApiException('An unexpected error occurred');
    }
  }

  @override
  String toString() => message;
}
