import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_journal/presentation/pages/user_profile_page.dart';
import 'package:ride_journal/presentation/providers/user_search_provider.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<UserSearchProvider>().search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserSearchProvider>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search riders...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                context.read<UserSearchProvider>().search('');
              },
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Text(
                    provider.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                )
              : provider.results.isEmpty && provider.query.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text(
                            'No riders found',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : provider.results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search,
                                  size: 64, color: Colors.grey.shade600),
                              const SizedBox(height: 16),
                              Text(
                                'Search for other riders',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.results.length,
                          itemBuilder: (context, index) {
                            final user = provider.results[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(user.displayName),
                              subtitle: Text(user.email),
                              trailing: user.isFollowing
                                  ? const Chip(label: Text('Following'))
                                  : null,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UserProfilePage(userId: user.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
    );
  }
}
