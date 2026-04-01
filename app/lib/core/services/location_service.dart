import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drive_journal/core/error/exceptions.dart';

abstract class LocationService {
  Future<bool> checkAndRequestPermission();
  Future<Position> getCurrentPosition();
  Stream<Position> getPositionStream();
  void dispose();
}

class LocationServiceImpl implements LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5, // minimum distance in meters before update
  );

  /// Android-specific settings for background location tracking.
  /// Uses a foreground service notification to keep GPS active.
  static final AndroidSettings _androidSettings = AndroidSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,
    forceLocationManager: false,
    intervalDuration: const Duration(seconds: 2),
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationText: 'Ride Tracker is recording your ride',
      notificationTitle: 'Ride Tracker',
      enableWakeLock: true,
    ),
  );

  /// iOS-specific settings for background location tracking.
  static final AppleSettings _appleSettings = AppleSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,
    activityType: ActivityType.automotiveNavigation,
    pauseLocationUpdatesAutomatically: false,
    showBackgroundLocationIndicator: true,
    allowBackgroundLocationUpdates: true,
  );

  LocationSettings get _platformSettings {
    // TODO: Commented out since not working (tested only on android)
    // if (Platform.isAndroid) return _androidSettings;
    // if (Platform.isIOS) return _appleSettings;
    return _locationSettings;
  }

  @override
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Location services are disabled. Please enable them.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permissions are permanently denied. '
        'Please enable them in settings.',
      );
    }

    // For background tracking, we need "always" permission
    if (permission == LocationPermission.whileInUse) {
      // Request "always" permission for background tracking
      permission = await Geolocator.requestPermission();
    }

    return true;
  }

  @override
  Future<Position> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
    } catch (e) {
      throw LocationException('Failed to get current position: $e');
    }
  }

  @override
  Stream<Position> getPositionStream() {
    _positionSubscription?.cancel();

    try {
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: _platformSettings,
          ).listen(
            (position) {
              _positionController.add(position);
            },
            onError: (dynamic error) {
              debugPrint('GPS stream error with platform settings: $error');
              debugPrint('Falling back to basic LocationSettings...');
              _startFallbackStream();
            },
          );
    } catch (e) {
      debugPrint('Failed to start GPS stream: $e');
      debugPrint('Falling back to basic LocationSettings...');
      _startFallbackStream();
    }

    return _positionController.stream;
  }

  void _startFallbackStream() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _locationSettings,
        ).listen(
          (position) {
            _positionController.add(position);
          },
          onError: (dynamic error) {
            _positionController.addError(
              LocationException('Location stream error: $error'),
            );
          },
        );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _positionController.close();
  }
}
