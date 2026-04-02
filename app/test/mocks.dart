import 'package:flutter/foundation.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/repositories/ride_repository.dart';
import 'package:ride_journal/presentation/providers/ride_list_provider.dart';

class MockRideRepository implements RideRepository {
  final List<Ride> _rides = [];

  @override
  Future<List<Ride>> getAllRides() async => List.from(_rides);

  @override
  Future<Ride?> getRideById(String id) async {
    try {
      return _rides.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRide(Ride ride) async {
    _rides.removeWhere((r) => r.id == ride.id);
    _rides.add(ride);
  }

  @override
  Future<void> deleteRide(String id) async {
    _rides.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> syncRides() async {
    // No-op in mock
  }

  void addRide(Ride ride) => _rides.add(ride);
  void clear() => _rides.clear();
}

class MockRideListProvider extends ChangeNotifier implements RideListProvider {
  List<Ride> _rides = [];
  bool _isLoading = false;
  String? _error;

  @override
  List<Ride> get rides => _rides;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  void setRides(List<Ride> rides) {
    _rides = rides;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  Future<void> loadRides() async {
    // No-op in mock
  }

  @override
  Future<void> deleteRide(String id) async {
    _rides.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
