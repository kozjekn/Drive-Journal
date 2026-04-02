import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? profilePictureBase64;
  final int followerCount;
  final int followingCount;
  final bool isFollowing;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.profilePictureBase64,
    required this.followerCount,
    required this.followingCount,
    required this.isFollowing,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, email, displayName, profilePictureBase64,
    followerCount, followingCount, isFollowing, createdAt,
  ];
}
