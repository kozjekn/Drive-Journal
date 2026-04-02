import 'package:ride_journal/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  });
  Future<User> login({required String email, required String password});
  Future<User> googleSignIn();
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<bool> isAuthenticated();
}
