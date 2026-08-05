import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ride_journal/core/error/exceptions.dart';
import 'package:ride_journal/core/services/location_capabilities.dart';

abstract class LocationService {
  /// What this platform can do. Valid before [positionStream] is called, and
  /// refined afterwards (e.g. `hasForegroundService` flips to false if the
  /// Android foreground service could not be started).
  LocationCapabilities get capabilities;

  /// Throws [LocationException] if location cannot be used. Prompts at most once.
  Future<void> ensurePermissions();

  Future<Position> getCurrentPosition();

  /// The raw platform stream. Errors are **not** swallowed — the caller
  /// classifies them, because a silent downgrade is what hid the original
  /// "tracking stops when the screen turns off" bug.
  Stream<Position> positionStream();
}

class LocationServiceImpl implements LocationService {
  LocationCapabilities _capabilities = _initialCapabilities();

  @override
  LocationCapabilities get capabilities => _capabilities;

  static LocationCapabilities _initialCapabilities() {
    if (kIsWeb) {
      return const LocationCapabilities(
        tracksWithScreenOff: false,
        hasForegroundService: false,
        canOpenSystemSettings: false,
        platformLabel: 'web',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const LocationCapabilities(
          tracksWithScreenOff: true,
          hasForegroundService: true,
          canOpenSystemSettings: true,
          platformLabel: 'Android',
        );
      case TargetPlatform.iOS:
        return const LocationCapabilities(
          tracksWithScreenOff: true,
          hasForegroundService: false,
          canOpenSystemSettings: true,
          platformLabel: 'iOS',
        );
      default:
        return LocationCapabilities(
          tracksWithScreenOff: false,
          hasForegroundService: false,
          canOpenSystemSettings: true,
          platformLabel: defaultTargetPlatform.name,
        );
    }
  }

  // --- Platform settings -----------------------------------------------------
  //
  // distanceFilter is 0 everywhere. A non-zero filter means the platform
  // delivers nothing at all while stationary, which froze the live speed
  // readout and the map marker at every red light. Thinning happens
  // client-side in RecordRideProvider instead, where "update the live readout"
  // and "append to the stored route" can be separated.

  /// Android: a `foregroundServiceType="location"` service is the sanctioned way
  /// to keep GPS alive with the screen off, and exempts the app from Doze.
  static final AndroidSettings _androidSettings = AndroidSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
    forceLocationManager: false,
    intervalDuration: const Duration(seconds: 2),
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: 'Recording ride',
      notificationText: 'Ride Journal is tracking your route · tap to open',
      notificationChannelName: 'Ride recording',
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
      enableWakeLock: true,
      setOngoing: true,
      color: Color(0xFF009698),
    ),
  );

  /// iOS: `allowBackgroundLocationUpdates` only takes effect because
  /// `UIBackgroundModes` contains `location` in Info.plist — geolocator checks
  /// for exactly that before enabling it. "When In Use" authorization is
  /// sufficient; "Always" is not needed for updates started in the foreground.
  ///
  /// `pauseLocationUpdatesAutomatically: false` is essential — with the
  /// automotive activity type iOS would otherwise pause updates when it decides
  /// you have stopped, and may never resume them.
  static final AppleSettings _appleSettings = AppleSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
    activityType: ActivityType.automotiveNavigation,
    pauseLocationUpdatesAutomatically: false,
    showBackgroundLocationIndicator: true,
    allowBackgroundLocationUpdates: true,
  );

  /// Web and desktop. Deliberately plain [LocationSettings]:
  ///
  /// - `WebSettings` would require importing `geolocator_web`, which
  ///   transitively pulls `flutter_web_plugins` and breaks the native build.
  ///   geolocator_web falls back to the values we want when handed a plain
  ///   settings object.
  /// - Never set `timeLimit` on web: geolocator_web passes `inMicroseconds`
  ///   into a field measured in milliseconds, so a 10-second limit becomes
  ///   roughly 2.8 hours.
  static const LocationSettings _basicSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
  );

  /// `kIsWeb` must be checked *before* `defaultTargetPlatform`: on web the
  /// latter reports the host platform, so an installed PWA on an iPhone would
  /// otherwise be handed `AppleSettings`.
  LocationSettings get _platformSettings {
    if (kIsWeb) return _basicSettings;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidSettings;
      case TargetPlatform.iOS:
        return _appleSettings;
      default:
        return _basicSettings;
    }
  }

  // --- Permissions -----------------------------------------------------------

  @override
  Future<void> ensurePermissions() async {
    // Web always reports services as enabled; the check is meaningless there.
    if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'Location services are turned off. Please enable them and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();

    // `unableToDetermine` shows up on browsers without the Permissions API.
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location access is permanently denied. Enable it for Ride Journal in '
        'your system settings.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location access is required to record a ride.',
      );
    }

    // whileInUse and always are BOTH sufficient — we never re-request. A second
    // request would be bundled with background location by geolocator, and
    // Android 11+ silently discards any request that mixes the two.

    await _ensureNotificationPermission();
  }

  /// Android 13+ needs POST_NOTIFICATIONS for the foreground-service
  /// notification to be *visible*. The service still runs if denied, so this
  /// never throws.
  Future<void> _ensureNotificationPermission() async {
    // kIsWeb first: on web permission_handler resolves to permission_handler_html,
    // which does not support Permission.notification and would throw.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('Notification permission request failed (non-fatal): $e');
    }
  }

  // --- Position --------------------------------------------------------------

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
  Stream<Position> positionStream() {
    try {
      return Geolocator.getPositionStream(locationSettings: _platformSettings);
    } catch (e) {
      // The one deliberate degradation, and it is visible: if the Android
      // foreground service cannot be started, fall back to a plain stream and
      // record that background tracking is unavailable so the UI can say so.
      debugPrint('Failed to start platform position stream: $e');
      _capabilities = _capabilities.copyWith(
        hasForegroundService: false,
        tracksWithScreenOff: false,
      );
      return Geolocator.getPositionStream(locationSettings: _basicSettings);
    }
  }
}
