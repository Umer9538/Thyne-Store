import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/community_provider.dart';
import '../../../../data/models/community.dart';
import '../../../../utils/theme.dart';

class CommunityAnalyticsScreen extends StatefulWidget {
  const CommunityAnalyticsScreen({super.key});

  @override
  State<CommunityAnalyticsScreen> createState() => _CommunityAnalyticsScreenState();
}

class _CommunityAnalyticsScreenState extends State<CommunityAnalyticsScreen> {
  String _timeRange = '7d'; // 7d, 30d, 90d, all, custom
  DateTime? _customStartDate;
  DateTime? _customEndDate;

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

  // Filter posts based on selected date range
  List<CommunityPost> _filterPostsByDateRange(List<CommunityPost> posts) {
    if (posts.isEmpty) return posts;

    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_timeRange) {
      case '7d':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '90d':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          startDate = _customStartDate!;
          endDate = _customEndDate!.add(const Duration(days: 1)); // Include end date
        } else {
          return posts; // No filter if custom dates not set
        }
        break;
      case 'all':
      default:
        return posts; // Return all posts
    }

    return posts.where((post) {
      return post.createdAt.isAfter(startDate) && post.createdAt.isBefore(endDate);
    }).toList();
  }

  // Show date picker options dialog
  Future<void> _showDatePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Select Date Option',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_today, color: AppTheme.primaryGold),
              ),
              title: const Text('Select Single Date'),
              subtitle: const Text('View analytics for a specific day'),
              onTap: () {
                Navigator.pop(context);
                _showSingleDatePicker();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.date_range, color: AppTheme.primaryGold),
              ),
              title: const Text('Select Date Range'),
              subtitle: const Text('View analytics for a period'),
              onTap: () {
                Navigator.pop(context);
                _showDateRangePicker();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Show single date picker
  Future<void> _showSingleDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryGold,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked;
        _customEndDate = picked; // Same date for single day
        _timeRange = 'custom';
      });
    }
  }

  // Show date range picker dialog
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryGold,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _timeRange = 'custom';
      });
    }
  }

  // Get display text for current date range
  String _getDateRangeDisplayText() {
    switch (_timeRange) {
      case '7d':
        return 'Last 7 Days';
      case '30d':
        return 'Last 30 Days';
      case '90d':
        return 'Last 90 Days';
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          final dateFormat = DateFormat('MMM d, yyyy');
          // Check if it's a single day
          if (_customStartDate!.year == _customEndDate!.year &&
              _customStartDate!.month == _customEndDate!.month &&
              _customStartDate!.day == _customEndDate!.day) {
            return dateFormat.format(_customStartDate!);
          }
          return '${dateFormat.format(_customStartDate!)} - ${dateFormat.format(_customEndDate!)}';
        }
        return 'Custom Date';
      case 'all':
      default:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter posts by date range
          final filteredPosts = _filterPostsByDateRange(provider.posts);

          return RefreshIndicator(
            onRefresh: _loadAnalytics,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Date range selector
                _buildDateRangeSelector(),
                const SizedBox(height: 16),

                // Overview metrics
                _buildOverviewSection(filteredPosts),
                const SizedBox(height: 24),

                // Engagement metrics
                _buildEngagementSection(filteredPosts),
                const SizedBox(height: 24),

                // Top posts
                _buildTopPostsSection(filteredPosts),
                const SizedBox(height: 24),

                // User activity
                _buildUserActivitySection(filteredPosts),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: AppTheme.primaryGold),
                const SizedBox(width: 8),
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quick select buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDateChip('7d', 'Last 7 Days'),
                _buildDateChip('30d', 'Last 30 Days'),
                _buildDateChip('90d', 'Last 90 Days'),
                _buildDateChip('all', 'All Time'),
              ],
            ),
            const SizedBox(height: 12),
            // Custom date button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showDatePickerOptions,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _timeRange == 'custom' && _customStartDate != null
                      ? _getDateRangeDisplayText()
                      : 'Select Custom Date Range',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _timeRange == 'custom' ? Colors.white : AppTheme.primaryGold,
                  backgroundColor: _timeRange == 'custom' ? AppTheme.primaryGold : null,
                  side: BorderSide(color: AppTheme.primaryGold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // Show selected date range info
            if (_timeRange != 'custom' && _timeRange != 'all') ...[
              const SizedBox(height: 8),
              Text(
                'Showing: ${_getDateRangeDisplayText()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String value, String label) {
    final isSelected = _timeRange == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _timeRange = value;
          });
        }
      },
      selectedColor: AppTheme.primaryGold.withValues(alpha: 0.3),
      checkmarkColor: AppTheme.primaryGold,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGold : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          childAspectRatio: 1.4,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementSection(List<CommunityPost> posts) {
    if (posts.isEmpty) {
      return _buildEmptyState('No posts in selected date range');
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

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
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
              subtitle: Text('by ${post.userName} • ${DateFormat('MMM d').format(post.createdAt)}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          post.likeCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.comment, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          post.commentCount.toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          likeCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Text(
                      'total likes',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
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
