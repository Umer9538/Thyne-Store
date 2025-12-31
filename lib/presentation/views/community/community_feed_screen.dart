import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/community_provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../widgets/community_post_card.dart';
import '../../../data/models/community.dart';
import '../../../utils/theme.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  String _sortBy = 'latest';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
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

  Future<void> _loadFeed() async {
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    await provider.fetchFeed(refresh: true);
  }

  Future<void> _onRefresh() async {
    await _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          // Create Post button in app bar
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Create Post',
              onPressed: _navigateToCreatePost,
            ),
          // Sort menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              final provider = Provider.of<CommunityProvider>(context, listen: false);
              provider.changeSortOrder(value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'latest',
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: _sortBy == 'latest' ? AppTheme.primaryGold : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Latest'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'popular',
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 20,
                      color: _sortBy == 'popular' ? AppTheme.primaryGold : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Popular'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'trending',
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 20,
                      color: _sortBy == 'trending' ? AppTheme.primaryGold : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Trending'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load community feed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error ?? 'Unknown error',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFeed,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share something!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToCreatePost(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Post'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: (isLoggedIn ? 1 : 0) + provider.posts.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Show "Create Post" card at top if logged in
                if (isLoggedIn && index == 0) {
                  return _buildCreatePostCard();
                }

                // Adjust index for posts
                final postIndex = isLoggedIn ? index - 1 : index;

                if (postIndex >= provider.posts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final post = provider.posts[postIndex];
                return _PostCard(
                  post: post,
                  isLoggedIn: isLoggedIn,
                  onShowLoginPrompt: _showLoginPrompt,
                  onNavigateToDetail: _navigateToPostDetail,
                  onShare: _sharePost,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: isLoggedIn
          ? FloatingActionButton(
              onPressed: _navigateToCreatePost,
              backgroundColor: AppTheme.primaryGold,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    ).then((created) {
      if (created == true) {
        _loadFeed();
      }
    });
  }

  void _navigateToPostDetail(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: postId),
      ),
    );
  }

  void _sharePost(post) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to interact with posts'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostCard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.user?.name ?? 'User';
    final userAvatar = authProvider.user?.profileImage;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _navigateToCreatePost,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                    ? NetworkImage(userAvatar)
                    : null,
                child: userAvatar == null || userAvatar.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // "What's on your mind?" text
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Share your jewelry style...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Camera icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppTheme.primaryGold,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stateful widget for individual post card with engagement
class _PostCard extends StatefulWidget {
  final CommunityPost post;
  final bool isLoggedIn;
  final VoidCallback onShowLoginPrompt;
  final Function(String) onNavigateToDetail;
  final Function(CommunityPost) onShare;

  const _PostCard({
    required this.post,
    required this.isLoggedIn,
    required this.onShowLoginPrompt,
    required this.onNavigateToDetail,
    required this.onShare,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _userLiked = false;
  String _userVoted = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEngagement();
  }

  Future<void> _loadEngagement() async {
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    final engagement = await provider.getPostEngagement(widget.post.id);

    if (mounted) {
      setState(() {
        _userLiked = engagement?.userLiked ?? false;
        _userVoted = engagement?.userVoted ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLike() async {
    if (!widget.isLoggedIn) {
      widget.onShowLoginPrompt();
      return;
    }

    // Optimistic update
    setState(() {
      _userLiked = !_userLiked;
    });

    final provider = Provider.of<CommunityProvider>(context, listen: false);
    await provider.toggleLike(widget.post.id);

    // Reload to get accurate state
    await _loadEngagement();
  }

  Future<void> _handleVote(String voteType) async {
    if (!widget.isLoggedIn) {
      widget.onShowLoginPrompt();
      return;
    }

    // Optimistic update
    setState(() {
      if (_userVoted == voteType) {
        _userVoted = '';
      } else {
        _userVoted = voteType;
      }
    });

    final provider = Provider.of<CommunityProvider>(context, listen: false);
    await provider.votePost(widget.post.id, voteType);

    // Reload to get accurate state
    await _loadEngagement();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return CommunityPostCard(
      post: widget.post,
      userLiked: _userLiked,
      userVoted: _userVoted,
      onLike: _handleLike,
      onVote: _handleVote,
      onComment: () => widget.onNavigateToDetail(widget.post.id),
      onShare: () => widget.onShare(widget.post),
      onTap: () => widget.onNavigateToDetail(widget.post.id),
    );
  }
}
