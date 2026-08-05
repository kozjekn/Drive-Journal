import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ride_journal/core/network/api_client.dart';
import 'package:ride_journal/domain/entities/user.dart';
import 'package:ride_journal/domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<void>? _sessionExpiredSub;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthProvider(this._authRepository, ApiClient apiClient) {
    // Turns a silent auth death (revoked or expired refresh token) into a visible
    // login screen, rather than every request just failing.
    _sessionExpiredSub = apiClient.onSessionExpired.listen((_) {
      if (_status == AuthStatus.unauthenticated) return;
      _user = null;
      _errorMessage = 'Your session expired. Please sign in again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        _user = await _authRepository.getCurrentUser();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email: email, password: password);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> googleSignIn() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.googleSignIn();
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }
}
