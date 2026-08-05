import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ride_journal/core/error/exceptions.dart';
import 'package:ride_journal/data/datasources/local/active_ride_local_data_source.dart';
import 'package:ride_journal/domain/entities/route_point.dart';
import 'package:ride_journal/domain/usecases/save_ride.dart';
import 'package:ride_journal/presentation/providers/record_ride_provider.dart';

import '../mocks.dart';

void main() {
  late MockRideRepository repository;
  late MockLocationService location;
  late MockScreenWakeService wakeLock;
  late MockActiveRideLocalDataSource activeStore;

  RecordRideProvider build({
    MockLocationService? locationService,
    MockScreenWakeService? screenWakeService,
  }) {
    location = locationService ?? MockLocationService();
    wakeLock = screenWakeService ?? MockScreenWakeService();
    return RecordRideProvider(
      saveRide: SaveRide(repository),
      locationService: location,
      screenWakeService: wakeLock,
      activeRideStore: activeStore,
      // The lifecycle observer needs a binding; these tests exercise the stream
      // logic instead.
      observeLifecycle: false,
    );
  }

  setUp(() {
    repository = MockRideRepository();
    activeStore = MockActiveRideLocalDataSource();
  });

  /// Lets the broadcast stream deliver queued events.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('point thinning', () {
    test('stores the first fix', () async {
      final provider = build();
      await provider.startRecording();

      location.emit(testPosition(latitude: 46.0, longitude: 14.0));
      await settle();

      expect(provider.routePoints, hasLength(1));
    });

    test('drops a fix that has barely moved', () async {
      final provider = build();
      await provider.startRecording();
      final t0 = DateTime(2026, 8, 3, 12);

      location.emit(
        testPosition(latitude: 46.0, longitude: 14.0, timestamp: t0),
      );
      await settle();
      // ~1 m away, 1 s later: under both the distance and heartbeat thresholds.
      location.emit(testPosition(
        latitude: 46.000009,
        longitude: 14.0,
        timestamp: t0.add(const Duration(seconds: 1)),
      ));
      await settle();

      expect(provider.routePoints, hasLength(1));
    });

    test('stores a fix once it has really moved', () async {
      final provider = build();
      await provider.startRecording();
      final t0 = DateTime(2026, 8, 3, 12);

      location.emit(
        testPosition(latitude: 46.0, longitude: 14.0, timestamp: t0),
      );
      await settle();
      // ~11 m away.
      location.emit(testPosition(
        latitude: 46.0001,
        longitude: 14.0,
        timestamp: t0.add(const Duration(seconds: 1)),
      ));
      await settle();

      expect(provider.routePoints, hasLength(2));
    });

    test('stores a heartbeat point while stationary', () async {
      final provider = build();
      await provider.startRecording();
      final t0 = DateTime(2026, 8, 3, 12);

      location.emit(
        testPosition(latitude: 46.0, longitude: 14.0, timestamp: t0),
      );
      await settle();
      // Same spot, but 6 s later — a stop should still appear in the track.
      location.emit(testPosition(
        latitude: 46.0,
        longitude: 14.0,
        timestamp: t0.add(const Duration(seconds: 6)),
      ));
      await settle();

      expect(provider.routePoints, hasLength(2));
    });

    test('rejects a low-accuracy fix but still updates the live speed',
        () async {
      final provider = build();
      await provider.startRecording();

      location.emit(testPosition(
        latitude: 46.0,
        longitude: 14.0,
        accuracy: 120,
        speed: 8,
      ));
      await settle();

      expect(provider.routePoints, isEmpty);
      // The readout must stay live even when the fix is too poor to store.
      expect(provider.currentSpeedKmh, closeTo(8 * 3.6, 0.01));
    });
  });

  group('live readout', () {
    test('speed comes from the latest fix, not the last stored point',
        () async {
      final provider = build();
      await provider.startRecording();
      final t0 = DateTime(2026, 8, 3, 12);

      location.emit(testPosition(
        latitude: 46.0,
        longitude: 14.0,
        speed: 20,
        timestamp: t0,
      ));
      await settle();
      // Stopped at a light: same position, speed 0, one second later — dropped
      // from the track, but the readout must show 0 rather than the old 20 m/s.
      location.emit(testPosition(
        latitude: 46.0,
        longitude: 14.0,
        speed: 0,
        timestamp: t0.add(const Duration(seconds: 1)),
      ));
      await settle();

      expect(provider.routePoints, hasLength(1));
      expect(provider.currentSpeedKmh, 0);
    });

    test('uses the platform timestamp, not wall-clock time', () async {
      final provider = build();
      await provider.startRecording();
      final stamp = DateTime(2026, 8, 3, 11, 22, 33);

      location.emit(
        testPosition(latitude: 46.0, longitude: 14.0, timestamp: stamp),
      );
      await settle();

      expect(provider.routePoints.single.timestamp, stamp);
    });
  });

  group('stream errors', () {
    test('a permission error is terminal', () async {
      final provider = build();
      await provider.startRecording();

      location.emitError(const PermissionDeniedException('denied'));
      await settle();
      await settle();

      expect(provider.state, RecordingState.error);
    });

    test('a transient error warns but keeps recording', () async {
      final provider = build();
      await provider.startRecording();

      location.emitError(Exception('POSITION_UNAVAILABLE'));
      await settle();

      expect(provider.state, RecordingState.recording);
      expect(provider.warning, isNotNull);
    });

    test('onDone while recording is terminal', () async {
      // A torn-down foreground service closes the stream; the old code sat in
      // `recording` forever with a frozen UI.
      final provider = build();
      await provider.startRecording();

      await location.close();
      await settle();
      await settle();

      expect(provider.state, RecordingState.error);
    });

    test('a failed permission check surfaces the message', () async {
      final provider = build(
        locationService: MockLocationService(
          throwOnPermissions:
              const LocationException('Location services are turned off.'),
        ),
      );

      await provider.startRecording();

      expect(provider.state, RecordingState.error);
      expect(provider.error, contains('Location services are turned off'));
    });
  });

  group('wake lock', () {
    test('reports the verified state, not the request', () async {
      // Mirrors an installed iOS PWA below 18.4: enable() resolves, nothing held.
      final provider = build(
        screenWakeService: MockScreenWakeService(acquireResult: false),
      );

      await provider.startRecording();

      expect(provider.wakeLockHeld, isFalse);
    });

    test('is held while recording and released on stop', () async {
      final provider = build();
      await provider.startRecording();
      expect(provider.wakeLockHeld, isTrue);

      location.emit(testPosition(latitude: 46.0, longitude: 14.0));
      await settle();
      await provider.stopRecording();

      expect(provider.wakeLockHeld, isFalse);
      expect(wakeLock.releaseCount, greaterThan(0));
    });

    test('is released when permissions fail', () async {
      final provider = build(
        locationService:
            MockLocationService(throwOnPermissions: Exception('nope')),
      );

      await provider.startRecording();

      expect(provider.wakeLockHeld, isFalse);
    });
  });

  group('persistence and recovery', () {
    test('flushes points to the active-ride store on stop', () async {
      final provider = build();
      await provider.startRecording();

      location.emit(testPosition(latitude: 46.0, longitude: 14.0));
      await settle();
      await provider.stopRecording();

      // Cleared after a successful save, so nothing is offered for recovery.
      expect(activeStore.clearCount, greaterThan(0));
    });

    test('offers a recoverable ride when one is on disk', () async {
      activeStore.snapshot = ActiveRideSnapshot(
        id: 'crashed-1',
        name: 'Morning Ride',
        startTime: DateTime(2026, 8, 3, 9),
        points: [
          RoutePoint(
            latitude: 46.0,
            longitude: 14.0,
            altitude: 300,
            speed: 10,
            timestamp: DateTime(2026, 8, 3, 9, 5),
          ),
        ],
        chunkCount: 1,
      );

      final provider = build();
      await provider.checkForRecoverableRide();

      expect(provider.hasRecoverableRide, isTrue);
    });

    test('ignores an empty snapshot', () async {
      activeStore.snapshot = ActiveRideSnapshot(
        id: 'empty',
        name: 'Ride',
        startTime: DateTime(2026, 8, 3, 9),
        points: const [],
        chunkCount: 0,
      );

      final provider = build();
      await provider.checkForRecoverableRide();

      expect(provider.hasRecoverableRide, isFalse);
      expect(activeStore.clearCount, greaterThan(0));
    });

    test('save-as-is ends at the last fix, not now()', () async {
      final start = DateTime(2026, 8, 3, 9);
      final lastFix = DateTime(2026, 8, 3, 9, 30);
      activeStore.snapshot = ActiveRideSnapshot(
        id: 'crashed-1',
        name: 'Morning Ride',
        startTime: start,
        points: [
          RoutePoint(
            latitude: 46.0,
            longitude: 14.0,
            altitude: 300,
            speed: 10,
            timestamp: start,
          ),
          RoutePoint(
            latitude: 46.01,
            longitude: 14.01,
            altitude: 305,
            speed: 12,
            timestamp: lastFix,
          ),
        ],
        chunkCount: 1,
      );

      final provider = build();
      await provider.checkForRecoverableRide();
      final ride = await provider.saveRecoveredRide();

      expect(ride, isNotNull);
      // Using now() would inflate the duration by however long the app was shut.
      expect(ride!.endTime, lastFix);
      expect(ride.duration, const Duration(minutes: 30));
      expect(provider.hasRecoverableRide, isFalse);
    });

    test('resuming keeps the original ride id and track', () async {
      final start = DateTime(2026, 8, 3, 9);
      activeStore.snapshot = ActiveRideSnapshot(
        id: 'crashed-1',
        name: 'Morning Ride',
        startTime: start,
        points: [
          RoutePoint(
            latitude: 46.0,
            longitude: 14.0,
            altitude: 300,
            speed: 10,
            timestamp: start,
          ),
        ],
        chunkCount: 3,
      );

      final provider = build();
      await provider.checkForRecoverableRide();
      await provider.resumeRecoveredRide();

      expect(provider.state, RecordingState.recording);
      expect(provider.routePoints, hasLength(1));
      // Chunk numbering continues, so a flush cannot overwrite loaded chunks.
      expect(activeStore.id, 'crashed-1');
    });

    test('discard clears the store', () async {
      activeStore.snapshot = ActiveRideSnapshot(
        id: 'crashed-1',
        name: 'Ride',
        startTime: DateTime(2026, 8, 3, 9),
        points: [
          RoutePoint(
            latitude: 46.0,
            longitude: 14.0,
            altitude: 300,
            speed: 10,
            timestamp: DateTime(2026, 8, 3, 9),
          ),
        ],
        chunkCount: 1,
      );

      final provider = build();
      await provider.checkForRecoverableRide();
      await provider.discardRecoveredRide();

      expect(provider.hasRecoverableRide, isFalse);
      expect(activeStore.clearCount, greaterThan(0));
    });
  });

  group('stats', () {
    test('accumulates distance incrementally', () async {
      final provider = build();
      await provider.startRecording();
      final t0 = DateTime(2026, 8, 3, 12);

      location.emit(
        testPosition(latitude: 46.0, longitude: 14.0, timestamp: t0),
      );
      await settle();
      location.emit(testPosition(
        latitude: 46.001,
        longitude: 14.0,
        timestamp: t0.add(const Duration(seconds: 5)),
      ));
      await settle();

      // ~111 m per 0.001 degree of latitude.
      expect(provider.distanceMeters, closeTo(111, 5));
    });

    test('tracks max speed across the ride', () async {
      final provider = build();
      await provider.startRecording();
      final t0 = DateTime(2026, 8, 3, 12);

      location.emit(testPosition(
        latitude: 46.0,
        longitude: 14.0,
        speed: 10,
        timestamp: t0,
      ));
      await settle();
      location.emit(testPosition(
        latitude: 46.001,
        longitude: 14.0,
        speed: 25,
        timestamp: t0.add(const Duration(seconds: 5)),
      ));
      await settle();
      location.emit(testPosition(
        latitude: 46.002,
        longitude: 14.0,
        speed: 5,
        timestamp: t0.add(const Duration(seconds: 10)),
      ));
      await settle();

      expect(provider.maxSpeedKmh, closeTo(25 * 3.6, 0.01));
    });
  });
}
