import 'package:flutter/foundation.dart';
import '../models/community.dart';
import '../services/api_service.dart';

class CommunityProvider with ChangeNotifier {
  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String _sortBy = 'latest'; // latest, popular, trending

  // Engagement cache
  final Map<String, PostEngagement> _engagementCache = {};
  final Map<String, List<PostComment>> _commentsCache = {};

  // Track liked posts
  final Set<String> _likedPosts = {};

  // Track saved/bookmarked posts
  final Set<String> _savedPosts = {};

  List<CommunityPost> get posts => _posts;
  Set<String> get savedPosts => _savedPosts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String get sortBy => _sortBy;
  bool get hasMore => _currentPage < _totalPages;

  // Load more posts (pagination)
  Future<void> loadMore() async {
    if (!hasMore || _isLoading) return;
    await fetchFeed();
  }

  // Get cached engagement for a post
  PostEngagement? getEngagement(String postId) {
    return _engagementCache[postId];
  }

  // Check if user has liked a post
  bool hasLikedPost(String postId) {
    return _likedPosts.contains(postId);
  }

  // Check if user has saved a post
  bool hasSavedPost(String postId) {
    return _savedPosts.contains(postId);
  }

  // Toggle save/bookmark a post (local only for now)
  Future<void> toggleSave(String postId) async {
    if (_savedPosts.contains(postId)) {
      _savedPosts.remove(postId);
    } else {
      _savedPosts.add(postId);
    }
    notifyListeners();
  }

  // Alias for toggleLike for consistency
  Future<void> likePost(String postId) => toggleLike(postId);

  // Fetch community feed
  Future<void> fetchFeed({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _posts = [];
    }

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getCommunityFeed(
        page: _currentPage,
        limit: 20,
        sortBy: _sortBy,
      );

      if (response['success'] == true && response['data'] != null) {
        final feedData = CommunityFeedResponse.fromJson(response['data']);

        if (refresh) {
          _posts = feedData.posts;
        } else {
          _posts.addAll(feedData.posts);
        }

        _totalPages = feedData.totalPages;
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change sort order
  Future<void> changeSortOrder(String newSortBy) async {
    if (_sortBy == newSortBy) return;
    _sortBy = newSortBy;
    await fetchFeed(refresh: true);
  }

  // Create a new post
  Future<bool> createPost({
    required String content,
    List<String>? images,
    List<String>? videos,
    List<String>? tags,
    List<ProductTag>? products,
    OrderTag? order,
    PostTagSource? tagSource,
  }) async {
    try {
      debugPrint('Creating post with content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
      debugPrint('Images: ${images?.length ?? 0}, Videos: ${videos?.length ?? 0}, Tags: ${tags?.length ?? 0}');
      debugPrint('Products: ${products?.length ?? 0}, Order: ${order != null ? 'Yes' : 'No'}');

      final response = await ApiService.createCommunityPost(
        content: content,
        images: images,
        videos: videos,
        tags: tags,
        products: products?.map((p) => p.toJson()).toList(),
        order: order?.toJson(),
        tagSource: tagSource,
      );

      debugPrint('Create post response: $response');

      if (response['success'] == true) {
        // Refresh feed to show new post
        await fetchFeed(refresh: true);
        return true;
      }

      // Set error from response if available
      _error = response['error']?.toString() ?? 'Failed to create post';
      debugPrint('Create post failed: $_error');
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Create post error: $e');
      notifyListeners();
      return false;
    }
  }

  // Like/Unlike a post
  Future<void> toggleLike(String postId) async {
    try {
      final response = await ApiService.likePost(postId);

      if (response['success'] == true) {
        final liked = response['liked'] ?? false;

        // Update liked posts set
        if (liked) {
          _likedPosts.add(postId);
        } else {
          _likedPosts.remove(postId);
        }

        // Update post in list
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = CommunityPost(
            id: post.id,
            userId: post.userId,
            userName: post.userName,
            userAvatar: post.userAvatar,
            content: post.content,
            images: post.images,
            videos: post.videos,
            likeCount: liked ? post.likeCount + 1 : post.likeCount - 1,
            voteCount: post.voteCount,
            commentCount: post.commentCount,
            tags: post.tags,
            isAdminPost: post.isAdminPost,
            isFeatured: post.isFeatured,
            isPinned: post.isPinned,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
          );

          // Update engagement cache
          if (_engagementCache.containsKey(postId)) {
            final engagement = _engagementCache[postId]!;
            _engagementCache[postId] = PostEngagement(
              postId: postId,
              likeCount: liked ? engagement.likeCount + 1 : engagement.likeCount - 1,
              voteCount: engagement.voteCount,
              commentCount: engagement.commentCount,
              userLiked: liked,
              userVoted: engagement.userVoted,
            );
          }

          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Vote on a post
  Future<void> votePost(String postId, String voteType) async {
    try {
      final response = await ApiService.votePost(postId, voteType);

      if (response['success'] == true) {
        // Refresh engagement for this post
        await getPostEngagement(postId, forceRefresh: true);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get post engagement
  Future<PostEngagement?> getPostEngagement(String postId, {bool forceRefresh = false}) async {
    if (_engagementCache.containsKey(postId) && !forceRefresh) {
      return _engagementCache[postId];
    }

    try {
      final response = await ApiService.getPostEngagement(postId);

      if (response['success'] == true && response['data'] != null) {
        final engagement = PostEngagement.fromJson(response['data']);
        _engagementCache[postId] = engagement;
        notifyListeners();
        return engagement;
      }
    } catch (e) {
      _error = e.toString();
    }
    return null;
  }

  // Get post comments
  Future<List<PostComment>> getPostComments(String postId, {bool forceRefresh = false}) async {
    if (_commentsCache.containsKey(postId) && !forceRefresh) {
      return _commentsCache[postId]!;
    }

    try {
      final response = await ApiService.getPostComments(postId);

      if (response['success'] == true && response['data'] != null) {
        final comments = (response['data']['comments'] as List<dynamic>?)
                ?.map((comment) => PostComment.fromJson(comment as Map<String, dynamic>))
                .toList() ??
            [];
        _commentsCache[postId] = comments;
        notifyListeners();
        return comments;
      }
    } catch (e) {
      _error = e.toString();
    }
    return [];
  }

  // Add a comment
  Future<bool> addComment(String postId, String content) async {
    try {
      final response = await ApiService.createComment(postId, content);

      if (response['success'] == true) {
        // Refresh comments for this post
        await getPostComments(postId, forceRefresh: true);

        // Update comment count in post
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = CommunityPost(
            id: post.id,
            userId: post.userId,
            userName: post.userName,
            userAvatar: post.userAvatar,
            content: post.content,
            images: post.images,
            videos: post.videos,
            likeCount: post.likeCount,
            voteCount: post.voteCount,
            commentCount: post.commentCount + 1,
            tags: post.tags,
            isAdminPost: post.isAdminPost,
            isFeatured: post.isFeatured,
            isPinned: post.isPinned,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
          );
          notifyListeners();
        }

        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      final response = await ApiService.deletePost(postId);

      if (response['success'] == true) {
        _posts.removeWhere((p) => p.id == postId);
        _engagementCache.remove(postId);
        _commentsCache.remove(postId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle feature status (admin only)
  Future<bool> toggleFeaturePost(String postId) async {
    try {
      final response = await ApiService.toggleFeaturePost(postId);

      if (response['success'] == true) {
        // Update post in list
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = CommunityPost(
            id: post.id,
            userId: post.userId,
            userName: post.userName,
            userAvatar: post.userAvatar,
            content: post.content,
            images: post.images,
            videos: post.videos,
            likeCount: post.likeCount,
            voteCount: post.voteCount,
            commentCount: post.commentCount,
            tags: post.tags,
            isAdminPost: post.isAdminPost,
            isFeatured: !post.isFeatured,
            isPinned: post.isPinned,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle pin status (admin only)
  Future<bool> togglePinPost(String postId) async {
    try {
      final response = await ApiService.togglePinPost(postId);

      if (response['success'] == true) {
        // Update post in list
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = CommunityPost(
            id: post.id,
            userId: post.userId,
            userName: post.userName,
            userAvatar: post.userAvatar,
            content: post.content,
            images: post.images,
            videos: post.videos,
            likeCount: post.likeCount,
            voteCount: post.voteCount,
            commentCount: post.commentCount,
            tags: post.tags,
            isAdminPost: post.isAdminPost,
            isFeatured: post.isFeatured,
            isPinned: !post.isPinned,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ==================== Admin Moderation Methods ====================

  List<CommunityPost> _pendingPosts = [];
  List<CommunityPost> _rejectedPosts = [];
  ModerationStats? _moderationStats;
  bool _isModerationLoading = false;
  int _pendingPage = 1;
  int _pendingTotalPages = 1;
  int _rejectedPage = 1;
  int _rejectedTotalPages = 1;

  List<CommunityPost> get pendingPosts => _pendingPosts;
  List<CommunityPost> get rejectedPosts => _rejectedPosts;
  ModerationStats? get moderationStats => _moderationStats;
  bool get isModerationLoading => _isModerationLoading;
  bool get hasMorePending => _pendingPage < _pendingTotalPages;
  bool get hasMoreRejected => _rejectedPage < _rejectedTotalPages;

  // Fetch pending posts for moderation
  Future<void> fetchPendingPosts({bool refresh = false}) async {
    if (refresh) {
      _pendingPage = 1;
      _pendingPosts = [];
    }

    if (_isModerationLoading) return;

    _isModerationLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getPendingPosts(
        page: _pendingPage,
        limit: 20,
      );

      if (response['success'] == true && response['data'] != null) {
        final feedData = CommunityFeedResponse.fromJson(response['data']);

        if (refresh) {
          _pendingPosts = feedData.posts;
        } else {
          _pendingPosts.addAll(feedData.posts);
        }

        _pendingTotalPages = feedData.totalPages;
        _pendingPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isModerationLoading = false;
      notifyListeners();
    }
  }

  // Fetch rejected posts
  Future<void> fetchRejectedPosts({bool refresh = false}) async {
    if (refresh) {
      _rejectedPage = 1;
      _rejectedPosts = [];
    }

    if (_isModerationLoading) return;

    _isModerationLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getRejectedPosts(
        page: _rejectedPage,
        limit: 20,
      );

      if (response['success'] == true && response['data'] != null) {
        final feedData = CommunityFeedResponse.fromJson(response['data']);

        if (refresh) {
          _rejectedPosts = feedData.posts;
        } else {
          _rejectedPosts.addAll(feedData.posts);
        }

        _rejectedTotalPages = feedData.totalPages;
        _rejectedPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isModerationLoading = false;
      notifyListeners();
    }
  }

  // Fetch moderation statistics
  Future<void> fetchModerationStats() async {
    try {
      final response = await ApiService.getModerationStats();

      if (response['success'] == true && response['data'] != null) {
        _moderationStats = ModerationStats.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Approve a post
  Future<bool> approvePost(String postId) async {
    try {
      final response = await ApiService.moderatePost(
        postId: postId,
        action: 'approve',
      );

      if (response['success'] == true) {
        // Remove from pending list
        _pendingPosts.removeWhere((p) => p.id == postId);
        // Refresh stats
        await fetchModerationStats();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reject a post
  Future<bool> rejectPost(String postId, String reason) async {
    try {
      final response = await ApiService.moderatePost(
        postId: postId,
        action: 'reject',
        reason: reason,
      );

      if (response['success'] == true) {
        // Remove from pending list
        _pendingPosts.removeWhere((p) => p.id == postId);
        // Refresh stats
        await fetchModerationStats();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Load more pending posts
  Future<void> loadMorePending() async {
    if (!hasMorePending || _isModerationLoading) return;
    await fetchPendingPosts();
  }

  // Load more rejected posts
  Future<void> loadMoreRejected() async {
    if (!hasMoreRejected || _isModerationLoading) return;
    await fetchRejectedPosts();
  }
}
