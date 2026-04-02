import 'package:flutter/foundation.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/usecases/delete_ride.dart';
import 'package:ride_journal/domain/usecases/get_all_rides.dart';

class RideListProvider extends ChangeNotifier {
  final GetAllRides _getAllRides;
  final DeleteRide _deleteRide;

  RideListProvider({
    required GetAllRides getAllRides,
    required DeleteRide deleteRide,
  }) : _getAllRides = getAllRides,
       _deleteRide = deleteRide;

  List<Ride> _rides = [];
  bool _isLoading = false;
  String? _error;

  List<Ride> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
