import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:geolocator/geolocator.dart';
import 'package:ride_journal/core/services/location_capabilities.dart';
import 'package:ride_journal/core/services/location_service.dart';
import 'package:ride_journal/core/services/screen_wake_service.dart';
import 'package:ride_journal/core/utils/distance_calculator.dart';
import 'package:ride_journal/core/utils/elevation_calculator.dart';
import 'package:ride_journal/core/utils/speed_calculator.dart';
import 'package:ride_journal/data/datasources/local/active_ride_local_data_source.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/entities/route_point.dart';
import 'package:ride_journal/domain/usecases/save_ride.dart';
import 'package:uuid/uuid.dart';

enum RecordingState { idle, recording, saving, error }

class RecordRideProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SaveRide _saveRide;
  final LocationService _locationService;
  final ScreenWakeService _screenWakeService;
  final ActiveRideLocalDataSource _activeRideStore;
  final Uuid _uuid;

  RecordRideProvider({
    required SaveRide saveRide,
    required LocationService locationService,
    required ScreenWakeService screenWakeService,
    required ActiveRideLocalDataSource activeRideStore,
    Uuid? uuid,
    bool observeLifecycle = true,
  })  : _saveRide = saveRide,
        _locationService = locationService,
        _screenWakeService = screenWakeService,
        _activeRideStore = activeRideStore,
        _uuid = uuid ?? const Uuid() {
    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
  }

  bool _observingLifecycle = false;

  // --- Thinning / quality thresholds ---------------------------------------
  //
  // The GPS stream now runs with distanceFilter 0 so the live readout stays
  // truthful while stationary. Thinning happens here instead, so "what the user
  // sees right now" and "what gets stored" are separate concerns.

  /// Fixes worse than this are ignored entirely.
  static const double _maxAcceptableAccuracy = 50.0;

  /// Minimum movement before a point joins the stored route.
  static const double _minStoredDistanceMeters = 4.0;

  /// Store a point at least this often even while stationary, so a stop still
  /// appears in the track.
  static const Duration _stationaryHeartbeat = Duration(seconds: 5);

  /// Segments shorter than this from a low-confidence fix are not counted
  /// towards distance — otherwise a parked bike accumulates phantom kilometres.
  static const double _jitterGuardMeters = 8.0;
  static const double _jitterGuardAccuracy = 25.0;

  // --- Persistence flush policy --------------------------------------------

  static const int _flushPointThreshold = 10;
  static const Duration _flushInterval = Duration(seconds: 15);

  // --- State ----------------------------------------------------------------

  RecordingState _state = RecordingState.idle;
  final List<RoutePoint> _routePoints = [];
  DateTime? _startTime;
  Timer? _durationTimer;
  Timer? _flushTimer;
  Duration _elapsed = Duration.zero;
  StreamSubscription<Position>? _positionSubscription;
  String? _error;
  String? _warning;

  /// Every fix, thinned or not. Drives the live speed readout and the map
  /// camera, so neither freezes when thinning drops a point.
  Position? _lastPosition;

  String? _rideId;
  final List<RoutePoint> _pendingFlush = [];
  DateTime? _lastFlushAt;
  bool _isFlushing = false;

  /// Running accumulators. The previous O(n) getters were recomputed from the
  /// full list on every build *and* on every 1-second timer tick.
  double _distanceMeters = 0;
  double _maxSpeedKmh = 0;
  double _elevationGain = 0;

  bool _wakeLockHeld = false;

  ActiveRideSnapshot? _recoverable;

  // --- Public API -----------------------------------------------------------

  RecordingState get state => _state;
  List<RoutePoint> get routePoints => List.unmodifiable(_routePoints);
  DateTime? get startTime => _startTime;
  Duration get elapsed => _elapsed;
  String? get error => _error;

  /// Non-fatal problem worth showing while recording continues (e.g. GPS
  /// signal lost). Rendered in every state, not only the error state.
  String? get warning => _warning;

  Position? get lastPosition => _lastPosition;

  LocationCapabilities get capabilities => _locationService.capabilities;

  /// Whether the screen wake lock is genuinely held. False on an installed iOS
  /// PWA below 18.4 even though the request appears to succeed.
  bool get wakeLockHeld => _wakeLockHeld;

  /// A recording found on disk from a previous session, if any.
  ActiveRideSnapshot? get recoverable => _recoverable;
  bool get hasRecoverableRide => _recoverable != null;

  double get distanceMeters => _distanceMeters;

  double get currentSpeedKmh => (_lastPosition?.speed ?? 0) * 3.6;

  double get avgSpeedKmh => SpeedCalculator.averageSpeed(
        distanceMeters: _distanceMeters,
        duration: _elapsed,
      );

  double get maxSpeedKmh => _maxSpeedKmh;

  double get elevationGain => _elevationGain;

  /// Loads any unfinished recording left on disk. Call once at startup.
  Future<void> checkForRecoverableRide() async {
    if (_state == RecordingState.recording) return;
    try {
      final snapshot = await _activeRideStore.load();
      // An empty snapshot is not worth offering to the user.
      _recoverable =
          (snapshot != null && snapshot.points.isNotEmpty) ? snapshot : null;
      if (_recoverable == null && snapshot != null) {
        await _activeRideStore.clear();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to check for recoverable ride: $e');
    }
  }

  Future<void> startRecording() async {
    if (_state == RecordingState.recording) return;
    try {
      await _locationService.ensurePermissions();

      // Acquire as early as possible: on web the NoSleep.js video fallback needs
      // to stay inside the originating user-gesture window.
      _wakeLockHeld = await _screenWakeService.acquire();

      _rideId = _uuid.v4();
      _startTime = DateTime.now();
      _resetTrack();
      _state = RecordingState.recording;
      _error = null;
      _warning = null;
      _recoverable = null;
      notifyListeners();

      await _activeRideStore.begin(
        id: _rideId!,
        name: _generateRideName(),
        startTime: _startTime!,
      );

      _startTimers();
      _subscribeToPositions();
    } catch (e) {
      await _screenWakeService.release();
      _wakeLockHeld = false;
      _state = RecordingState.error;
      _error = e is Exception ? _messageOf(e) : e.toString();
      notifyListeners();
    }
  }

  /// Continues a recording recovered from disk under its original id.
  Future<void> resumeRecoveredRide() async {
    final snapshot = _recoverable;
    if (snapshot == null || _state == RecordingState.recording) return;

    try {
      await _locationService.ensurePermissions();
      _wakeLockHeld = await _screenWakeService.acquire();

      _rideId = snapshot.id;
      _startTime = snapshot.startTime;
      _resetTrack();
      _routePoints.addAll(snapshot.points);
      _recomputeStatsFromTrack();

      _state = RecordingState.recording;
      _error = null;
      _warning = null;
      _recoverable = null;
      notifyListeners();

      await _activeRideStore.begin(
        id: snapshot.id,
        name: snapshot.name,
        startTime: snapshot.startTime,
        startingChunk: snapshot.chunkCount,
      );

      _startTimers();
      _subscribeToPositions();
    } catch (e) {
      await _screenWakeService.release();
      _wakeLockHeld = false;
      _state = RecordingState.error;
      _error = e is Exception ? _messageOf(e) : e.toString();
      notifyListeners();
    }
  }

  /// Saves a recovered recording without resuming it. `endTime` comes from the
  /// last stored fix, not `now()`, so the duration is not inflated by however
  /// long the app was closed.
  Future<Ride?> saveRecoveredRide() async {
    final snapshot = _recoverable;
    if (snapshot == null) return null;

    _state = RecordingState.saving;
    notifyListeners();

    final endTime = snapshot.lastPointTime ?? snapshot.startTime;
    final duration = endTime.difference(snapshot.startTime);
    final distance = DistanceCalculator.totalDistance(snapshot.points);

    final ride = Ride(
      id: snapshot.id,
      name: snapshot.name,
      distanceMeters: distance,
      duration: duration,
      avgSpeedKmh: SpeedCalculator.averageSpeed(
        distanceMeters: distance,
        duration: duration,
      ),
      maxSpeedKmh: SpeedCalculator.maxSpeed(snapshot.points),
      elevationGainMeters:
          ElevationCalculator.totalElevationGain(snapshot.points),
      startTime: snapshot.startTime,
      endTime: endTime,
      routePoints: List.of(snapshot.points),
      updatedAt: DateTime.now(),
    );

    try {
      await _saveRide(ride);
      await _activeRideStore.clear();
      _recoverable = null;
      _state = RecordingState.idle;
      notifyListeners();
      return ride;
    } catch (e) {
      _state = RecordingState.error;
      _error = 'Failed to save recovered ride: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> discardRecoveredRide() async {
    await _activeRideStore.clear();
    _recoverable = null;
    if (_state == RecordingState.error) _state = RecordingState.idle;
    notifyListeners();
  }

  Future<Ride?> stopRecording() async {
    if (_state != RecordingState.recording) return null;

    _state = RecordingState.saving;
    notifyListeners();

    await _teardownTracking();

    final endTime = DateTime.now();
    final finalDuration = endTime.difference(_startTime!);

    final ride = Ride(
      id: _rideId ?? _uuid.v4(),
      name: _generateRideName(),
      distanceMeters: _distanceMeters,
      duration: finalDuration,
      avgSpeedKmh: SpeedCalculator.averageSpeed(
        distanceMeters: _distanceMeters,
        duration: finalDuration,
      ),
      maxSpeedKmh: _maxSpeedKmh,
      elevationGainMeters: _elevationGain,
      startTime: _startTime!,
      endTime: endTime,
      routePoints: List.of(_routePoints),
      updatedAt: DateTime.now(),
    );

    try {
      await _saveRide(ride);
      await _activeRideStore.clear();
      _state = RecordingState.idle;
      _resetTrack();
      _startTime = null;
      _rideId = null;
      notifyListeners();
      return ride;
    } catch (e) {
      // The recording stays on disk so it can be recovered rather than lost.
      _state = RecordingState.error;
      _error = 'Failed to save ride: $e';
      notifyListeners();
      return null;
    }
  }

  void clearWarning() {
    if (_warning == null) return;
    _warning = null;
    notifyListeners();
  }

  // --- Position handling ----------------------------------------------------

  void _subscribeToPositions() {
    _positionSubscription = _locationService.positionStream().listen(
          _onPositionUpdate,
          onError: _onStreamError,
          // Without this, a torn-down foreground service leaves the provider
          // stuck in `recording` with a frozen UI and no indication why.
          onDone: _onStreamDone,
        );
  }

  void _onPositionUpdate(Position position) {
    _lastPosition = position;

    if (_warning != null) _warning = null;

    if (position.accuracy > 0 &&
        position.accuracy > _maxAcceptableAccuracy) {
      // Still refresh the live readout, but keep the garbage out of the track.
      notifyListeners();
      return;
    }

    final point = RoutePoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: position.speed,
      // Never DateTime.now(): with enableWakeLock Android can deliver a batch of
      // buffered fixes at once, and now() would stamp them all identically.
      timestamp: position.timestamp,
    );

    if (_shouldStore(point)) {
      _accumulateStats(point, position);
      _routePoints.add(point);
      _pendingFlush.add(point);
      _maybeFlush();
    }

    notifyListeners();
  }

  bool _shouldStore(RoutePoint point) {
    if (_routePoints.isEmpty) return true;
    final last = _routePoints.last;
    final metres = DistanceCalculator.between(last, point);
    if (metres >= _minStoredDistanceMeters) return true;
    return point.timestamp.difference(last.timestamp) >= _stationaryHeartbeat;
  }

  void _accumulateStats(RoutePoint point, Position position) {
    if (_routePoints.isNotEmpty) {
      final last = _routePoints.last;
      final segment = DistanceCalculator.between(last, point);
      final lowConfidence =
          position.accuracy > _jitterGuardAccuracy || position.accuracy <= 0;
      if (!(lowConfidence && segment < _jitterGuardMeters)) {
        _distanceMeters += segment;
      }
      final climb = point.altitude - last.altitude;
      if (climb > 0) _elevationGain += climb;
    }
    final speedKmh = point.speed * 3.6;
    if (speedKmh > _maxSpeedKmh) _maxSpeedKmh = speedKmh;
  }

  void _onStreamError(Object error) {
    // Permission revoked or services switched off is terminal — anything else
    // (transient POSITION_UNAVAILABLE, which is routine indoors and on iOS
    // Safari) should not abort a ride that is otherwise fine.
    if (error is PermissionDeniedException ||
        error is LocationServiceDisabledException) {
      _hardFail(_messageOf(error));
    } else {
      _warning = 'GPS signal lost — still recording';
      debugPrint('Transient GPS stream error: $error');
      notifyListeners();
    }
  }

  void _onStreamDone() {
    if (_state != RecordingState.recording) return;
    _hardFail(
      'Location updates stopped unexpectedly. Your ride so far has been saved '
      'and can be recovered.',
    );
  }

  void _hardFail(String message) {
    _teardownTracking().then((_) {
      _state = RecordingState.error;
      _error = message;
      notifyListeners();
    });
  }

  // --- Persistence ----------------------------------------------------------

  void _maybeFlush() {
    final due = _pendingFlush.length >= _flushPointThreshold ||
        _lastFlushAt == null ||
        DateTime.now().difference(_lastFlushAt!) >= _flushInterval;
    if (due) {
      // Deliberately not awaited: this runs on the position hot path.
      _flush();
    }
  }

  Future<void> _flush({bool force = false}) async {
    if (_isFlushing) return;
    if (_pendingFlush.isEmpty && !force) return;
    _isFlushing = true;
    final batch = List<RoutePoint>.of(_pendingFlush);
    _pendingFlush.clear();
    try {
      if (batch.isNotEmpty) {
        // Chunk numbering lives in the store's own meta, which is what makes a
        // resumed recording continue past the chunks it just loaded.
        await _activeRideStore.appendPoints(batch);
      }
      _lastFlushAt = DateTime.now();
    } catch (e) {
      // Put them back so the next flush retries rather than losing them.
      _pendingFlush.insertAll(0, batch);
      debugPrint('Failed to flush active ride points: $e');
    } finally {
      _isFlushing = false;
    }
  }

  // --- Lifecycle ------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_state != RecordingState.recording) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // On iOS `hidden` is the last callback before suspension, so this is the
        // highest-value flush there is.
        _flush(force: true);
      case AppLifecycleState.resumed:
        _reverifyWakeLock();
    }
  }

  Future<void> _reverifyWakeLock() async {
    // The Screen Wake Lock spec releases the sentinel whenever the document is
    // hidden. wakelock_plus re-acquires on visibilitychange, but verify rather
    // than assume.
    final held = await _screenWakeService.isHeld;
    if (!held) {
      final reacquired = await _screenWakeService.acquire();
      if (_wakeLockHeld != reacquired) {
        _wakeLockHeld = reacquired;
        notifyListeners();
      }
    }
  }

  // --- Helpers --------------------------------------------------------------

  void _startTimers() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed = DateTime.now().difference(_startTime!);
      notifyListeners();
    });
    // Heartbeat flush so a stationary rider still gets progress persisted.
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flush());
  }

  Future<void> _teardownTracking() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _flush(force: true);
    await _screenWakeService.release();
    _wakeLockHeld = false;
  }

  void _resetTrack() {
    _routePoints.clear();
    _pendingFlush.clear();
    _elapsed = Duration.zero;
    _distanceMeters = 0;
    _maxSpeedKmh = 0;
    _elevationGain = 0;
    _lastPosition = null;
    _lastFlushAt = null;
  }

  /// Recomputes accumulators from the full track. Only needed after loading a
  /// recovered recording — this is why the calculator utilities stay.
  void _recomputeStatsFromTrack() {
    _distanceMeters = DistanceCalculator.totalDistance(_routePoints);
    _maxSpeedKmh = SpeedCalculator.maxSpeed(_routePoints);
    _elevationGain = ElevationCalculator.totalElevationGain(_routePoints);
    _elapsed = _routePoints.isEmpty
        ? Duration.zero
        : _routePoints.last.timestamp.difference(_startTime!);
  }

  static String _messageOf(Object error) {
    final text = error.toString();
    // Strip the `SomeException: ` prefix so the UI shows the message alone.
    final colon = text.indexOf(': ');
    return colon >= 0 && colon < 40 ? text.substring(colon + 2) : text;
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
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _durationTimer?.cancel();
    _flushTimer?.cancel();
    _positionSubscription?.cancel();
    _screenWakeService.release();
    super.dispose();
  }
}
