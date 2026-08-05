/// What the current platform can actually do for location tracking.
///
/// The UI reads this instead of sniffing the platform itself, so the honest
/// "we can't track with the screen off here" messaging lives in one place.
class LocationCapabilities {
  /// True when the OS keeps delivering fixes with the screen off.
  ///
  /// False on web: no browser API can read GPS while the document is hidden.
  /// A service worker cannot help — `WorkerNavigator` has no `geolocation`
  /// property at all.
  final bool tracksWithScreenOff;

  /// True when an Android foreground service is backing the position stream.
  final bool hasForegroundService;

  /// False on web — `geolocator_web` throws `UnsupportedError` from
  /// `openAppSettings()` / `openLocationSettings()`.
  final bool canOpenSystemSettings;

  final String platformLabel;

  const LocationCapabilities({
    required this.tracksWithScreenOff,
    required this.hasForegroundService,
    required this.canOpenSystemSettings,
    required this.platformLabel,
  });

  LocationCapabilities copyWith({
    bool? tracksWithScreenOff,
    bool? hasForegroundService,
    bool? canOpenSystemSettings,
    String? platformLabel,
  }) {
    return LocationCapabilities(
      tracksWithScreenOff: tracksWithScreenOff ?? this.tracksWithScreenOff,
      hasForegroundService: hasForegroundService ?? this.hasForegroundService,
      canOpenSystemSettings:
          canOpenSystemSettings ?? this.canOpenSystemSettings,
      platformLabel: platformLabel ?? this.platformLabel,
    );
  }

  @override
  String toString() =>
      'LocationCapabilities($platformLabel, screenOff: $tracksWithScreenOff, '
      'fgs: $hasForegroundService, settings: $canOpenSystemSettings)';
}
