import 'package:flutter/foundation.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/usecases/get_ride_by_id.dart';

class RideDetailProvider extends ChangeNotifier {
  final GetRideById _getRideById;

  RideDetailProvider({required GetRideById getRideById})
    : _getRideById = getRideById;

  Ride? _ride;
  bool _isLoading = false;
  String? _error;

  Ride? get ride => _ride;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRide(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ride = await _getRideById(id);
      if (_ride == null) {
        _error = 'Ride not found';
      }
    } catch (e) {
      _error = 'Failed to load ride: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
