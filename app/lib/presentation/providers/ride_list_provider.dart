import 'package:flutter/foundation.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/usecases/delete_ride.dart';
import 'package:ride_journal/domain/usecases/get_all_rides.dart';
import 'package:ride_journal/domain/usecases/sync_rides.dart';

class RideListProvider extends ChangeNotifier {
  final GetAllRides _getAllRides;
  final DeleteRide _deleteRide;
  final SyncRides _syncRides;

  RideListProvider({
    required GetAllRides getAllRides,
    required DeleteRide deleteRide,
    required SyncRides syncRides,
  })  : _getAllRides = getAllRides,
        _deleteRide = deleteRide,
        _syncRides = syncRides;

  List<Ride> _rides = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String? _syncError;

  List<Ride> get rides => _rides;
  bool get isLoading => _isLoading;

  /// Separate from [isLoading] so a pull-to-refresh does not replace the list
  /// with a full-screen spinner.
  bool get isRefreshing => _isRefreshing;

  String? get error => _error;
  String? get syncError => _syncError;

  /// Rides with local changes the server hasn't acknowledged.
  int get pendingCount => _rides.where((r) => r.isPendingSync).length;

  /// Local-only fast path for first paint.
  Future<void> loadRides() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rides = await _getAllRides();
    } catch (e) {
      _error = 'Failed to load rides: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Syncs with the server, then re-reads local storage. Hive stays the single
  /// source of truth for the UI — the server writes into it, never into the
  /// widget tree.
  Future<void> refresh() async {
    _isRefreshing = true;
    _syncError = null;
    notifyListeners();

    try {
      final outcome = await _syncRides();
      if (!outcome.succeeded) _syncError = outcome.error;
      _rides = await _getAllRides();
      _error = null;
    } catch (e) {
      _error = 'Failed to refresh rides: $e';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> deleteRide(String id) async {
    try {
      await _deleteRide(id);
      _rides.removeWhere((ride) => ride.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete ride: $e';
      notifyListeners();
    }
  }
}
