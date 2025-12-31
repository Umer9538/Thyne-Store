import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../viewmodels/auth_provider.dart';
import '../../data/models/community.dart';
import '../../data/services/api_service.dart';
import 'create_post_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CommunityPost> _userPosts = [];
  InstagramProfile? _instagramProfile;
  bool _isLoading = true;
  int _totalLikes = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = authProvider.user?.id ?? '';
      debugPrint('📱 Loading posts for user: $userId');

      // Load user's posts
      final postsResponse = await ApiService.getUserPosts(userId);
      debugPrint('📱 Posts response: $postsResponse');

      if (postsResponse['success'] == true && postsResponse['data'] != null) {
        final data = postsResponse['data'];
        // Handle both formats: direct array or {posts: [...]} object
        List postsData;
        if (data is List) {
          postsData = data;
        } else if (data is Map && data['posts'] != null) {
          postsData = data['posts'] as List;
        } else {
          postsData = [];
        }

        _userPosts = postsData.map((p) => CommunityPost.fromJson(p)).toList();
        debugPrint('📱 Loaded ${_userPosts.length} posts');

        // Calculate total likes
        _totalLikes = _userPosts.fold(0, (sum, post) => sum + post.likeCount);
      } else {
        debugPrint('📱 No posts data in response');
      }

      // Load Instagram profile
      try {
        final instaResponse = await ApiService.getInstagramProfile(userId);
        if (instaResponse['success'] == true && instaResponse['data'] != null) {
          _instagramProfile = InstagramProfile.fromJson(instaResponse['data']);
        }
      } catch (e) {
        // Instagram not linked, that's ok
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return _buildNotLoggedIn();
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(authProvider),

            const SizedBox(height: 20),

            // Stats
            _buildStats(),

            const SizedBox(height: 20),

            // Bio
            _buildBio(authProvider),

            // Instagram Link
            if (_instagramProfile != null) _buildInstagramLink(),

            const SizedBox(height: 20),

            // Add Post Button
            _buildAddPostButton(),

            const SizedBox(height: 20),

            // Link Instagram Button (if not linked)
            if (_instagramProfile == null) _buildLinkInstagramButton(),

            const SizedBox(height: 20),

            // Tabs (Grid/Saved)
            _buildTabs(),

            // Posts Grid
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
            else
              _buildPostsGrid(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Sign in to view your profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create posts, track your engagement, and connect with the community',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D1F1F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    final user = authProvider.user;
    final avatar = user?.profileImage;
    final name = user?.name ?? 'User';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
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
                        child: const Icon(Icons.person, size: 50),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 20),

          // Name and Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user?.role == 'admin')
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${_userPosts.length}', 'Posts'),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
          ),
          _buildStatItem(_formatNumber(_totalLikes), 'Likes'),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '$number';
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildBio(AuthProvider authProvider) {
    final user = authProvider.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user?.name ?? 'Your Name',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (user?.phone != null && user!.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.phone,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstagramLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Could open Instagram app or web profile
            },
            child: Row(
              children: [
                const Icon(Icons.camera_alt, size: 16, color: Color(0xFFE1306C)),
                const SizedBox(width: 8),
                Text(
                  '@${_instagramProfile!.username}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE1306C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_instagramProfile!.isVerified)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.verified, size: 16, color: Color(0xFF3897F0)),
                  ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showUnlinkInstagramDialog,
            child: const Text(
              'Unlink',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnlinkInstagramDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Instagram'),
        content: Text(
          'Are you sure you want to unlink @${_instagramProfile?.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await ApiService.unlinkInstagram();
                if (!mounted) return;
                if (response['success'] == true) {
                  setState(() {
                    _instagramProfile = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Instagram unlinked successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPostButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );
          if (result == true) {
            _loadUserData();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3D1F1F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Post',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkInstagramButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showLinkInstagramDialog(),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE1306C),
          side: const BorderSide(color: Color(0xFFE1306C)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 20),
            SizedBox(width: 8),
            Text(
              'Link Instagram',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkInstagramDialog() {
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Instagram'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your Instagram username to link your profile.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Instagram Username',
                prefixText: '@',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = usernameController.text.trim();
              if (username.isEmpty) return;

              Navigator.pop(context);

              try {
                final response = await ApiService.linkInstagram(
                  instagramId: username,
                  username: username,
                );

                if (!mounted) return;
                if (response['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Instagram linked successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadUserData();
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE1306C),
            ),
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF3D1F1F),
        labelColor: const Color(0xFF3D1F1F),
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on, size: 28)),
          Tab(icon: Icon(Icons.bookmark_border, size: 28)),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_userPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your first post with the community!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        return _buildPostItem(_userPosts[index]);
      },
    );
  }

  Widget _buildPostItem(CommunityPost post) {
    final imageUrl = post.images.isNotEmpty ? post.images.first : null;

    return GestureDetector(
      onTap: () {
        // Navigate to post detail
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            )
          else
            Container(
              color: const Color(0xFF3D1F1F),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  post.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Engagement overlay
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 12, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    '${post.likeCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
