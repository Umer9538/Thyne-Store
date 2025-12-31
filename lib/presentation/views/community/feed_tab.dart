import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../viewmodels/community_provider.dart';
import '../viewmodels/auth_provider.dart';
import '../../data/models/community.dart';
import '../../data/models/product.dart';
import '../../data/services/api_service.dart';
import '../product/product_detail_screen.dart';
import 'create_post_screen.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, int> _currentImageIndices = {};
  final Map<String, PageController> _pageControllers = {};

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
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoading) {
        provider.loadMore();
      }
    }
  }

  Future<void> _loadFeed() async {
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    await provider.fetchFeed(refresh: true);
  }

  PageController _getPageController(String postId) {
    if (!_pageControllers.containsKey(postId)) {
      _pageControllers[postId] = PageController();
    }
    return _pageControllers[postId]!;
  }

  int _getCurrentImageIndex(String postId) {
    return _currentImageIndices[postId] ?? 0;
  }

  void _setCurrentImageIndex(String postId, int index) {
    setState(() {
      _currentImageIndices[postId] = index;
    });
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

        if (provider.error != null && provider.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load feed',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadFeed,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.posts.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadFeed,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: provider.posts.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.posts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final post = provider.posts[index];
              return _buildPostCard(post, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share something!',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreatePost(),
            icon: const Icon(Icons.add),
            label: const Text('Create Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D1F1F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreatePost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to create a post'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
    if (result == true) {
      _loadFeed();
    }
  }

  Widget _buildPostCard(CommunityPost post, CommunityProvider provider) {
    final hasLiked = provider.hasLikedPost(post.id);
    final hasSaved = provider.hasSavedPost(post.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Image with Carousel (only if images exist)
          if (post.images.isNotEmpty) _buildImageCarousel(post),

          // Action buttons (Like, Comment, Share, Bookmark)
          _buildActionButtons(post, provider, hasLiked, hasSaved),

          // Likes count
          _buildLikesCount(post),

          // View comments (show above caption if there are comments)
          if (post.commentCount > 0) _buildViewComments(post),

          // Caption with username
          if (post.content.isNotEmpty) _buildCaption(post),

          // Tagged Products (from direct tagging or orders)
          if (post.hasTaggedItem)
            _buildTaggedProducts(post),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(CommunityPost post) {
    final pageController = _getPageController(post.id);
    final currentIndex = _getCurrentImageIndex(post.id);

    return Stack(
      children: [
        // Image
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: pageController,
            itemCount: post.images.length,
            onPageChanged: (index) {
              _setCurrentImageIndex(post.id, index);
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: post.images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image, size: 64, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),

        // Left Arrow
        if (post.images.length > 1 && currentIndex > 0)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

        // Right Arrow
        if (post.images.length > 1 && currentIndex < post.images.length - 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

        // Page indicators (dots)
        if (post.images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                post.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == currentIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(
      CommunityPost post, CommunityProvider provider, bool hasLiked, bool hasSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // Like button
          GestureDetector(
            onTap: () => _handleLike(post.id, provider),
            child: Icon(
              hasLiked ? Icons.favorite : Icons.favorite_border,
              color: hasLiked ? Colors.red : Colors.black,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Comment button
          GestureDetector(
            onTap: () => _showComments(post),
            child: const Icon(
              Icons.mode_comment_outlined,
              size: 26,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 16),

          // Share button
          GestureDetector(
            onTap: () => _sharePost(post),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(3.14159), // Mirror horizontally
              child: const Icon(
                Icons.reply,
                size: 26,
                color: Colors.black,
              ),
            ),
          ),

          const Spacer(),

          // Bookmark button
          GestureDetector(
            onTap: () => _handleSave(post.id, provider),
            child: Icon(
              hasSaved ? Icons.bookmark : Icons.bookmark_border,
              size: 28,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesCount(CommunityPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '${_formatNumber(post.likeCount)} likes',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}K';
    }
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildCaption(CommunityPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: '${post.userName} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: post.content),
            // Tags
            if (post.tags.isNotEmpty) ...[
              const TextSpan(text: ' '),
              ...post.tags.map((tag) => TextSpan(
                    text: '#$tag ',
                    style: const TextStyle(color: Color(0xFF3D1F1F)),
                  )),
            ],
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildViewComments(CommunityPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => _showComments(post),
        child: Text(
          'View all ${post.commentCount} comments',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTaggedProducts(CommunityPost post) {
    // Get all tagged products (from direct tagging or order)
    final products = post.allTaggedProducts;
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                post.tagSource == PostTagSource.order
                    ? 'Products from Order'
                    : 'Tagged Products',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              if (post.order != null) ...[
                const Spacer(),
                Text(
                  '#${post.order!.orderNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Product list
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () => _navigateToProductWithCustomization(product),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      // Product image with customization badge
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: product.customization != null &&
                                        product.customization!.hasCustomizations
                                    ? const Color(0xFF3D1F1F)
                                    : Colors.grey.shade300,
                                width: product.customization != null &&
                                        product.customization!.hasCustomizations
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: ClipOval(
                              child: product.imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: product.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Container(color: Colors.grey[200]),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.image, size: 24),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.shopping_bag, size: 24),
                                    ),
                            ),
                          ),
                          // Customization indicator
                          if (product.customization != null &&
                              product.customization!.hasCustomizations)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3D1F1F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.tune,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Product name
                      Text(
                        product.name,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      // Show customization summary if available
                      if (product.customization != null &&
                          product.customization!.hasCustomizations)
                        Text(
                          product.customization!.summary,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToProductWithCustomization(ProductTag productTag) async {
    // Build customization arguments to pass to the product detail screen
    final Map<String, dynamic> customizationArgs = {};

    if (productTag.customization != null && productTag.customization!.hasCustomizations) {
      final customization = productTag.customization!;
      if (customization.selectedMetal != null) {
        customizationArgs['selectedMetal'] = customization.selectedMetal;
      }
      if (customization.selectedPlating != null) {
        customizationArgs['selectedPlating'] = customization.selectedPlating;
      }
      if (customization.stoneColors != null) {
        customizationArgs['stoneColors'] = customization.stoneColors;
      }
      if (customization.selectedSize != null) {
        customizationArgs['selectedSize'] = customization.selectedSize;
      }
      if (customization.engravingText != null) {
        customizationArgs['engravingText'] = customization.engravingText;
      }
      if (customization.thickness != null) {
        customizationArgs['thickness'] = customization.thickness;
      }
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      // Fetch the full product details
      final response = await ApiService.getProduct(productId: productTag.id);
      if (mounted) Navigator.pop(context); // Close loading dialog

      if (response['success'] == true && response['data'] != null) {
        final product = Product.fromJson(response['data']);
        if (!mounted) return;

        // Navigate to product detail with customization intent
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: product,
              customizationIntent: customizationArgs.isNotEmpty ? customizationArgs : null,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load product details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLike(String postId, CommunityProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to like posts'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await provider.toggleLike(postId);
  }

  Future<void> _handleSave(String postId, CommunityProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to save posts'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await provider.toggleSave(postId);
  }

  void _showComments(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(post: post),
    );
  }

  void _sharePost(CommunityPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }
}

// Comments Bottom Sheet
class _CommentsSheet extends StatefulWidget {
  final CommunityPost post;

  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<PostComment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      final comments = await provider.getPostComments(widget.post.id);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to comment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      await provider.addComment(widget.post.id, content);
      _commentController.clear();
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Text(
              'Comments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const Divider(),

            // Comments list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? Center(
                          child: Text(
                            'No comments yet',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _buildCommentItem(comment);
                          },
                        ),
            ),

            // Comment input
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF3D1F1F)),
                    onPressed: _submitComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(PostComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            backgroundImage: comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                ? CachedNetworkImageProvider(comment.userAvatar!)
                : null,
            child: comment.userAvatar == null || comment.userAvatar!.isEmpty
                ? Text(
                    comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                        text: '${comment.userName} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: comment.content),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(comment.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
