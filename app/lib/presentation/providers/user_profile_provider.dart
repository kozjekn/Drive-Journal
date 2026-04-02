import 'package:flutter/foundation.dart';
import 'package:ride_journal/data/datasources/remote/user_remote_data_source.dart';
import 'package:ride_journal/domain/entities/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  final UserRemoteDataSource _userRemoteDataSource;

  UserProfileProvider(this._userRemoteDataSource);

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;
  List<UserProfile> _followers = [];
  List<UserProfile> _following = [];

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<UserProfile> get followers => _followers;
  List<UserProfile> get following => _following;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _userRemoteDataSource.getProfile(userId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadFollowers(String userId) async {
    try {
      _followers = await _userRemoteDataSource.getFollowers(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadFollowing(String userId) async {
    try {
      _following = await _userRemoteDataSource.getFollowing(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleFollow(String userId) async {
    if (_profile == null) return;

    try {
      if (_profile!.isFollowing) {
        await _userRemoteDataSource.unfollowUser(userId);
        _profile = UserProfile(
          id: _profile!.id,
          email: _profile!.email,
          displayName: _profile!.displayName,
          profilePictureBase64: _profile!.profilePictureBase64,
          followerCount: _profile!.followerCount - 1,
          followingCount: _profile!.followingCount,
          isFollowing: false,
          createdAt: _profile!.createdAt,
        );
      } else {
        await _userRemoteDataSource.followUser(userId);
        _profile = UserProfile(
          id: _profile!.id,
          email: _profile!.email,
          displayName: _profile!.displayName,
          profilePictureBase64: _profile!.profilePictureBase64,
          followerCount: _profile!.followerCount + 1,
          followingCount: _profile!.followingCount,
          isFollowing: true,
          createdAt: _profile!.createdAt,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
