import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/community_post_card.dart';
import '../../models/community.dart';
import '../../utils/theme.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isLoadingPost = true;
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;
  CommunityPost? _post;
  List<PostComment> _comments = [];
  PostEngagement? _engagement;

  @override
  void initState() {
    super.initState();
    _loadPostAndComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostAndComments() async {
    final provider = Provider.of<CommunityProvider>(context, listen: false);

    // Load post
    setState(() {
      _isLoadingPost = true;
      _isLoadingComments = true;
    });

    try {
      // Get post from feed or fetch individual post
      _post = provider.posts.firstWhere(
        (p) => p.id == widget.postId,
        orElse: () => provider.posts.first, // Fallback
      );

      // Get engagement
      _engagement = await provider.getPostEngagement(widget.postId);

      // Get comments
      _comments = await provider.getPostComments(widget.postId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPost = false;
          _isLoadingComments = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      final success = await provider.addComment(widget.postId, content);

      if (success) {
        _commentController.clear();
        // Reload comments
        _comments = await provider.getPostComments(widget.postId, forceRefresh: true);
        FocusScope.of(context).unfocus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment posted!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: _isLoadingPost
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('Post not found'))
              : Column(
                  children: [
                    // Post content
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          // Post card
                          Consumer<CommunityProvider>(
                            builder: (context, provider, child) {
                              return CommunityPostCard(
                                post: _post!,
                                userLiked: _engagement?.userLiked ?? false,
                                userVoted: _engagement?.userVoted ?? '',
                                onLike: isLoggedIn
                                    ? () async {
                                        await provider.toggleLike(widget.postId);
                                        _engagement = await provider.getPostEngagement(
                                          widget.postId,
                                          forceRefresh: true,
                                        );
                                        setState(() {});
                                      }
                                    : null,
                                onVote: isLoggedIn
                                    ? (voteType) async {
                                        await provider.votePost(
                                          widget.postId,
                                          voteType,
                                        );
                                        _engagement = await provider.getPostEngagement(
                                          widget.postId,
                                          forceRefresh: true,
                                        );
                                        setState(() {});
                                      }
                                    : null,
                              );
                            },
                          ),

                          // Comments section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Comments (${_post!.commentCount})',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),

                          if (_isLoadingComments)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_comments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.comment_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No comments yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Be the first to comment!',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _comments.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final comment = _comments[index];
                                return _buildCommentCard(comment);
                              },
                            ),
                        ],
                      ),
                    ),

                    // Comment input
                    if (isLoggedIn) _buildCommentInput(),
                  ],
                ),
    );
  }

  Widget _buildCommentCard(PostComment comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
          backgroundImage: comment.userAvatar != null && comment.userAvatar!.isNotEmpty
              ? CachedNetworkImageProvider(comment.userAvatar!)
              : null,
          child: comment.userAvatar == null || comment.userAvatar!.isEmpty
              ? Text(
                  comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),

        // Comment content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeago.format(comment.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.content,
                style: const TextStyle(fontSize: 14),
              ),
              if (comment.likeCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${comment.likeCount} likes',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 8),
          _isSubmittingComment
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }
}
