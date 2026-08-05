import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_journal/core/config/env_config.dart';
import 'package:ride_journal/core/theme/app_theme.dart';
import 'package:ride_journal/di/injection.dart';
import 'package:ride_journal/presentation/pages/auth/login_page.dart';
import 'package:ride_journal/presentation/pages/home_page.dart';
import 'package:ride_journal/presentation/providers/auth_provider.dart';
import 'package:ride_journal/presentation/providers/record_ride_provider.dart';
import 'package:ride_journal/presentation/providers/ride_detail_provider.dart';
import 'package:ride_journal/presentation/providers/ride_list_provider.dart';
import 'package:ride_journal/presentation/providers/sync_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!EnvConfig.isConfigured) {
    // Loud rather than silent: without API_BASE_URL every network call fails, and
    // it looks exactly like a connectivity problem.
    debugPrint(
      'WARNING: API_BASE_URL is not set. Build with '
      '--dart-define-from-file=.env — all network requests will fail.',
    );
  }

  await configureDependencies();
  runApp(const RideJournalApp());
}

class RideJournalApp extends StatelessWidget {
  const RideJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => sl<AuthProvider>()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => sl<SyncProvider>()),
        ChangeNotifierProvider(create: (_) => sl<RideListProvider>()),
        ChangeNotifierProvider(create: (_) => sl<RideDetailProvider>()),
        ChangeNotifierProvider(
          create: (_) => sl<RecordRideProvider>()..checkForRecoverableRide(),
        ),
      ],
      child: MaterialApp(
        title: 'Ride Journal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

/// Also the place where sync learns about sign-in and sign-out.
///
/// Driving it from here rather than from `AuthProvider` keeps auth from depending
/// on the ride repository, which would invert the layering.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus? _lastStatus;
  String? _lastUserId;

  void _handleAuthTransition(AuthProvider auth) {
    final sync = context.read<SyncProvider>();
    final userId = auth.user?.id;

    switch (auth.status) {
      case AuthStatus.authenticated:
        // Fires on login and on app start, and again if the account changes —
        // bindToUser is what clears another user's rides off this device.
        if (_lastStatus != AuthStatus.authenticated || _lastUserId != userId) {
          if (userId != null) {
            _lastUserId = userId;
            sync.onSignedIn(userId);
          }
        }
      case AuthStatus.unauthenticated:
        if (_lastStatus == AuthStatus.authenticated) {
          _lastUserId = null;
          sync.onSignedOut();
        }
      case AuthStatus.initial:
      case AuthStatus.loading:
      case AuthStatus.error:
        break;
    }
    _lastStatus = auth.status;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.status != _lastStatus ||
        (authProvider.status == AuthStatus.authenticated &&
            authProvider.user?.id != _lastUserId)) {
      // Side effects belong outside build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleAuthTransition(authProvider);
      });
    }

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
