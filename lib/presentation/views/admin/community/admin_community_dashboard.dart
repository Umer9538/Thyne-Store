import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../viewmodels/community_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../../data/models/community.dart';
import '../../../../utils/theme.dart';
import 'community_analytics_screen.dart';
import 'community_moderation_screen.dart';

class AdminCommunityDashboard extends StatefulWidget {
  const AdminCommunityDashboard({super.key});

  @override
  State<AdminCommunityDashboard> createState() => _AdminCommunityDashboardState();
}

class _AdminCommunityDashboardState extends State<AdminCommunityDashboard> {
  final ScrollController _scrollController = ScrollController();
  String _filter = 'all'; // all, flagged, featured, pinned
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        provider.fetchFeed();
      }
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    await Future.wait([
      provider.fetchFeed(refresh: true),
      provider.fetchModerationStats(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Management'),
        actions: [
          Consumer<CommunityProvider>(
            builder: (context, provider, _) {
              final pendingCount = provider.moderationStats?.pending ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.pending_actions),
                    tooltip: 'Post Moderation',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommunityModerationScreen(),
                        ),
                      );
                    },
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          pendingCount > 99 ? '99+' : pendingCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityAnalyticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          _buildFilterTabs(),

          // Stats cards
          _buildStatsCards(),

          const Divider(height: 1),

          // Posts list
          Expanded(
            child: Consumer<CommunityProvider>(
              builder: (context, provider, child) {
                if (_isLoading && provider.posts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.posts.isEmpty) {
                  return const Center(
                    child: Text('No posts found'),
                  );
                }

                // Filter posts based on selected filter
                List<CommunityPost> filteredPosts = provider.posts;
                if (_filter == 'featured') {
                  filteredPosts = provider.posts.where((p) => p.isFeatured).toList();
                } else if (_filter == 'pinned') {
                  filteredPosts = provider.posts.where((p) => p.isPinned).toList();
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPosts.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filteredPosts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final post = filteredPosts[index];
                      return _buildPostCard(post, provider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All Posts', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Featured', 'featured'),
            const SizedBox(width: 8),
            _buildFilterChip('Pinned', 'pinned'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      selectedColor: AppTheme.primaryGold.withOpacity(0.3),
      checkmarkColor: AppTheme.primaryGold,
    );
  }

  Widget _buildStatsCards() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        final totalPosts = provider.posts.length;
        final featuredCount = provider.posts.where((p) => p.isFeatured).length;
        final pinnedCount = provider.posts.where((p) => p.isPinned).length;
        final totalLikes = provider.posts.fold<int>(0, (sum, p) => sum + p.likeCount);

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildStatCard('Total Posts', totalPosts.toString(), Icons.article)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Featured', featuredCount.toString(), Icons.star)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Pinned', pinnedCount.toString(), Icons.push_pin)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Total Likes', totalLikes.toString(), Icons.favorite)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPostImages(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: images.first,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      );
    }

    // Multiple images - show grid
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < images.length - 1 ? 8 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: images[index],
                width: 180,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 180,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 180,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaggedProducts(List<ProductTag> products) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, size: 16, color: AppTheme.primaryGold),
              const SizedBox(width: 6),
              const Text(
                'Tagged Products',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 160,
                  margin: EdgeInsets.only(right: index < products.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post, CommunityProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                  backgroundImage: post.userAvatar != null && post.userAvatar!.isNotEmpty
                      ? CachedNetworkImageProvider(post.userAvatar!)
                      : null,
                  child: post.userAvatar == null || post.userAvatar!.isEmpty
                      ? Text(
                          post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        timeago.format(post.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badges
                if (post.isPinned)
                  const Icon(Icons.push_pin, size: 16, color: AppTheme.primaryGold),
                if (post.isFeatured)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Featured',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              post.content,
              style: const TextStyle(fontSize: 14),
            ),

            // Post Images
            if (post.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPostImages(post.images),
            ],

            // Tagged Products
            if (post.products != null && post.products!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTaggedProducts(post.products!),
            ],

            // Tags
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: post.tags.take(3).map((tag) => Chip(
                  label: Text('#$tag'),
                  labelStyle: const TextStyle(fontSize: 10),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppTheme.primaryGold.withOpacity(0.1),
                )).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Stats
            Row(
              children: [
                _buildStatChip(Icons.favorite, post.likeCount.toString(), Colors.red),
                const SizedBox(width: 12),
                _buildStatChip(
                  post.voteCount > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  post.voteCount.abs().toString(),
                  post.voteCount > 0 ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                _buildStatChip(Icons.comment, post.commentCount.toString(), Colors.blue),
              ],
            ),

            const Divider(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: post.isFeatured ? Icons.star : Icons.star_border,
                  label: post.isFeatured ? 'Unfeature' : 'Feature',
                  color: post.isFeatured ? AppTheme.primaryGold : Colors.grey,
                  onTap: () => _toggleFeature(post, provider),
                ),
                _buildActionButton(
                  icon: post.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  label: post.isPinned ? 'Unpin' : 'Pin',
                  color: post.isPinned ? AppTheme.primaryGold : Colors.grey,
                  onTap: () => _togglePin(post, provider),
                ),
                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppTheme.errorRed,
                  onTap: () => _confirmDelete(post, provider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFeature(CommunityPost post, CommunityProvider provider) async {
    final success = await provider.toggleFeaturePost(post.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (post.isFeatured ? 'Post unfeatured' : 'Post featured')
                : 'Failed to update post',
          ),
        ),
      );
      if (success) _loadPosts();
    }
  }

  Future<void> _togglePin(CommunityPost post, CommunityProvider provider) async {
    final success = await provider.togglePinPost(post.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (post.isPinned ? 'Post unpinned' : 'Post pinned')
                : 'Failed to update post',
          ),
        ),
      );
      if (success) _loadPosts();
    }
  }

  Future<void> _confirmDelete(CommunityPost post, CommunityProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.deletePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Post deleted' : 'Failed to delete post'),
          ),
        );
        if (success) _loadPosts();
      }
    }
  }
}
