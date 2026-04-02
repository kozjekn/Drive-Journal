import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drive_journal/domain/entities/user.dart';
import 'package:drive_journal/domain/entities/auth_token.dart';

class AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  AuthLocalDataSource([FlutterSecureStorage? secureStorage])
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> saveTokens(AuthToken token) async {
    await _secureStorage.write(key: 'access_token', value: token.accessToken);
    await _secureStorage.write(key: 'refresh_token', value: token.refreshToken);
    await _secureStorage.write(
        key: 'expires_at', value: token.expiresAt.toIso8601String());
  }

  Future<AuthToken?> getTokens() async {
    final accessToken = await _secureStorage.read(key: 'access_token');
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    final expiresAtStr = await _secureStorage.read(key: 'expires_at');

    if (accessToken == null || refreshToken == null || expiresAtStr == null) {
      return null;
    }

    return AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.parse(expiresAtStr),
    );
  }

  Future<void> saveUser(User user) async {
    final json = jsonEncode({
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'profilePictureBase64': user.profilePictureBase64,
      'createdAt': user.createdAt.toIso8601String(),
    });
    await _secureStorage.write(key: 'current_user', value: json);
  }

  Future<User?> getUser() async {
    final jsonStr = await _secureStorage.read(key: 'current_user');
    if (jsonStr == null) return null;

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      profilePictureBase64: map['profilePictureBase64'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Future<void> saveLastSyncAt(DateTime syncAt) async {
    await _secureStorage.write(
        key: 'last_sync_at', value: syncAt.toIso8601String());
  }

  Future<DateTime?> getLastSyncAt() async {
    final str = await _secureStorage.read(key: 'last_sync_at');
    if (str == null) return null;
    return DateTime.parse(str);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
