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

  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String get sortBy => _sortBy;
  bool get hasMore => _currentPage < _totalPages;

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
  }) async {
    try {
      final response = await ApiService.createCommunityPost(
        content: content,
        images: images,
        videos: videos,
        tags: tags,
      );

      if (response['success'] == true) {
        // Refresh feed to show new post
        await fetchFeed(refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
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
}
