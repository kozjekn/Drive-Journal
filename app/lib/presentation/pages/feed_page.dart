import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_journal/presentation/providers/feed_provider.dart';
import 'package:ride_journal/presentation/widgets/ride_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadFeed(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<FeedProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.loadFeed();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: RefreshIndicator(
        onRefresh: () => feedProvider.loadFeed(refresh: true),
        child: feedProvider.rides.isEmpty && !feedProvider.isLoading
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rss_feed,
                              size: 64, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text(
                            'No rides in your feed',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Follow other riders to see their rides here',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount:
                    feedProvider.rides.length + (feedProvider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == feedProvider.rides.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: RideCard(
                      ride: feedProvider.rides[index],
                      onTap: () {},
                    ),
                  );
                },
              ),
      ),
    );
  }
}
