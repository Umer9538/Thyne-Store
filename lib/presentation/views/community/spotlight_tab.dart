import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../viewmodels/community_provider.dart';
import '../../../data/models/community.dart';

class SpotlightTab extends StatefulWidget {
  const SpotlightTab({super.key});

  @override
  State<SpotlightTab> createState() => _SpotlightTabState();
}

class _SpotlightTabState extends State<SpotlightTab> {
  String _selectedFilter = 'MOST LIKED';
  List<CommunityPost> _featuredPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedPosts();
  }

  Future<void> _loadFeaturedPosts() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      // Get posts sorted by popularity (likes)
      final sortBy = _selectedFilter == 'MOST LIKED' ? 'popular' : 'trending';
      await provider.changeSortOrder(sortBy);
      setState(() {
        _featuredPosts = provider.posts.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadFeaturedPosts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Filter Pills
            _buildFilterPills(),

            const SizedBox(height: 20),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
            else ...[
              // Top 3 Leaders
              _buildTop3Leaders(),

              const SizedBox(height: 24),

              // Leaderboard List
              _buildLeaderboardList(),

              const SizedBox(height: 24),

              // Featured Posts Section
              _buildFeaturedPosts(),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterPill('MOST LIKED', _selectedFilter == 'MOST LIKED'),
          const SizedBox(width: 12),
          _buildFilterPill('TOP ENGAGEMENT', _selectedFilter == 'TOP ENGAGEMENT'),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
          _loadFeaturedPosts();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3D1F1F) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? const Color(0xFF3D1F1F) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.favorite : Icons.chat_bubble_outline,
                size: 16,
                color: isSelected ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTop3Leaders() {
    // Get top 3 posts by like count
    final topPosts = _featuredPosts.take(3).toList();
    if (topPosts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No featured posts yet'),
        ),
      );
    }

    // Ensure we have at least some posts to display
    while (topPosts.length < 3) {
      topPosts.add(topPosts.isNotEmpty ? topPosts.first : _createPlaceholderPost());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          _buildLeaderPodium(
            rank: 2,
            post: topPosts.length > 1 ? topPosts[1] : null,
            badge: Icons.looks_two,
            badgeColor: Colors.grey,
          ),

          // 1st Place
          _buildLeaderPodium(
            rank: 1,
            post: topPosts.isNotEmpty ? topPosts[0] : null,
            badge: Icons.emoji_events,
            badgeColor: const Color(0xFFFFD700),
            isWinner: true,
          ),

          // 3rd Place
          _buildLeaderPodium(
            rank: 3,
            post: topPosts.length > 2 ? topPosts[2] : null,
            badge: Icons.looks_3,
            badgeColor: const Color(0xFFCD7F32),
          ),
        ],
      ),
    );
  }

  CommunityPost _createPlaceholderPost() {
    return CommunityPost(
      id: '',
      userId: '',
      userName: 'No User',
      content: '',
      createdAt: DateTime.now(),
    );
  }

  Widget _buildLeaderPodium({
    required int rank,
    CommunityPost? post,
    required IconData badge,
    required Color badgeColor,
    bool isWinner = false,
  }) {
    final size = isWinner ? 100.0 : 80.0;
    final name = post?.userName ?? 'Unknown';
    final likes = post != null ? '${post.likeCount} likes' : '0 likes';
    final avatar = post?.userAvatar;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isWinner ? const Color(0xFFFFD700) : Colors.grey.shade300,
                  width: isWinner ? 3 : 2,
                ),
              ),
              child: ClipOval(
                child: avatar != null && avatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatar,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.person, size: size * 0.5),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: size * 0.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            if (isWinner)
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child: Icon(
                  Icons.emoji_events,
                  color: badgeColor,
                  size: 32,
                ),
              ),
            Positioned(
              bottom: -5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: size + 20,
          child: Text(
            name,
            style: TextStyle(
              fontSize: isWinner ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          likes,
          style: TextStyle(
            fontSize: isWinner ? 13 : 11,
            color: Colors.grey,
          ),
        ),
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Top Creator',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF3D1F1F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    final leaders = _featuredPosts.skip(3).take(5).toList();
    if (leaders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: leaders.asMap().entries.map((entry) {
          final index = entry.key;
          final post = entry.value;
          return _buildLeaderListItem(
            rank: index + 4, // Starting from 4th place
            post: post,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderListItem({
    required int rank,
    required CommunityPost post,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar
          ClipOval(
            child: post.userAvatar != null && post.userAvatar!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: post.userAvatar!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, size: 25),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[200],
                    child: Center(
                      child: Text(
                        post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // Name and stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 14, color: Colors.red[300]),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likeCount}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_upward, size: 14, color: Colors.green[300]),
                    const SizedBox(width: 4),
                    Text(
                      '${post.voteCount}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments
          Column(
            children: [
              Text(
                '${post.commentCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                'comments',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPosts() {
    final featuredPosts = _featuredPosts.where((p) => p.isFeatured || p.images.isNotEmpty).take(5).toList();
    if (featuredPosts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.star, color: Color(0xFF3D1F1F), size: 24),
              SizedBox(width: 8),
              Text(
                'featured posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: featuredPosts.map((post) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildFeaturedPostCard(post),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedPostCard(CommunityPost post) {
    final imageUrl = post.images.isNotEmpty ? post.images.first : null;
    final tag = post.tags.isNotEmpty ? post.tags.first.toUpperCase() : 'FEATURED';

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 200,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 200,
                    height: 250,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 200,
                    height: 250,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 64),
                  ),
                )
              : Container(
                  width: 200,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF3D1F1F),
                        const Color(0xFF3D1F1F).withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        post.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likeCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.comment, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
