import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

// Import existing providers and models
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/community.dart';
import '../../theme/thyne_theme.dart';

class CommunitySectionNew extends StatefulWidget {
  const CommunitySectionNew({Key? key}) : super(key: key);

  @override
  State<CommunitySectionNew> createState() => _CommunitySectionNewState();
}

class _CommunitySectionNewState extends State<CommunitySectionNew>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0; // 0: Verse, 1: Spotlight, 2: Profile

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index;
        });
      }
    });

    // Load community data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      provider.fetchFeed();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVerseTab(),
              _buildSpotlightTab(),
              _buildProfileTab(),
            ],
          ),
        ),
      ],
    );
  }

  // Verse Tab - Main Feed
  Widget _buildVerseTab() {
    final communityProvider = Provider.of<CommunityProvider>(context);

    if (communityProvider.isLoading && communityProvider.posts.isEmpty) {
      return _buildShimmerFeed();
    }

    if (communityProvider.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_2,
              size: 64,
              color: ThyneTheme.mutedForeground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThyneTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share something!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThyneTheme.mutedForeground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await communityProvider.fetchFeed();
      },
      color: ThyneTheme.communityRuby,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: communityProvider.posts.length + 1,
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index == communityProvider.posts.length) {
            if (communityProvider.hasMore && communityProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const SizedBox(height: 100);
          }

          // Load more when reaching the end
          if (index == communityProvider.posts.length - 2 &&
              communityProvider.hasMore &&
              !communityProvider.isLoading) {
            communityProvider.loadMore();
          }

          final post = communityProvider.posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  // Spotlight Tab - Featured Content
  Widget _buildSpotlightTab() {
    final communityProvider = Provider.of<CommunityProvider>(context);

    // Filter featured/spotlight posts
    final spotlightPosts = communityProvider.posts
        .where((post) => post.isFeatured || post.isPinned)
        .toList();

    if (spotlightPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.star,
              size: 64,
              color: ThyneTheme.mutedForeground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No spotlight posts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThyneTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Featured content will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThyneTheme.mutedForeground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: spotlightPosts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(spotlightPosts[index], isSpotlight: true);
      },
    );
  }

  // Profile Tab - User's Posts
  Widget _buildProfileTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final communityProvider = Provider.of<CommunityProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_circle,
              size: 64,
              color: ThyneTheme.mutedForeground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to view your profile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThyneTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThyneTheme.communityRuby,
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }

    // Filter user's posts
    final userPosts = communityProvider.posts
        .where((post) => post.userId == authProvider.user?.id)
        .toList();

    return CustomScrollView(
      slivers: [
        // Profile Header
        SliverToBoxAdapter(
          child: _buildProfileHeader(authProvider, userPosts.length),
        ),

        // User's Posts Grid
        if (userPosts.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = userPosts[index];
                  return _buildPostGridItem(post);
                },
                childCount: userPosts.length,
              ),
            ),
          )
        else
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No posts yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ThyneTheme.mutedForeground,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider, int postCount) {
    final user = authProvider.user!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThyneTheme.cardBackground,
        border: Border(
          bottom: BorderSide(color: ThyneTheme.border),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ThyneTheme.communityRuby,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: user.profileImage != null
                  ? CachedNetworkImage(
                      imageUrl: user.profileImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: ThyneTheme.secondary,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: ThyneTheme.secondary,
                        child: Icon(
                          CupertinoIcons.person,
                          size: 40,
                          color: ThyneTheme.mutedForeground,
                        ),
                      ),
                    )
                  : Container(
                      color: ThyneTheme.secondary,
                      child: Icon(
                        CupertinoIcons.person,
                        size: 40,
                        color: ThyneTheme.mutedForeground,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThyneTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('Posts', postCount.toString()),
              const SizedBox(width: 32),
              _buildStatItem('Followers', '0'),
              const SizedBox(width: 32),
              _buildStatItem('Following', '0'),
            ],
          ),
          const SizedBox(height: 16),

          // Edit Profile Button
          OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: ThyneTheme.communityRuby,
              side: BorderSide(color: ThyneTheme.communityRuby),
            ),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ThyneTheme.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(CommunityPost post, {bool isSpotlight = false}) {
    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
    final engagement = communityProvider.getEngagement(post.id);
    final hasLiked = communityProvider.hasLikedPost(post.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ThyneTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpotlight
              ? ThyneTheme.communityRuby.withOpacity(0.3)
              : ThyneTheme.border,
          width: isSpotlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ThyneTheme.communityRuby.withOpacity(0.3),
                    ),
                  ),
                  child: ClipOval(
                    child: post.userAvatar != null
                        ? CachedNetworkImage(
                            imageUrl: post.userAvatar!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: ThyneTheme.secondary,
                            child: Icon(
                              CupertinoIcons.person,
                              size: 20,
                              color: ThyneTheme.mutedForeground,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.userName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (post.isAdminPost) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ThyneTheme.communityRuby,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThyneTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu button
                IconButton(
                  onPressed: () {
                    // Show options menu
                  },
                  icon: Icon(
                    Icons.more_horiz,
                    color: ThyneTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          // Images
          if (post.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: post.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: post.images.length == 1 ? null : 200,
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: post.images[index],
                        fit: BoxFit.cover,
                        width: post.images.length == 1
                            ? MediaQuery.of(context).size.width - 48
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Tags
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ThyneTheme.communityRuby.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: ThyneTheme.communityRuby,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Like button
                InkWell(
                  onTap: () async {
                    await communityProvider.likePost(post.id);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: hasLiked
                              ? Colors.red
                              : ThyneTheme.mutedForeground,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          engagement?.likeCount.toString() ?? '0',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                // Comment button
                InkWell(
                  onTap: () {
                    // Navigate to post detail for comments
                    Navigator.pushNamed(context, '/community/post/${post.id}');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble,
                          size: 20,
                          color: ThyneTheme.mutedForeground,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          engagement?.commentCount.toString() ?? '0',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                // Share button
                InkWell(
                  onTap: () {
                    // Share functionality
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Icon(
                      CupertinoIcons.share,
                      size: 20,
                      color: ThyneTheme.mutedForeground,
                    ),
                  ),
                ),

                const Spacer(),

                // Bookmark button
                InkWell(
                  onTap: () {
                    // Bookmark functionality
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      CupertinoIcons.bookmark,
                      size: 20,
                      color: ThyneTheme.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGridItem(CommunityPost post) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/community/post/${post.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThyneTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (post.images.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: post.images.first,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: ThyneTheme.secondary,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    post.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              // Overlay with engagement info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.likeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        CupertinoIcons.chat_bubble,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.commentCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerFeed() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}