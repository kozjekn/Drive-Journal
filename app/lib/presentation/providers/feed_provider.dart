import 'package:flutter/foundation.dart';
import 'package:ride_journal/data/datasources/remote/ride_remote_data_source.dart';
import 'package:ride_journal/domain/entities/ride.dart';

class FeedProvider extends ChangeNotifier {
  static const int _pageSize = 20;

  final RideRemoteDataSource _rideRemoteDataSource;

  FeedProvider(this._rideRemoteDataSource);

  List<Ride> _rides = [];
  bool _isLoading = false;
  String? _error;

  /// Offset, not a page number: the endpoint takes skip/limit. Sending
  /// page/pageSize meant the params were dropped and every "page" returned the
  /// same first rows, which the old code then appended.
  int _skip = 0;
  bool _hasMore = true;

  List<Ride> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> loadFeed({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _skip = 0;
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newRides = await _rideRemoteDataSource.getFeed(
        skip: _skip,
        limit: _pageSize,
      );

      final entities = newRides.map((m) => m.toEntity()).toList();

      if (refresh) {
        _rides = entities;
      } else {
        // Dedupe by id: with offset paging a ride arriving between requests
        // shifts everything and re-serves a row, which throws on duplicate
        // Dismissible keys in the list.
        final seen = _rides.map((r) => r.id).toSet();
        _rides.addAll(entities.where((r) => seen.add(r.id)));
      }

      _hasMore = newRides.length == _pageSize;
      _skip += newRides.length;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
