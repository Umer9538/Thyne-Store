import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/community.dart';
import '../../utils/theme.dart';
import 'glass/glass_ui.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onLike;
  final Function(String)? onVote; // "up" or "down"
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  final bool userLiked;
  final String userVoted; // "up", "down", or ""

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onVote,
    this.onComment,
    this.onShare,
    this.onTap,
    this.userLiked = false,
    this.userVoted = '',
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      elevation: 2,
      blur: GlassConfig.softBlur,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Header: User info
              _buildHeader(context),
              const SizedBox(height: 12),

              // Content
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              // Tags
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: post.tags.map((tag) => _buildTag(tag)).toList(),
                ),
              ],

              // Images/Videos
              if (post.images.isNotEmpty || post.videos.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMediaGallery(),
              ],

              const SizedBox(height: 12),

              // Engagement stats
              _buildEngagementStats(context),

              const Divider(height: 20),

              // Action buttons
              _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // User avatar
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

        // User name and time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.userName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.isAdminPost) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppTheme.primaryGold,
                    ),
                  ],
                ],
              ),
              Text(
                timeago.format(post.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _buildTag(String tag) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      blur: GlassConfig.softBlur,
      borderRadius: BorderRadius.circular(8),
      tintColor: AppTheme.primaryGold,
      showGlow: true,
      child: Text(
        '#$tag',
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.primaryGold,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMediaGallery() {
    final totalMedia = post.images.length + post.videos.length;

    if (totalMedia == 0) return const SizedBox.shrink();

    if (totalMedia == 1) {
      // Single image or video
      final imageUrl = post.images.isNotEmpty ? post.images[0] : null;
      if (imageUrl != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 300,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            ),
          ),
        );
      }
    }

    // Multiple images - show grid
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: post.images.length,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: post.images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEngagementStats(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (post.likeCount > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${post.likeCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        if (post.voteCount != 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                post.voteCount > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: post.voteCount > 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.voteCount.abs()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: post.voteCount > 0 ? Colors.green : Colors.red,
                    ),
              ),
            ],
          ),
        if (post.commentCount > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.comment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${post.commentCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Like button
        Flexible(
          child: _ActionButton(
            icon: userLiked ? Icons.favorite : Icons.favorite_border,
            label: 'Like',
            color: userLiked ? AppTheme.errorRed : Colors.grey[700]!,
            onTap: onLike,
          ),
        ),

        // Upvote button
        Flexible(
          child: _ActionButton(
            icon: Icons.arrow_upward,
            label: 'Up',
            color: userVoted == 'up' ? Colors.green : Colors.grey[700]!,
            onTap: onVote != null ? () => onVote!('up') : null,
          ),
        ),

        // Downvote button
        Flexible(
          child: _ActionButton(
            icon: Icons.arrow_downward,
            label: 'Down',
            color: userVoted == 'down' ? Colors.red : Colors.grey[700]!,
            onTap: onVote != null ? () => onVote!('down') : null,
          ),
        ),

        // Comment button
        Flexible(
          child: _ActionButton(
            icon: Icons.comment_outlined,
            label: 'Comment',
            color: Colors.grey[700]!,
            onTap: onComment,
          ),
        ),

        // Share button
        Flexible(
          child: _ActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            color: Colors.grey[700]!,
            onTap: onShare,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
