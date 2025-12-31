import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../viewmodels/auth_provider.dart';
import '../viewmodels/cart_provider.dart';
import '../viewmodels/wishlist_provider.dart';
import 'feed_tab_figma.dart';
import 'spotlight_tab.dart';
import 'profile_tab.dart';

class CommunitySectionFigma extends StatefulWidget {
  const CommunitySectionFigma({super.key});

  @override
  State<CommunitySectionFigma> createState() => _CommunitySectionFigmaState();
}

class _CommunitySectionFigmaState extends State<CommunitySectionFigma> with SingleTickerProviderStateMixin {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          // Custom App Bar
          _buildCustomAppBar(authProvider, cartProvider, wishlistProvider),

          // Tab Pills
          _buildTabPills(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FeedTabFigma(),
                SpotlightTab(),
                ProfileTab(),
              ],
            ),
          ),
        ],
      ),
      // FAB removed - Create post button is in the floating search bar instead
    );
  }

  Widget _buildCustomAppBar(
    AuthProvider authProvider,
    CartProvider cartProvider,
    WishlistProvider wishlistProvider,
  ) {
    return Container(
      color: const Color(0xFFFAF8F3), // Cream background matching Figma
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Top Row - Logo and User Avatar
              Row(
                children: [
                  // Logo Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/thyne.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // THYNE Text
                  const Text(
                    'THYNE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  // User Avatar
                  GestureDetector(
                    onTap: () {
                      if (authProvider.isAuthenticated) {
                        Navigator.pushNamed(context, '/profile');
                      } else {
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: authProvider.isAuthenticated && authProvider.user?.profilePicture != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: authProvider.user!.profilePicture!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              authProvider.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom Row - Location and Action Icons
              Row(
                children: [
                  // Location
                  const Icon(
                    CupertinoIcons.location,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'deliver to ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                  Text(
                    authProvider.user?.defaultAddress?.city ?? 'Sector 2',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  // Gift Icon
                  const Icon(
                    CupertinoIcons.gift,
                    size: 22,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 20),
                  // Heart Icon
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/wishlist'),
                    child: const Icon(
                      CupertinoIcons.heart,
                      size: 22,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Shopping Bag Icon with Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/cart'),
                        child: const Icon(
                          CupertinoIcons.bag,
                          size: 22,
                          color: Color(0xFF666666),
                        ),
                      ),
                      if (cartProvider.items.isNotEmpty)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                '${cartProvider.items.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPills() {
    return Container(
      color: const Color(0xFFFAF8F3),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFECE8E1),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildTabPill('feed', 0),
            _buildTabPill('spotlight', 1),
            _buildTabPill('profile', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(String label, int index) {
    final isSelected = _currentTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3D3D3D) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : const Color(0xFF6B6B6B),
            ),
          ),
        ),
      ),
    );
  }

}