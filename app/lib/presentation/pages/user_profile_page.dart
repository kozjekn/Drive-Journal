import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_journal/presentation/providers/auth_provider.dart';
import 'package:drive_journal/presentation/providers/user_profile_provider.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UserProfileProvider>();
      provider.loadProfile(widget.userId);
      provider.loadFollowers(widget.userId);
      provider.loadFollowing(widget.userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isOwnProfile = authProvider.user?.id == widget.userId;

    if (profileProvider.isLoading && profileProvider.profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (profileProvider.error != null && profileProvider.profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            profileProvider.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    final profile = profileProvider.profile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.displayName),
        actions: isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => authProvider.logout(),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Profile header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  child: Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatColumn(
                        context, profile.followerCount.toString(), 'Followers'),
                    const SizedBox(width: 40),
                    _buildStatColumn(context,
                        profile.followingCount.toString(), 'Following'),
                  ],
                ),
                if (!isOwnProfile) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 160,
                    child: profile.isFollowing
                        ? OutlinedButton(
                            onPressed: () =>
                                profileProvider.toggleFollow(widget.userId),
                            child: const Text('Unfollow'),
                          )
                        : FilledButton(
                            onPressed: () =>
                                profileProvider.toggleFollow(widget.userId),
                            child: const Text('Follow'),
                          ),
                  ),
                ],
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(profileProvider.followers),
                _buildUserList(profileProvider.following),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildUserList(List users) {
    if (users.isEmpty) {
      return const Center(child: Text('No users'));
    }
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
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
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserProfilePage(userId: user.id),
              ),
            );
          },
        );
      },
    );
  }
}
