import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ride_journal/core/theme/app_theme.dart';
import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/presentation/pages/ride_list_page.dart';
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
    testWidgets('shows empty state when no rides', (WidgetTester tester) async {
      final mockProvider = MockRideListProvider();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ChangeNotifierProvider<RideListProvider>.value(
            value: mockProvider,
            child: const RideListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No rides yet'), findsOneWidget);
      expect(find.text('Start Ride'), findsOneWidget);
    });
  });
}
