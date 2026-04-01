import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_journal/core/theme/app_theme.dart';
import 'package:drive_journal/di/injection.dart';
import 'package:drive_journal/presentation/pages/ride_list_page.dart';
import 'package:drive_journal/presentation/providers/record_ride_provider.dart';
import 'package:drive_journal/presentation/providers/ride_detail_provider.dart';
import 'package:drive_journal/presentation/providers/ride_list_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const RideTrackerApp());
}

class RideTrackerApp extends StatelessWidget {
  const RideTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<RideListProvider>()),
        ChangeNotifierProvider(create: (_) => sl<RideDetailProvider>()),
        ChangeNotifierProvider(create: (_) => sl<RecordRideProvider>()),
      ],
      child: MaterialApp(
        title: 'Ride Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const RideListPage(),
      ),
    );
  }
}
