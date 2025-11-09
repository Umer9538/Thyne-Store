import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/community_provider.dart';
import '../../../models/community.dart';
import '../../../utils/theme.dart';

class CommunityAnalyticsScreen extends StatefulWidget {
  const CommunityAnalyticsScreen({super.key});

  @override
  State<CommunityAnalyticsScreen> createState() => _CommunityAnalyticsScreenState();
}

class _CommunityAnalyticsScreenState extends State<CommunityAnalyticsScreen> {
  String _timeRange = '7d'; // 7d, 30d, 90d, all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    await provider.fetchFeed(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Analytics'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (value) {
              setState(() {
                _timeRange = value;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7d', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30d', child: Text('Last 30 Days')),
              const PopupMenuItem(value: '90d', child: Text('Last 90 Days')),
              const PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
          ),
        ],
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadAnalytics,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Overview metrics
                _buildOverviewSection(provider.posts),
                const SizedBox(height: 24),

                // Engagement metrics
                _buildEngagementSection(provider.posts),
                const SizedBox(height: 24),

                // Top posts
                _buildTopPostsSection(provider.posts),
                const SizedBox(height: 24),

                // User activity
                _buildUserActivitySection(provider.posts),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewSection(List<CommunityPost> posts) {
    final totalPosts = posts.length;
    final totalLikes = posts.fold<int>(0, (sum, p) => sum + p.likeCount);
    final totalComments = posts.fold<int>(0, (sum, p) => sum + p.commentCount);
    final totalVotes = posts.fold<int>(0, (sum, p) => sum + p.voteCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Total Posts',
              totalPosts.toString(),
              Icons.article,
              Colors.blue,
            ),
            _buildMetricCard(
              'Total Likes',
              totalLikes.toString(),
              Icons.favorite,
              Colors.red,
            ),
            _buildMetricCard(
              'Total Comments',
              totalComments.toString(),
              Icons.comment,
              Colors.green,
            ),
            _buildMetricCard(
              'Net Votes',
              totalVotes.toString(),
              totalVotes > 0 ? Icons.arrow_upward : Icons.arrow_downward,
              totalVotes > 0 ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementSection(List<CommunityPost> posts) {
    if (posts.isEmpty) {
      return const SizedBox.shrink();
    }

    final avgLikes = posts.fold<int>(0, (sum, p) => sum + p.likeCount) / posts.length;
    final avgComments = posts.fold<int>(0, (sum, p) => sum + p.commentCount) / posts.length;
    final avgVotes = posts.fold<int>(0, (sum, p) => sum + p.voteCount) / posts.length;

    final postsWithImages = posts.where((p) => p.images.isNotEmpty).length;
    final postsWithVideos = posts.where((p) => p.videos.isNotEmpty).length;
    final featuredPosts = posts.where((p) => p.isFeatured).length;
    final pinnedPosts = posts.where((p) => p.isPinned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Engagement Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildEngagementRow('Avg. Likes per Post', avgLikes.toStringAsFixed(1)),
                const Divider(),
                _buildEngagementRow('Avg. Comments per Post', avgComments.toStringAsFixed(1)),
                const Divider(),
                _buildEngagementRow('Avg. Votes per Post', avgVotes.toStringAsFixed(1)),
                const Divider(),
                _buildEngagementRow('Posts with Images', '$postsWithImages (${(postsWithImages / posts.length * 100).toStringAsFixed(0)}%)'),
                const Divider(),
                _buildEngagementRow('Posts with Videos', '$postsWithVideos (${(postsWithVideos / posts.length * 100).toStringAsFixed(0)}%)'),
                const Divider(),
                _buildEngagementRow('Featured Posts', '$featuredPosts'),
                const Divider(),
                _buildEngagementRow('Pinned Posts', '$pinnedPosts'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPostsSection(List<CommunityPost> posts) {
    if (posts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get top 5 posts by like count
    final topPosts = List<CommunityPost>.from(posts)
      ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
    final top5 = topPosts.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Posts by Likes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...top5.asMap().entries.map((entry) {
          final index = entry.key;
          final post = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRankColor(index),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('by ${post.userName}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        post.likeCount.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.comment, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(post.commentCount.toString()),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUserActivitySection(List<CommunityPost> posts) {
    if (posts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Count posts per user
    final Map<String, int> userPostCounts = {};
    final Map<String, int> userLikeCounts = {};

    for (final post in posts) {
      userPostCounts[post.userName] = (userPostCounts[post.userName] ?? 0) + 1;
      userLikeCounts[post.userName] = (userLikeCounts[post.userName] ?? 0) + post.likeCount;
    }

    // Get top 5 users
    final topUsers = userPostCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5Users = topUsers.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Contributors',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...top5Users.asMap().entries.map((entry) {
          final index = entry.key;
          final userName = entry.value.key;
          final postCount = entry.value.value;
          final likeCount = userLikeCounts[userName] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRankColor(index),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(userName),
              subtitle: Text('$postCount posts'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        likeCount.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    'total likes',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.primaryGold;
    }
  }
}
