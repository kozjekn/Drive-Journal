import 'package:flutter/foundation.dart';
import 'package:drive_journal/data/datasources/remote/ride_remote_data_source.dart';
import 'package:drive_journal/domain/entities/ride.dart';

class FeedProvider extends ChangeNotifier {
  final RideRemoteDataSource _rideRemoteDataSource;

  FeedProvider(this._rideRemoteDataSource);

  List<Ride> _rides = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<Ride> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> loadFeed({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newRides = await _rideRemoteDataSource.getFeed(
        page: _currentPage,
        pageSize: 20,
      );

      if (refresh) {
        _rides = newRides.map((m) => m.toEntity()).toList();
      } else {
        _rides.addAll(newRides.map((m) => m.toEntity()));
      }

      _hasMore = newRides.length == 20;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
