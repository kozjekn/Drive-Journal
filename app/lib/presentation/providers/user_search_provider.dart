import 'package:flutter/foundation.dart';
import 'package:ride_journal/data/datasources/remote/user_remote_data_source.dart';
import 'package:ride_journal/domain/entities/user_profile.dart';

class UserSearchProvider extends ChangeNotifier {
  final UserRemoteDataSource _userRemoteDataSource;

  UserSearchProvider(this._userRemoteDataSource);

  List<UserProfile> _results = [];
  bool _isLoading = false;
  String? _error;
  String _query = '';

  List<UserProfile> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get query => _query;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _results = [];
      _query = '';
      notifyListeners();
      return;
    }

    _query = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _results = await _userRemoteDataSource.searchUsers(query);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
