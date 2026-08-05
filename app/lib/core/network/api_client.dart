import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ride_journal/core/config/env_config.dart';

class ApiClient {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'expires_at';

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  /// In-flight refresh, so concurrent 401s share one attempt. Without this, N
  /// simultaneous 401s (very likely during a chunked sync) each fire a refresh —
  /// and since the server revokes a refresh token when it is used, every attempt
  /// after the first fails and kills the session outright.
  Future<bool>? _refreshFuture;

  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  /// Emits when the refresh token is gone or rejected. `AuthProvider` listens and
  /// shows the login screen, instead of the session dying silently.
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  ApiClient({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio.options.baseUrl = EnvConfig.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['Content-Type'] = 'application/json';

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: _accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final options = error.requestOptions;

        // Never try to refresh a failing auth call, and never retry twice —
        // otherwise a retry that also 401s recurses.
        final isAuthCall = options.path.contains('/api/auth/');
        final alreadyRetried = options.extra['retried'] == true;

        if (error.response?.statusCode == 401 && !isAuthCall && !alreadyRetried) {
          final refreshed = await _refresh();
          if (refreshed) {
            final token = await _secureStorage.read(key: _accessTokenKey);
            options.headers['Authorization'] = 'Bearer $token';
            options.extra['retried'] = true;
            try {
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  /// Refreshes the access token now. Exposed so `isAuthenticated()` can recover a
  /// session whose access token expired but whose refresh token is still valid.
  Future<bool> refreshNow() => _refresh();

  Future<bool> _refresh() {
    final existing = _refreshFuture;
    if (existing != null) return existing;

    final run = _doRefresh().whenComplete(() => _refreshFuture = null);
    _refreshFuture = run;
    return run;
  }

  Future<bool> _doRefresh() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        _sessionExpiredController.add(null);
        return false;
      }

      // A bare Dio, to avoid recursing through this interceptor.
      final response = await Dio().post(
        '${EnvConfig.apiBaseUrl}/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _secureStorage.write(
            key: _accessTokenKey, value: data['accessToken'] as String?);
        await _secureStorage.write(
            key: _refreshTokenKey, value: data['refreshToken'] as String?);

        // Persisting expiresAt is not optional. Without it the stored value stays
        // at the original login's expiry, so isAuthenticated() sees an expired
        // token on the next cold start and forces a logout roughly an hour after
        // every sign-in — which silently stops sync.
        final expiresAt = data['expiresAt'] as String?;
        if (expiresAt != null) {
          await _secureStorage.write(key: _expiresAtKey, value: expiresAt);
        }
        return true;
      }

      await _clearSession();
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await _clearSession();
      return false;
    }
  }

  Future<void> _clearSession() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expiresAtKey);
    _sessionExpiredController.add(null);
  }

  void dispose() {
    _sessionExpiredController.close();
  }
}
