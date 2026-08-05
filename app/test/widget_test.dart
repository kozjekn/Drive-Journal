import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ride_journal/core/theme/app_theme.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/usecases/save_ride.dart';
import 'package:ride_journal/presentation/pages/ride_list_page.dart';
import 'package:ride_journal/presentation/providers/record_ride_provider.dart';
import 'package:ride_journal/presentation/providers/ride_list_provider.dart';
import 'package:ride_journal/presentation/widgets/ride_card.dart';
import 'package:ride_journal/presentation/widgets/stat_tile.dart';

import 'mocks.dart';

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

  group('RideListPage Widget', () {
    /// The page reads RecordRideProvider too (for the unfinished-ride banner), so
    /// both providers have to be in scope.
    Widget wrap(MockRideListProvider listProvider) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<RideListProvider>.value(value: listProvider),
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
