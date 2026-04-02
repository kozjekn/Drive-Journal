import 'package:google_sign_in/google_sign_in.dart';
import 'package:drive_journal/core/config/env_config.dart';
import 'package:drive_journal/data/datasources/local/auth_local_data_source.dart';
import 'package:drive_journal/data/datasources/remote/auth_remote_data_source.dart';
import 'package:drive_journal/domain/entities/auth_token.dart';
import 'package:drive_journal/domain/entities/user.dart';
import 'package:drive_journal/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    GoogleSignIn? googleSignIn,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: EnvConfig.googleClientId.isNotEmpty
                  ? EnvConfig.googleClientId
                  : null,
            );

  @override
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final data = await _remoteDataSource.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    return _handleAuthResponse(data);
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final data = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    return _handleAuthResponse(data);
  }

  @override
  Future<User> googleSignIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Google sign-in cancelled');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw Exception('Failed to get Google ID token');

    final data = await _remoteDataSource.googleAuth(idToken: idToken);
    return _handleAuthResponse(data);
  }

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _localDataSource.clearAll();
  }

  @override
  Future<User?> getCurrentUser() async {
    return _localDataSource.getUser();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _localDataSource.getTokens();
    if (token == null) return false;
    if (token.isExpired) return false;
    return true;
  }

  Future<User> _handleAuthResponse(Map<String, dynamic> data) async {
    final token = AuthToken(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
    await _localDataSource.saveTokens(token);

    final userData = data['user'] as Map<String, dynamic>;
    final user = User(
      id: userData['id'] as String,
      email: userData['email'] as String,
      displayName: userData['displayName'] as String,
      profilePictureBase64: userData['profilePictureBase64'] as String?,
      createdAt: DateTime.parse(userData['createdAt'] as String),
    );
    await _localDataSource.saveUser(user);

    return user;
  }
}
