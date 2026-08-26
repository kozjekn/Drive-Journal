import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ride_journal/core/theme/app_theme.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/entities/route_point.dart';
import 'package:ride_journal/domain/usecases/save_ride.dart';
import 'package:ride_journal/presentation/pages/fullscreen_map_page.dart';
import 'package:ride_journal/presentation/pages/ride_list_page.dart';
import 'package:ride_journal/presentation/providers/record_ride_provider.dart';
import 'package:ride_journal/presentation/providers/ride_list_provider.dart';
import 'package:ride_journal/presentation/providers/sync_provider.dart';
import 'package:ride_journal/presentation/widgets/ride_card.dart';
import 'package:ride_journal/presentation/widgets/ride_map_widget.dart';
import 'package:ride_journal/presentation/widgets/stat_tile.dart';

import 'mocks.dart';

/// A 1x1 transparent PNG, so `flutter_map`'s TileLayer gets a decodable image
/// instead of the test binding's blanket 400.
final _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _TransparentTileHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest(url);

  // What flutter_map's NetworkTileProvider actually calls.
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest(url);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.uri);

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  // package:http's IOClient streams the (empty) request body before closing.
  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<void> flush() async {}

  @override
  Future<HttpClientResponse> get done async => _FakeHttpClientResponse();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Ride _sampleRide() => Ride(
      id: 'ride-1',
      name: 'Morning Ride',
      distanceMeters: 15230,
      duration: const Duration(hours: 1, minutes: 15),
      avgSpeedKmh: 45.2,
      maxSpeedKmh: 82.0,
      elevationGainMeters: 120,
      startTime: DateTime(2026, 3, 15, 8, 30),
      endTime: DateTime(2026, 3, 15, 9, 45),
      routePoints: const [],
      updatedAt: DateTime(2026, 3, 15, 9, 45),
      syncedAt: DateTime(2026, 3, 15, 9, 46),
    );

void main() {
  group('RideCard Widget', () {
    testWidgets('displays ride name, distance, duration, speed', (
      WidgetTester tester,
    ) async {
      final ride = Ride(
        id: '1',
        name: 'Morning Ride',
        distanceMeters: 15230,
        duration: const Duration(hours: 1, minutes: 15),
        avgSpeedKmh: 45.2,
        maxSpeedKmh: 82.0,
        elevationGainMeters: 120,
        startTime: DateTime(2025, 3, 15, 8, 30),
        endTime: DateTime(2025, 3, 15, 9, 45),
        routePoints: const [],
        updatedAt: DateTime(2025, 3, 15, 9, 45),
      );

      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: RideCard(ride: ride, onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('Morning Ride'), findsOneWidget);
      expect(find.text('15.23 km'), findsOneWidget);
      expect(find.text('1h 15m 0s'), findsOneWidget);
      expect(find.text('45.2 km/h'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });
  });

  group('StatTile Widget', () {
    testWidgets('displays icon, label, and value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StatTile(
              icon: Icons.speed,
              label: 'Avg Speed',
              value: '45.2 km/h',
            ),
          ),
        ),
      );

      expect(find.text('45.2 km/h'), findsOneWidget);
      expect(find.text('Avg Speed'), findsOneWidget);
      expect(find.byIcon(Icons.speed), findsOneWidget);
    });
  });

  group('RideMapWidget fullscreen', () {
    setUp(() {
      // flutter_map fetches OSM tiles, and the test binding answers every HTTP
      // request with a 400 — 18 uncaught ClientExceptions that fail the test
      // before it can assert anything. Serve a 1x1 PNG instead; these tests are
      // about the expand/close affordances, not tile rendering.
      final original = HttpOverrides.current;
      HttpOverrides.global = _TransparentTileHttpOverrides();
      addTearDown(() => HttpOverrides.global = original);
    });

    // Two points so the bounds-fitting path is exercised, not the degenerate
    // single-point one.
    final route = [
      RoutePoint(
        latitude: 46.05,
        longitude: 14.50,
        altitude: 300,
        speed: 5,
        timestamp: DateTime(2026, 3, 15, 8, 30),
      ),
      RoutePoint(
        latitude: 46.06,
        longitude: 14.52,
        altitude: 320,
        speed: 6,
        timestamp: DateTime(2026, 3, 15, 8, 40),
      ),
    ];

    Widget wrapMap({required List<RoutePoint> points, bool expandable = true}) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: RideMapWidget(
            routePoints: points,
            height: 250,
            expandable: expandable,
            title: 'Morning Ride',
          ),
        ),
      );
    }

    testWidgets('expand button opens fullscreen and the X closes it',
        (tester) async {
      await tester.pumpWidget(wrapMap(points: route));
      await tester.pump();

      expect(find.byIcon(Icons.fullscreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FullscreenMapPage), findsOneWidget);
      expect(find.text('Morning Ride'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FullscreenMapPage), findsNothing);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    testWidgets('no expand affordance without a route', (tester) async {
      await tester.pumpWidget(wrapMap(points: const []));
      await tester.pump();

      expect(find.text('No route data available'), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsNothing);
    });
  });

  group('RideListPage Widget', () {
    /// The page reads RecordRideProvider (unfinished-ride banner) and
    /// SyncProvider (post-delete / post-recording upload) too, so all three have
    /// to be in scope. SyncProvider has no bound user here, so sync() no-ops.
    Widget wrap(MockRideListProvider listProvider) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<RideListProvider>.value(value: listProvider),
            ChangeNotifierProvider<SyncProvider>(
              create: (_) =>
                  SyncProvider(MockRideRepository(), observeLifecycle: false),
            ),
            ChangeNotifierProvider<RecordRideProvider>(
              create: (_) => RecordRideProvider(
                saveRide: SaveRide(MockRideRepository()),
                locationService: MockLocationService(),
                screenWakeService: MockScreenWakeService(),
                activeRideStore: MockActiveRideLocalDataSource(),
                observeLifecycle: false,
              ),
            ),
          ],
          child: const RideListPage(),
        ),
      );
    }

    testWidgets('shows empty state when no rides', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(MockRideListProvider()));
      await tester.pumpAndSettle();

      expect(find.text('No rides yet'), findsOneWidget);
      expect(find.text('Start Ride'), findsOneWidget);
    });

    testWidgets('empty state is still pull-to-refreshable', (tester) async {
      // A second device starts with zero local rides, so the empty state must
      // offer a way to pull them from the server.
      await tester.pumpWidget(wrap(MockRideListProvider()));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows a pending-upload banner and a cloud-off badge',
        (tester) async {
      final listProvider = MockRideListProvider()
        ..setRides([
          Ride(
            id: 'pending-1',
            name: 'Unsynced Ride',
            distanceMeters: 1000,
            duration: const Duration(minutes: 10),
            avgSpeedKmh: 6,
            maxSpeedKmh: 12,
            elevationGainMeters: 0,
            startTime: DateTime(2026, 8, 3, 9),
            endTime: DateTime(2026, 8, 3, 9, 10),
            routePoints: const [],
            updatedAt: DateTime(2026, 8, 3, 9, 10),
            // syncedAt null -> pending
          ),
        ]);

      await tester.pumpWidget(wrap(listProvider));
      await tester.pumpAndSettle();

      expect(find.text('1 ride not uploaded yet'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('swiping a card asks before deleting, and Cancel keeps it',
        (tester) async {
      final listProvider = MockRideListProvider()..setRides([_sampleRide()]);

      await tester.pumpWidget(wrap(listProvider));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(RideCard), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete ride?'), findsOneWidget);
      expect(listProvider.deletedIds, isEmpty);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete ride?'), findsNothing);
      expect(listProvider.deletedIds, isEmpty);
      expect(find.text('Morning Ride'), findsOneWidget);
    });

    testWidgets('confirming the dialog deletes the ride', (tester) async {
      final listProvider = MockRideListProvider()..setRides([_sampleRide()]);

      await tester.pumpWidget(wrap(listProvider));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(RideCard), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(listProvider.deletedIds, ['ride-1']);
      expect(find.text('Morning Ride'), findsNothing);
    });

    testWidgets('shows no pending banner once rides are synced', (tester) async {
      final syncedAt = DateTime(2026, 8, 3, 9, 11);
      final listProvider = MockRideListProvider()
        ..setRides([
          Ride(
            id: 'synced-1',
            name: 'Synced Ride',
            distanceMeters: 1000,
            duration: const Duration(minutes: 10),
            avgSpeedKmh: 6,
            maxSpeedKmh: 12,
            elevationGainMeters: 0,
            startTime: DateTime(2026, 8, 3, 9),
            endTime: DateTime(2026, 8, 3, 9, 10),
            routePoints: const [],
            updatedAt: DateTime(2026, 8, 3, 9, 10),
            syncedAt: syncedAt,
          ),
        ]);

      await tester.pumpWidget(wrap(listProvider));
      await tester.pumpAndSettle();

      expect(find.textContaining('not uploaded yet'), findsNothing);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });
  });
}
