import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? profilePictureBase64;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.profilePictureBase64,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? profilePictureBase64,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profilePictureBase64: profilePictureBase64 ?? this.profilePictureBase64,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, profilePictureBase64, createdAt];
}
