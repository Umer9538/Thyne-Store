import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../viewmodels/community_provider.dart';
import '../viewmodels/auth_provider.dart';
import '../../data/models/community.dart';

class FeedTabFigma extends StatefulWidget {
  const FeedTabFigma({super.key});

  @override
  State<FeedTabFigma> createState() => _FeedTabFigmaState();
}

class _FeedTabFigmaState extends State<FeedTabFigma> {
  final ScrollController _scrollController = ScrollController();
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
    });
  }

  Future<void> _loadFeed() async {
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    await provider.fetchFeed(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.posts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final posts = provider.posts.isNotEmpty
            ? provider.posts
            : _getMockPosts().map((p) => CommunityPost(
                id: p['id'],
                userId: p['userId'],
                userName: p['username'],
                userAvatar: p['userAvatar'],
                content: p['caption'],
                images: List<String>.from(p['images'] ?? []),
                likeCount: p['likes'] ?? 0,
                commentCount: p['comments'] ?? 0,
                voteCount: 0,
                tags: List<String>.from(p['tags'] ?? []),
                createdAt: DateTime.now(),
                videos: [],
              )).toList();

        return RefreshIndicator(
          onRefresh: _loadFeed,
          color: const Color(0xFF1A1A1A),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _buildPostCard(posts[index], provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildPostCard(CommunityPost post, CommunityProvider provider) {
    final currentIndex = ValueNotifier<int>(0);

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Images Carousel
          if (post.images.isNotEmpty) ...[
            Stack(
              children: [
                CarouselSlider(
                  carouselController: _carouselController,
                  options: CarouselOptions(
                    aspectRatio: 1.0,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: false,
                    onPageChanged: (index, reason) {
                      currentIndex.value = index;
                    },
                  ),
                  items: post.images.map((image) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                      ),
                      child: CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Carousel Navigation Arrows
                if (post.images.length > 1) ...[
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          padding: EdgeInsets.zero,
                          onPressed: () => _carouselController.previousPage(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          padding: EdgeInsets.zero,
                          onPressed: () => _carouselController.nextPage(),
                        ),
                      ),
                    ),
                  ),
                ],

                // Dots Indicator
                if (post.images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<int>(
                      valueListenable: currentIndex,
                      builder: (context, index, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            post.images.length,
                            (i) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],

          // Action Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Like Button
                GestureDetector(
                  onTap: () => provider.toggleLike(post.id),
                  child: Icon(
                    provider.hasLikedPost(post.id)
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    size: 28,
                    color: provider.hasLikedPost(post.id)
                        ? Colors.red
                        : Colors.black87,
                  ),
                ),
                const SizedBox(width: 20),

                // Comment Button
                GestureDetector(
                  onTap: () => _showCommentDialog(context, post.id, provider),
                  child: const Icon(
                    CupertinoIcons.chat_bubble,
                    size: 26,
                    color: Colors.black87,
                  ),
                ),

                const Spacer(),

                // Admin Actions Menu (if user is admin)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.user?.isAdmin == true) {
                      return PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 26,
                          color: Colors.black87,
                        ),
                        onSelected: (value) => _handleAdminAction(context, value, post.id, provider),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'feature',
                            child: Row(
                              children: [
                                Icon(
                                  post.isFeatured ? Icons.star : Icons.star_border,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(post.isFeatured ? 'Unfeature' : 'Feature'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'pin',
                            child: Row(
                              children: [
                                Icon(
                                  post.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(post.isPinned ? 'Unpin' : 'Pin'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Likes Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_formatNumber(post.likeCount)} likes',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Comments Count (if any)
          if (post.commentCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _showCommentDialog(context, post.id, provider),
                child: Text(
                  'View all ${_formatNumber(post.commentCount)} comments',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),

          if (post.commentCount > 0) const SizedBox(height: 8),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '${post.userName} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: post.content,
                  ),
                ],
              ),
            ),
          ),

          // Tags
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                children: post.tags.map((tag) {
                  return Text(
                    '#$tag',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0095F6),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Product Tags (if any)
          if (post.products != null && post.products!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildProductTags(post.products!),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProductTags(List<ProductTag> products) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_formatNumber(product.price.toInt())}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showCommentDialog(BuildContext context, String postId, CommunityProvider provider) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Comments List
              FutureBuilder<List<PostComment>>(
                future: provider.getPostComments(postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'No comments yet. Be the first to comment!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: comment.userAvatar != null
                                ? CachedNetworkImageProvider(comment.userAvatar!)
                                : null,
                            child: comment.userAvatar == null
                                ? Text(comment.userName.substring(0, 1).toUpperCase())
                                : null,
                          ),
                          title: Text(
                            comment.userName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(comment.content),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              const Divider(),

              // Comment Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(CupertinoIcons.paperplane_fill),
                    onPressed: () async {
                      final content = commentController.text.trim();
                      if (content.isNotEmpty) {
                        final success = await provider.addComment(postId, content);
                        if (success && context.mounted) {
                          commentController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Comment added!')),
                          );
                          // Refresh the comments
                          Navigator.pop(context);
                          _showCommentDialog(context, postId, provider);
                        }
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAdminAction(
    BuildContext context,
    String action,
    String postId,
    CommunityProvider provider,
  ) async {
    bool success = false;
    String message = '';

    switch (action) {
      case 'feature':
        success = await provider.toggleFeaturePost(postId);
        message = success ? 'Post featured status updated' : 'Failed to update feature status';
        break;
      case 'pin':
        success = await provider.togglePinPost(postId);
        message = success ? 'Post pin status updated' : 'Failed to update pin status';
        break;
      case 'delete':
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          success = await provider.deletePost(postId);
          message = success ? 'Post deleted successfully' : 'Failed to delete post';
        } else {
          return; // User cancelled
        }
        break;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getMockPosts() {
    return [
      {
        'id': '1',
        'userId': 'user1',
        'username': 'luxe.fashion',
        'userAvatar': 'https://i.pravatar.cc/150?img=1',
        'images': [
          'https://images.unsplash.com/photo-1620625515032-6ed0c1790c75',
          'https://images.unsplash.com/photo-1522273500616-6b4757e4c184',
        ],
        'caption': 'Elegance never goes out of style #luxury #fashion #ootd',
        'likes': 2847,
        'comments': 89,
        'tags': ['luxury', 'fashion', 'ootd'],
        'isLiked': false,
        'isSaved': false,
        'products': [
          {
            'id': 'p1',
            'name': 'Silk Gown',
            'price': 8999,
            'image': 'https://images.unsplash.com/photo-1594463750939-ebb28c3f7f75',
          },
          {
            'id': 'p2',
            'name': 'Watch',
            'price': 14999,
            'image': 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49',
          },
        ],
      },
      {
        'id': '2',
        'userId': 'user2',
        'username': 'jewelry.love',
        'userAvatar': 'https://i.pravatar.cc/150?img=2',
        'images': [
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338',
        ],
        'caption': 'New collection just dropped! ✨ Check out these stunning pieces',
        'likes': 1523,
        'comments': 67,
        'tags': ['jewelry', 'newcollection', 'sparkle'],
        'isLiked': true,
        'isSaved': false,
      },
    ];
  }
}