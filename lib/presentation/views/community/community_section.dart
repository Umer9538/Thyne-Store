import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_provider.dart';
import '../viewmodels/cart_provider.dart';
import '../viewmodels/wishlist_provider.dart';
import '../../../utils/theme.dart';
import 'feed_tab.dart';
import 'spotlight_tab.dart';
import 'profile_tab.dart';
import 'create_post_screen.dart';

class CommunitySection extends StatefulWidget {
  const CommunitySection({super.key});

  @override
  State<CommunitySection> createState() => _CommunitySectionState();
}

class _CommunitySectionState extends State<CommunitySection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        Column(
          children: [
            // Custom Header
            _buildCustomHeader(authProvider, cartProvider, wishlistProvider),

            // Tab Pills
            _buildTabPills(),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  FeedTab(),
                  SpotlightTab(),
                  ProfileTab(),
                ],
              ),
            ),
          ],
        ),
        // Floating Search Bar with Create Post Button
        Positioned(
          bottom: 80 + bottomPadding, // Account for bottom navigation + safe area
          left: 16,
          right: 16,
          child: _buildFloatingSearchBar(),
        ),
      ],
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
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildFloatingSearchBar() {
    return Row(
      children: [
        // Green circular button with plus icon - Create Post
        GestureDetector(
          onTap: _navigateToCreatePost,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF3D1F1F), // Dark maroon color
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Search bar
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Show search
              Navigator.pushNamed(context, '/search');
            },
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ask me anything',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.mic,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomHeader(AuthProvider authProvider, CartProvider cartProvider, WishlistProvider wishlistProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          // Top row: Logo and User Avatar
          Row(
            children: [
              // Globe icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.language, size: 20, color: Colors.grey),
              ),
              const SizedBox(width: 12),

              // THYNE Logo
              const Text(
                'THYNE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const Spacer(),

              // User Avatar
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 20,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Delivery Location + Icons
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              const Text(
                'deliver to ',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const Text(
                'Sector 2',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),

              const Spacer(),

              // Gift Icon
              IconButton(
                icon: const Icon(Icons.card_giftcard_outlined, size: 22),
                onPressed: () {
                  // TODO: Navigate to gifts
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
              ),

              // Wishlist Icon
              IconButton(
                icon: Badge(
                  label: Text('${wishlistProvider.wishlistCount}'),
                  isLabelVisible: wishlistProvider.wishlistCount > 0,
                  child: const Icon(Icons.favorite_outline, size: 22),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/wishlist');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
              ),

              // Cart Icon
              IconButton(
                icon: Badge(
                  label: Text('${cartProvider.itemCount}'),
                  isLabelVisible: cartProvider.itemCount > 0,
                  child: const Icon(Icons.shopping_bag_outlined, size: 22),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabPills() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: const Color(0xFFF5F5F0),
      child: Row(
        children: [
          _buildTabPill('feed', 0),
          const SizedBox(width: 12),
          _buildTabPill('spotlight', 1),
          const SizedBox(width: 12),
          _buildTabPill('profile', 2),
        ],
      ),
    );
  }

  Widget _buildTabPill(String label, int index) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
