import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drive_journal/core/services/location_service.dart';
import 'package:drive_journal/core/utils/distance_calculator.dart';
import 'package:drive_journal/core/utils/elevation_calculator.dart';
import 'package:drive_journal/core/utils/speed_calculator.dart';
import 'package:drive_journal/domain/entities/ride.dart';
import 'package:drive_journal/domain/entities/route_point.dart';
import 'package:drive_journal/domain/usecases/save_ride.dart';
import 'package:uuid/uuid.dart';

enum RecordingState { idle, recording, saving, error }

class RecordRideProvider extends ChangeNotifier {
  final SaveRide _saveRide;
  final LocationService _locationService;
  final Uuid _uuid;

  RecordRideProvider({
    required SaveRide saveRide,
    required LocationService locationService,
    Uuid? uuid,
  }) : _saveRide = saveRide,
       _locationService = locationService,
       _uuid = uuid ?? const Uuid();

  RecordingState _state = RecordingState.idle;
  final List<RoutePoint> _routePoints = [];
  DateTime? _startTime;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;
  StreamSubscription<Position>? _positionSubscription;
  String? _error;

  RecordingState get state => _state;
  List<RoutePoint> get routePoints => List.unmodifiable(_routePoints);
  DateTime? get startTime => _startTime;
  Duration get elapsed => _elapsed;
  String? get error => _error;

  double get distanceMeters => DistanceCalculator.totalDistance(_routePoints);

  double get currentSpeedKmh {
    if (_routePoints.isEmpty) return 0.0;
    return _routePoints.last.speed * 3.6; // m/s to km/h
  }

  double get avgSpeedKmh => SpeedCalculator.averageSpeed(
    distanceMeters: distanceMeters,
    duration: _elapsed,
  );

  double get maxSpeedKmh => SpeedCalculator.maxSpeed(_routePoints);

  double get elevationGain =>
      ElevationCalculator.totalElevationGain(_routePoints);

  Future<void> startRecording() async {
    try {
      await _locationService.checkAndRequestPermission();

      _state = RecordingState.recording;
      _startTime = DateTime.now();
      _routePoints.clear();
      _elapsed = Duration.zero;
      _error = null;
      notifyListeners();

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsed = DateTime.now().difference(_startTime!);
        notifyListeners();
      });

      // Start GPS stream
      _positionSubscription = _locationService.getPositionStream().listen(
        _onPositionUpdate,
        onError: (dynamic error) {
          _error = 'GPS error: $error';
          notifyListeners();
        },
      );
    } catch (e) {
      _state = RecordingState.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  void _onPositionUpdate(Position position) {
    final point = RoutePoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: position.speed,
      timestamp: DateTime.now(),
    );
    _routePoints.add(point);
    notifyListeners();
  }

  Future<Ride?> stopRecording() async {
    if (_state != RecordingState.recording) return null;

    _state = RecordingState.saving;
    notifyListeners();

    _durationTimer?.cancel();
    _durationTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final endTime = DateTime.now();
    final finalDuration = endTime.difference(_startTime!);

    final ride = Ride(
      id: _uuid.v4(),
      name: _generateRideName(),
      distanceMeters: distanceMeters,
      duration: finalDuration,
      avgSpeedKmh: SpeedCalculator.averageSpeed(
        distanceMeters: distanceMeters,
        duration: finalDuration,
      ),
      maxSpeedKmh: SpeedCalculator.maxSpeed(_routePoints),
      elevationGainMeters: ElevationCalculator.totalElevationGain(_routePoints),
      startTime: _startTime!,
      endTime: endTime,
      routePoints: List.from(_routePoints),
    );

    try {
      await _saveRide(ride);
      _state = RecordingState.idle;
      _routePoints.clear();
      _startTime = null;
      _elapsed = Duration.zero;
      notifyListeners();
      return ride;
    } catch (e) {
      _state = RecordingState.error;
      _error = 'Failed to save ride: $e';
      notifyListeners();
      return null;
    }
  }

  String _generateRideName() {
    final now = _startTime ?? DateTime.now();
    final hour = now.hour;

    String timeOfDay;
    if (hour < 6) {
      timeOfDay = 'Night';
    } else if (hour < 12) {
      timeOfDay = 'Morning';
    } else if (hour < 17) {
      timeOfDay = 'Afternoon';
    } else if (hour < 21) {
      timeOfDay = 'Evening';
    } else {
      timeOfDay = 'Night';
    }

    return '$timeOfDay Ride';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
