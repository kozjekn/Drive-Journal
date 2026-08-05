import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ride_journal/core/services/location_capabilities.dart';
import 'package:ride_journal/core/services/location_service.dart';
import 'package:ride_journal/core/services/screen_wake_service.dart';
import 'package:ride_journal/data/datasources/local/active_ride_local_data_source.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/entities/route_point.dart';
import 'package:ride_journal/domain/entities/sync_outcome.dart';
import 'package:ride_journal/domain/repositories/ride_repository.dart';
import 'package:ride_journal/presentation/providers/ride_list_provider.dart';

class MockRideRepository implements RideRepository {
  final List<Ride> _rides = [];

  /// What [syncRides] returns; set it to a failure to exercise error paths.
  SyncOutcome nextSyncOutcome = const SyncOutcome();
  int syncCallCount = 0;
  String? boundUserId;
  bool clearedLocalData = false;

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
  Future<SyncOutcome> syncRides() async {
    syncCallCount++;
    return nextSyncOutcome;
  }

  @override
  Future<int> pendingRideCount() async =>
      _rides.where((r) => r.isPendingSync).length;

  @override
  Future<SyncStatus> syncStatus() async => SyncStatus(
        pendingRideIds:
            _rides.where((r) => r.isPendingSync).map((r) => r.id).toList(),
        tombstoneIds: const [],
        lastSyncAt: null,
        ridesOwnerUserId: boundUserId,
      );

  @override
  Future<void> bindToUser(String userId) async {
    if (boundUserId != userId) _rides.clear();
    boundUserId = userId;
  }

  @override
  Future<void> clearLocalData() async {
    _rides.clear();
    clearedLocalData = true;
  }

  void addRide(Ride ride) => _rides.add(ride);
  void clear() => _rides.clear();
}

class MockRideListProvider extends ChangeNotifier implements RideListProvider {
  List<Ride> _rides = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String? _syncError;

  @override
  List<Ride> get rides => _rides;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isRefreshing => _isRefreshing;

  @override
  String? get error => _error;

  @override
  String? get syncError => _syncError;

  @override
  int get pendingCount => _rides.where((r) => r.isPendingSync).length;

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

  void setSyncError(String? error) {
    _syncError = error;
    notifyListeners();
  }

  @override
  Future<void> loadRides() async {
    // No-op in mock
  }

  @override
  Future<void> refresh() async {
    _isRefreshing = false;
    notifyListeners();
  }

  @override
  Future<void> deleteRide(String id) async {
    _rides.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}

/// Feeds a scripted position stream so tracking behaviour is testable without a
/// device.
class MockLocationService implements LocationService {
  MockLocationService({
    this.throwOnPermissions,
    LocationCapabilities? capabilities,
  }) : _capabilities = capabilities ??
            const LocationCapabilities(
              tracksWithScreenOff: true,
              hasForegroundService: true,
              canOpenSystemSettings: true,
              platformLabel: 'test',
            );

  final Object? throwOnPermissions;
  final LocationCapabilities _capabilities;

  final StreamController<Position> controller =
      StreamController<Position>.broadcast();

  Position? currentPosition;
  int permissionCallCount = 0;

  @override
  LocationCapabilities get capabilities => _capabilities;

  @override
  Future<void> ensurePermissions() async {
    permissionCallCount++;
    final failure = throwOnPermissions;
    if (failure != null) throw failure;
  }

  @override
  Future<Position> getCurrentPosition() async {
    final position = currentPosition;
    if (position == null) throw Exception('No position configured');
    return position;
  }

  @override
  Stream<Position> positionStream() => controller.stream;

  void emit(Position position) => controller.add(position);
  void emitError(Object error) => controller.addError(error);
  Future<void> close() => controller.close();
}

class MockScreenWakeService implements ScreenWakeService {
  MockScreenWakeService({this.acquireResult = true});

  /// Set false to simulate an installed iOS PWA below 18.4, where the request
  /// succeeds but no lock is actually held.
  final bool acquireResult;

  bool held = false;
  int acquireCount = 0;
  int releaseCount = 0;

  @override
  Future<bool> acquire() async {
    acquireCount++;
    held = acquireResult;
    return acquireResult;
  }

  @override
  Future<void> release() async {
    releaseCount++;
    held = false;
  }

  @override
  Future<bool> get isHeld async => held;
}

/// In-memory stand-in for the append-only Hive active-ride store.
class MockActiveRideLocalDataSource implements ActiveRideLocalDataSource {
  final List<List<RoutePoint>> chunks = [];
  String? id;
  String? name;
  DateTime? startTime;
  int clearCount = 0;

  /// Snapshot returned by [load]; set it to simulate a recoverable ride.
  ActiveRideSnapshot? snapshot;

  @override
  Future<void> begin({
    required String id,
    required String name,
    required DateTime startTime,
    int startingChunk = 0,
  }) async {
    this.id = id;
    this.name = name;
    this.startTime = startTime;
    if (startingChunk == 0) chunks.clear();
  }

  @override
  Future<void> appendPoints(List<RoutePoint> points) async {
    if (points.isEmpty) return;
    chunks.add(List.of(points));
  }

  @override
  Future<ActiveRideSnapshot?> load() async => snapshot;

  @override
  Future<void> clear() async {
    clearCount++;
    chunks.clear();
    snapshot = null;
  }

  List<RoutePoint> get allPoints => chunks.expand((c) => c).toList();
}

/// Builds a [Position] with sensible defaults so tests only state what matters.
Position testPosition({
  required double latitude,
  required double longitude,
  double altitude = 100,
  double speed = 10,
  double accuracy = 5,
  DateTime? timestamp,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime(2026, 8, 3, 12),
    accuracy: accuracy,
    altitude: altitude,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: speed,
    speedAccuracy: 1,
  );
}
