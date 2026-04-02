import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_journal/di/injection.dart';
import 'package:drive_journal/presentation/pages/feed_page.dart';
import 'package:drive_journal/presentation/pages/ride_list_page.dart';
import 'package:drive_journal/presentation/pages/user_search_page.dart';
import 'package:drive_journal/presentation/pages/user_profile_page.dart';
import 'package:drive_journal/presentation/providers/auth_provider.dart';
import 'package:drive_journal/presentation/providers/feed_provider.dart';
import 'package:drive_journal/presentation/providers/user_profile_provider.dart';
import 'package:drive_journal/presentation/providers/user_search_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.user?.id ?? '';

    final pages = [
      const RideListPage(),
      ChangeNotifierProvider(
        create: (_) => sl<FeedProvider>(),
        child: const FeedPage(),
      ),
      ChangeNotifierProvider(
        create: (_) => sl<UserSearchProvider>(),
        child: const UserSearchPage(),
      ),
      ChangeNotifierProvider(
        create: (_) => sl<UserProfileProvider>(),
        child: UserProfilePage(userId: userId),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.motorcycle_outlined),
            selectedIcon: Icon(Icons.motorcycle),
            label: 'My Rides',
          ),
          NavigationDestination(
            icon: Icon(Icons.rss_feed_outlined),
            selectedIcon: Icon(Icons.rss_feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
