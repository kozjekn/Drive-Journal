import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_journal/core/theme/app_theme.dart';
import 'package:ride_journal/di/injection.dart';
import 'package:ride_journal/presentation/pages/auth/login_page.dart';
import 'package:ride_journal/presentation/pages/home_page.dart';
import 'package:ride_journal/presentation/providers/auth_provider.dart';
import 'package:ride_journal/presentation/providers/record_ride_provider.dart';
import 'package:ride_journal/presentation/providers/ride_detail_provider.dart';
import 'package:ride_journal/presentation/providers/ride_list_provider.dart';

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
        ChangeNotifierProvider(
          create: (_) => sl<AuthProvider>()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => sl<RideListProvider>()),
        ChangeNotifierProvider(create: (_) => sl<RideDetailProvider>()),
        ChangeNotifierProvider(create: (_) => sl<RecordRideProvider>()),
      ],
      child: MaterialApp(
        title: 'RideJournal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const HomePage();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginPage();
    }
  }
}
