import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';

// Import existing providers
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/cart_provider.dart';
import '../../viewmodels/wishlist_provider.dart';
import '../../viewmodels/product_provider.dart';
import '../../viewmodels/community_provider.dart';

// Import theme
import '../../../theme/thyne_theme.dart';

// Section screens (to be created)
import '../commerce/commerce_section.dart';
import '../community/community_section.dart';
import '../create/create_section.dart';

class ThyneMainNavigation extends StatefulWidget {
  const ThyneMainNavigation({Key? key}) : super(key: key);

  @override
  State<ThyneMainNavigation> createState() => _ThyneMainNavigationState();
}

class _ThyneMainNavigationState extends State<ThyneMainNavigation>
    with SingleTickerProviderStateMixin {
  // Navigation state
  int _selectedModule = 0; // 0: Commerce, 1: Community, 2: Create
  bool _isHeaderVisible = true;
  bool _isToolbarVisible = true;

  // Scroll controllers
  final ScrollController _scrollController = ScrollController();
  double _lastScrollPosition = 0;

  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Module names
  final List<String> _moduleNames = ['commerce', 'community', 'create'];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Load initial data
    _loadInitialData();

    // Setup scroll listener for collapsible navigation
    _scrollController.addListener(_handleScroll);
  }

  void _loadInitialData() {
    // Load data using existing providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load user data if authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        // Load wishlist
        Provider.of<WishlistProvider>(context, listen: false).loadWishlist();
        // Load products
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
        // Load community feed
        Provider.of<CommunityProvider>(context, listen: false).fetchFeed();
      }
    });
  }

  void _handleScroll() {
    final currentScroll = _scrollController.position.pixels;
    final scrollDiff = currentScroll - _lastScrollPosition;

    // Only trigger if scrolled more than 5px (avoid jittery behavior)
    if (scrollDiff.abs() < 5) return;

    setState(() {
      // Scrolling UP - hide both (collapse when going up)
      if (scrollDiff < 0 && currentScroll > 50) {
        _isHeaderVisible = false;
        _isToolbarVisible = false;
      }
      // Scrolling DOWN - show both (expand when scrolling down)
      else if (scrollDiff > 0) {
        _isHeaderVisible = true;
        _isToolbarVisible = true;
      }
    });

    _lastScrollPosition = currentScroll;
  }

  void _onModuleChanged(int index) {
    if (_selectedModule != index) {
      setState(() {
        _selectedModule = index;
        _isHeaderVisible = true;
        _isToolbarVisible = true;
      });

      // Animate transition
      _animationController.forward(from: 0);

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Reset scroll position
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentModule = _moduleNames[_selectedModule];
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      backgroundColor: ThyneTheme.background,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Collapsible App Bar
              AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                offset: Offset(0, _isHeaderVisible ? 0 : -1),
                child: _buildCollapsibleAppBar(
                  context,
                  cartItemCount: cartProvider.itemCount,
                  wishlistCount: wishlistProvider.wishlist.length,
                ),
              ),

              // Module-specific top navigation
              AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                offset: Offset(0, _isHeaderVisible ? 0 : -1),
                child: _buildModuleTopNav(currentModule),
              ),

              // Content area
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(currentModule),
                ),
              ),
            ],
          ),

          // Bottom navigation with glass morphism
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              offset: Offset(0, _isToolbarVisible ? 0 : 1),
              child: _buildBottomNavigation(currentModule),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleAppBar(BuildContext context, {
    required int cartItemCount,
    required int wishlistCount,
  }) {
    return Container(
      height: 60 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: ThyneTheme.background.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: ThyneTheme.border,
            width: 0.5,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              const SizedBox(width: 16),

              // Logo
              Text(
                'THYNE',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: ThyneTheme.trackingWider,
                ),
              ),

              const Spacer(),

              // Wishlist button
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/wishlist');
                },
                icon: Badge(
                  isLabelVisible: wishlistCount > 0,
                  label: Text('$wishlistCount'),
                  child: Icon(
                    CupertinoIcons.heart,
                    size: 22,
                    color: ThyneTheme.foreground,
                  ),
                ),
              ),

              // Cart button
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                icon: Badge(
                  isLabelVisible: cartItemCount > 0,
                  label: Text('$cartItemCount'),
                  child: Icon(
                    CupertinoIcons.bag,
                    size: 22,
                    color: ThyneTheme.foreground,
                  ),
                ),
              ),

              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleTopNav(String module) {
    switch (module) {
      case 'commerce':
        return _buildCommerceTopNav();
      case 'community':
        return _buildCommunityTopNav();
      case 'create':
        return _buildCreateTopNav();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCommerceTopNav() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ThyneTheme.background.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: ThyneTheme.border,
            width: 0.5,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('All', true),
          _buildCategoryChip('Rings', false),
          _buildCategoryChip('Necklaces', false),
          _buildCategoryChip('Earrings', false),
          _buildCategoryChip('Bracelets', false),
          _buildCategoryChip('Bangles', false),
          _buildCategoryChip('Pendants', false),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool value) {
          // TODO: Implement category filtering
        },
        selectedColor: ThyneTheme.commerceGreen.withOpacity(0.1),
        checkmarkColor: ThyneTheme.commerceGreen,
        labelStyle: TextStyle(
          color: isSelected ? ThyneTheme.commerceGreen : ThyneTheme.foreground,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        backgroundColor: ThyneTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? ThyneTheme.commerceGreen.withOpacity(0.3)
                : ThyneTheme.border,
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityTopNav() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ThyneTheme.background.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: ThyneTheme.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton('Verse', true, ThyneTheme.communityRuby),
          _buildTabButton('Spotlight', false, ThyneTheme.communityRuby),
          _buildTabButton('Profile', false, ThyneTheme.communityRuby),
        ],
      ),
    );
  }

  Widget _buildCreateTopNav() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ThyneTheme.background.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: ThyneTheme.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton('Chat', true, ThyneTheme.createBlue),
          _buildTabButton('Creations', false, ThyneTheme.createBlue),
          _buildTabButton('History', false, ThyneTheme.createBlue),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected, Color moduleColor) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // TODO: Implement tab switching
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
                    bottom: BorderSide(
                      color: moduleColor,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? moduleColor : ThyneTheme.mutedForeground,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String module) {
    return IndexedStack(
      index: _selectedModule,
      children: const [
        CommerceSection(),
        CommunitySection(),
        CreateSection(),
      ],
    );
  }

  Widget _buildBottomNavigation(String currentModule) {
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: ThyneTheme.background.withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: ThyneTheme.border,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: CupertinoIcons.shopping_cart,
                  module: 'commerce',
                  index: 0,
                  isSelected: _selectedModule == 0,
                ),
                _buildNavItem(
                  icon: CupertinoIcons.person_2,
                  module: 'community',
                  index: 1,
                  isSelected: _selectedModule == 1,
                ),
                _buildNavItem(
                  icon: CupertinoIcons.sparkles,
                  module: 'create',
                  index: 2,
                  isSelected: _selectedModule == 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String module,
    required int index,
    required bool isSelected,
  }) {
    final color = ThyneTheme.getModuleColor(module);

    return InkWell(
      onTap: () => _onModuleChanged(index),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 24,
            color: isSelected
                ? color
                : ThyneTheme.mutedForeground.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}