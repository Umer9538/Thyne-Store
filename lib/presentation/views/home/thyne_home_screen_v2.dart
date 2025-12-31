import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';

import '../viewmodels/auth_provider.dart';
import '../viewmodels/cart_provider.dart';
import '../viewmodels/product_provider.dart';
import '../viewmodels/wishlist_provider.dart';
import '../viewmodels/community_provider.dart';
import '../../data/services/api_service.dart';
import '../../../theme/thyne_theme.dart';
import '../../data/models/product.dart';
import '../../../utils/currency_formatter.dart';
import '../product/product_detail_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../cart/cart_screen.dart';
import '../community/community_section.dart';
import '../ai/ai_create_section.dart';

class ThyneHomeScreenV2 extends StatefulWidget {
  const ThyneHomeScreenV2({Key? key}) : super(key: key);

  @override
  State<ThyneHomeScreenV2> createState() => _ThyneHomeScreenV2State();
}

class _ThyneHomeScreenV2State extends State<ThyneHomeScreenV2> with TickerProviderStateMixin {
  // Navigation State
  String selectedTab = 'commerce';
  String selectedCategory = 'All';
  String communityTab = 'verse';
  String createTab = 'chat';

  // UI Visibility State
  bool isHeaderVisible = true;
  bool isToolbarVisible = true;
  bool isSearchOpen = false;
  bool isFullScreenOpen = false;

  // Scroll Controller
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0;

  // Animation Controllers
  late AnimationController _headerAnimationController;
  late AnimationController _toolbarAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _toolbarAnimation;

  // Dynamic Content Data
  List<dynamic> _banners = [];
  List<dynamic> _flashSales = [];
  List<dynamic> _dealsOfDay = [];
  List<dynamic> _bundles = [];
  List<dynamic> _showcases = [];
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadDynamicContent();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0,
      end: -104, // Height of collapsible header
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Cubic(0.32, 0.72, 0, 1),
    ));

    _toolbarAnimation = Tween<double>(
      begin: 0,
      end: 200, // Height of bottom toolbar + search
    ).animate(CurvedAnimation(
      parent: _toolbarAnimationController,
      curve: const Cubic(0.32, 0.72, 0, 1),
    ));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final currentOffset = _scrollController.offset;
        final delta = currentOffset - _lastScrollOffset;

        // Only hide/show after scrolling more than 5px
        if (delta.abs() > 5) {
          if (delta > 0 && currentOffset > 50) {
            // Scrolling down - hide bars
            _hideNavigationBars();
          } else if (delta < 0) {
            // Scrolling up - show bars
            _showNavigationBars();
          }
          _lastScrollOffset = currentOffset;
        }
      }
    });
  }

  void _hideNavigationBars() {
    if (isHeaderVisible) {
      setState(() => isHeaderVisible = false);
      _headerAnimationController.forward();
    }
    if (isToolbarVisible) {
      setState(() => isToolbarVisible = false);
      _toolbarAnimationController.forward();
    }
  }

  void _showNavigationBars() {
    if (!isHeaderVisible) {
      setState(() => isHeaderVisible = true);
      _headerAnimationController.reverse();
    }
    if (!isToolbarVisible) {
      setState(() => isToolbarVisible = true);
      _toolbarAnimationController.reverse();
    }
  }

  Future<void> _loadDynamicContent() async {
    setState(() => _isLoadingContent = true);

    try {
      // Load all dynamic content in parallel
      final results = await Future.wait([
        ApiService.getActiveBanners(),
        ApiService.getFlashSales(),
        ApiService.getDealsOfDay(),
        ApiService.getBundleDeals(),
        ApiService.getShowcases(),
      ]);

      setState(() {
        _banners = results[0]['data'] ?? [];
        _flashSales = results[1]['data'] ?? [];
        _dealsOfDay = results[2]['data'] ?? [];
        _bundles = results[3]['data'] ?? [];
        _showcases = results[4]['data'] ?? [];
        _isLoadingContent = false;
      });
    } catch (e) {
      print('Error loading dynamic content: $e');
      setState(() => _isLoadingContent = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _toolbarAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThyneTheme.background,
      body: Column(
        children: [
          // Top Navigation Bar
          AnimatedBuilder(
            animation: _headerAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _headerAnimation.value),
                child: _buildCollapsibleAppBar(),
              );
            },
          ),

          // Module Navigation (Commerce/Community/Create specific)
          if (selectedTab == 'commerce')
            AnimatedBuilder(
              animation: _headerAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _headerAnimation.value),
                  child: _buildCommerceTopNav(),
                );
              },
            ),

          // Main Content Area
          Expanded(
            child: Stack(
              children: [
                _buildMainContent(),

                // Search Overlay
                if (isSearchOpen) _buildSearchOverlay(),
              ],
            ),
          ),

          // Bottom Toolbar with Search
          AnimatedBuilder(
            animation: _toolbarAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _toolbarAnimation.value),
                child: _buildBottomToolbar(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleAppBar() {
    return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: ThyneTheme.background.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: ThyneTheme.border,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Row 1: Logo + Avatar (Always visible)
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Thyne Logo + Text
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: ThyneTheme.getModuleColor(selectedTab),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  'T',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'THYNE',
                              style: GoogleFonts.inter(
                                fontSize: ThyneTheme.textBodySm,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.08,
                                color: ThyneTheme.foreground,
                              ),
                            ),
                          ],
                        ),
                        // User Avatar
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/profile');
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ThyneTheme.border,
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: auth.user?.profileImage != null
                                      ? CachedNetworkImage(
                                          imageUrl: auth.user!.profileImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: ThyneTheme.muted,
                                          child: Icon(
                                            CupertinoIcons.person_fill,
                                            size: 18,
                                            color: ThyneTheme.mutedForeground,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Row 2: Location + Icons (Collapsible)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    height: isHeaderVisible ? 60 : 0,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Location
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.location,
                                  size: 16,
                                  color: ThyneTheme.mutedForeground,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'deliver to Sector 2',
                                  style: GoogleFonts.inter(
                                    fontSize: ThyneTheme.textBodySm,
                                    color: ThyneTheme.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                            // Icons
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    CupertinoIcons.gift,
                                    size: 20,
                                    color: ThyneTheme.mutedForeground,
                                  ),
                                  onPressed: () {},
                                ),
                                Consumer<WishlistProvider>(
                                  builder: (context, wishlist, _) {
                                    return Stack(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            CupertinoIcons.heart,
                                            size: 20,
                                            color: ThyneTheme.mutedForeground,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const WishlistScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        if (wishlist.wishlist.isNotEmpty)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: ThyneTheme.communityRuby,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                Consumer<CartProvider>(
                                  builder: (context, cart, _) {
                                    return Stack(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            CupertinoIcons.bag,
                                            size: 20,
                                            color: ThyneTheme.mutedForeground,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const CartScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        if (cart.items.isNotEmpty)
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: ThyneTheme.commerceGreen,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${cart.items.length}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildCommerceTopNav() {
    final categories = ['All', 'Women', 'Men', 'Inclusive', 'Kids'];

    return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: ThyneTheme.background.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: ThyneTheme.border,
                  width: 1,
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isActive = selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedCategory = category);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Stack(
                        children: [
                          // Glow effect for active state
                          if (isActive) ...[
                            // Outer glow
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ThyneTheme.commerceGreen.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // Main button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? ThyneTheme.commerceGreen.withOpacity(0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? ThyneTheme.commerceGreen
                                    : ThyneTheme.border,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                  letterSpacing: 0.5,
                                  color: isActive
                                      ? ThyneTheme.commerceGreen
                                      : ThyneTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
  }

  Widget _buildBottomToolbar() {
    return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: ThyneTheme.background.withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: ThyneTheme.border,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Bar
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => isSearchOpen = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: ThyneTheme.muted,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: ThyneTheme.border,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.search,
                              size: 16,
                              color: ThyneTheme.mutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Search for products...',
                              style: GoogleFonts.inter(
                                fontSize: ThyneTheme.textBody,
                                color: ThyneTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Navigation Tabs
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: ThyneTheme.border,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildNavTab(
                          'commerce',
                          CupertinoIcons.bag,
                          'Shop',
                        ),
                        _buildNavTab(
                          'community',
                          CupertinoIcons.heart_fill,
                          'Community',
                        ),
                        _buildNavTab(
                          'create',
                          CupertinoIcons.plus,
                          'Create',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildNavTab(String tab, IconData icon, String label) {
    final isActive = selectedTab == tab;
    final color = ThyneTheme.getModuleColor(tab);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = tab),
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? color.withOpacity(0.1)
                : Colors.transparent,
            border: isActive
                ? Border(
                    top: BorderSide(
                      color: color,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? color : ThyneTheme.mutedForeground,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: ThyneTheme.trackingWider,
                  color: isActive ? color : ThyneTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: _buildTabContent(),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case 'commerce':
        return _buildCommerceContent();
      case 'community':
        return _buildCommunityContent();
      case 'create':
        return _buildCreateContent();
      default:
        return _buildCommerceContent();
    }
  }

  Widget _buildCommerceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Banner Carousel - Show placeholder if empty
        _banners.isNotEmpty ? _buildHeroBanner() : _buildPlaceholderBanner(),

        // Flash Sales
        if (_flashSales.isNotEmpty) _buildFlashSales(),

        // Deals of the Day
        if (_dealsOfDay.isNotEmpty) _buildDealsOfDay(),

        // Bundle Deals
        if (_bundles.isNotEmpty) _buildBundleDeals(),

        // 360 Showcases
        if (_showcases.isNotEmpty) _buildShowcases(),

        // Shop by Category - Always show
        _buildShopByCategory(),

        // Featured Products
        _buildFeaturedProducts(),

        // Trending Now
        _buildTrendingProducts(),

        // New Arrivals
        _buildNewArrivals(),

        const SizedBox(height: 100), // Space for bottom navigation
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 400,
      child: carousel.CarouselSlider(
        options: carousel.CarouselOptions(
          height: 400,
          viewportFraction: 1.0,
          enlargeCenterPage: false,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
        ),
        items: _banners.map((banner) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(
                  banner['imageUrl'] ?? '',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner['title'] ?? 'Begin Your Bridal Journey',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: ThyneTheme.trackingTight,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    banner['subtitle'] ?? 'Explore our exclusive collection',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (banner['link'] != null) {
                        // Navigate to banner link
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThyneTheme.commerceGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      banner['ctaText'] ?? 'Shop Now',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: ThyneTheme.trackingWider,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlashSales() {
    return _buildSection(
      title: 'Flash Sales',
      subtitle: 'Limited time offers',
      child: SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _flashSales.length,
          itemBuilder: (context, index) {
            final sale = _flashSales[index];
            return _buildProductCard(
              Product.fromJson(sale['product'] ?? {}),
              badge: '${sale['discount']}% OFF',
              badgeColor: ThyneTheme.communityRuby,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDealsOfDay() {
    return _buildSection(
      title: 'Deals of the Day',
      subtitle: 'Today\'s best offers',
      child: SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _dealsOfDay.length,
          itemBuilder: (context, index) {
            final deal = _dealsOfDay[index];
            return _buildProductCard(
              Product.fromJson(deal['product'] ?? {}),
              badge: 'DEAL',
              badgeColor: ThyneTheme.commerceGreen,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBundleDeals() {
    return _buildSection(
      title: 'Bundle Deals',
      subtitle: 'Save more with bundles',
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _bundles.length,
          itemBuilder: (context, index) {
            final bundle = _bundles[index];
            return Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ThyneTheme.border,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bundle['name'] ?? 'Bundle Deal',
                    style: GoogleFonts.inter(
                      fontSize: ThyneTheme.textHeadingSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bundle['description'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: ThyneTheme.textBodySm,
                      color: ThyneTheme.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CurrencyFormatter.format(bundle['price'] ?? 0),
                            style: GoogleFonts.inter(
                              fontSize: ThyneTheme.textHeadingSm,
                              fontWeight: FontWeight.w600,
                              color: ThyneTheme.commerceGreen,
                            ),
                          ),
                          Text(
                            'Save ${bundle['savings'] ?? '0'}%',
                            style: GoogleFonts.inter(
                              fontSize: ThyneTheme.textFootnote,
                              color: ThyneTheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThyneTheme.commerceGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'View Bundle',
                          style: GoogleFonts.inter(
                            fontSize: ThyneTheme.textFootnote,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShowcases() {
    return _buildSection(
      title: '360° Showcases',
      subtitle: 'Interactive product views',
      child: SizedBox(
        height: 250,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _showcases.length,
          itemBuilder: (context, index) {
            final showcase = _showcases[index];
            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    showcase['thumbnailUrl'] ?? '',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.play_circle_fill,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      showcase['title'] ?? 'View in 360°',
                      style: GoogleFonts.inter(
                        fontSize: ThyneTheme.textBody,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      showcase['subtitle'] ?? 'Interactive view',
                      style: GoogleFonts.inter(
                        fontSize: ThyneTheme.textFootnote,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShopByCategory() {
    final categories = [
      {'name': 'Rings', 'icon': CupertinoIcons.circle, 'color': ThyneTheme.commerceGreen},
      {'name': 'Necklaces', 'icon': CupertinoIcons.link, 'color': ThyneTheme.communityRuby},
      {'name': 'Earrings', 'icon': CupertinoIcons.drop, 'color': ThyneTheme.createBlue},
      {'name': 'Bracelets', 'icon': CupertinoIcons.circle_grid_3x3, 'color': Color(0xFFF59E0B)},
    ];

    return _buildSection(
      title: 'Shop by Category',
      subtitle: 'Find what you\'re looking for',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                // Navigate to category
              },
              child: Container(
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (category['color'] as Color).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 32,
                      color: category['color'] as Color,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: ThyneTheme.textBody,
                        fontWeight: FontWeight.w500,
                        color: ThyneTheme.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final products = productProvider.featuredProducts.take(6).toList();

        if (products.isEmpty) return const SizedBox.shrink();

        return _buildSection(
          title: 'Featured Products',
          subtitle: 'Handpicked for you',
          child: SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  products[index],
                  badge: 'FEATURED',
                  badgeColor: ThyneTheme.commerceGreen,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendingProducts() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final products = productProvider.products
            .where((p) => p.rating > 4.5)
            .take(6)
            .toList();

        if (products.isEmpty) return const SizedBox.shrink();

        return _buildSection(
          title: 'Trending Now',
          subtitle: 'Most loved by customers',
          child: SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  products[index],
                  badge: 'TRENDING',
                  badgeColor: Colors.pink.shade500,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewArrivals() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final products = productProvider.products.take(6).toList();

        if (products.isEmpty) return const SizedBox.shrink();

        return _buildSection(
          title: 'New Arrivals',
          subtitle: 'Fresh additions to our collection',
          child: SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  products[index],
                  badge: 'NEW',
                  badgeColor: Colors.blue.shade500,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: ThyneTheme.textHeadingMd,
                        fontWeight: FontWeight.w600,
                        letterSpacing: ThyneTheme.trackingTight,
                        color: ThyneTheme.foreground,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: ThyneTheme.textBodySm,
                        color: ThyneTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: GoogleFonts.inter(
                          fontSize: ThyneTheme.textBodySm,
                          fontWeight: FontWeight.w500,
                          color: ThyneTheme.getModuleColor(selectedTab),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: ThyneTheme.getModuleColor(selectedTab),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Product product, {
    String? badge,
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        product.images.isNotEmpty
                            ? product.images.first
                            : 'https://via.placeholder.com/400',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Badge
                if (badge != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor ?? ThyneTheme.commerceGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: ThyneTheme.trackingWider,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Wishlist Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<WishlistProvider>(
                    builder: (context, wishlist, _) {
                      final isWishlisted = wishlist.isInWishlist(product.id);
                      return GestureDetector(
                        onTap: () {
                          wishlist.toggleWishlist(product.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            size: 14,
                            color: isWishlisted
                                ? ThyneTheme.communityRuby
                                : ThyneTheme.mutedForeground,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Rating
                if (product.rating > 0)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.star_fill,
                            size: 10,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Product Details
            const SizedBox(height: 8),
            Text(
              product.name,
              style: GoogleFonts.inter(
                fontSize: ThyneTheme.textFootnote,
                fontWeight: FontWeight.w500,
                color: ThyneTheme.foreground,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  CurrencyFormatter.format(product.price),
                  style: GoogleFonts.inter(
                    fontSize: ThyneTheme.textBodySm,
                    fontWeight: FontWeight.w600,
                    color: ThyneTheme.foreground,
                  ),
                ),
                if (product.originalPrice != null &&
                    product.originalPrice! > product.price) ...[
                  const SizedBox(width: 4),
                  Text(
                    CurrencyFormatter.format(product.originalPrice!),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: ThyneTheme.mutedForeground,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Add to Bag Button
            SizedBox(
              width: double.infinity,
              height: 32,
              child: Consumer<CartProvider>(
                builder: (context, cart, _) {
                  return ElevatedButton(
                    onPressed: () {
                      cart.addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to bag'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: ThyneTheme.commerceGreen,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThyneTheme.muted,
                      foregroundColor: ThyneTheme.foreground,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: ThyneTheme.border,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'Add to Bag',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: ThyneTheme.trackingWider,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      height: 400,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThyneTheme.getModuleColor(selectedTab).withOpacity(0.1),
            ThyneTheme.getModuleColor(selectedTab).withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.sparkles,
              size: 64,
              color: ThyneTheme.getModuleColor(selectedTab),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to Thyne Jewels',
              style: GoogleFonts.inter(
                fontSize: ThyneTheme.textHeadingLg,
                fontWeight: FontWeight.w600,
                color: ThyneTheme.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover our exclusive collection',
              style: GoogleFonts.inter(
                fontSize: ThyneTheme.textBody,
                color: ThyneTheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityContent() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: const CommunitySection(),
    );
  }

  Widget _buildCreateContent() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: const AiCreateSection(),
    );
  }

  Widget _buildSearchOverlay() {
    return Container(
      color: ThyneTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(CupertinoIcons.arrow_left),
                    onPressed: () => setState(() => isSearchOpen = false),
                  ),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search for products...',
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: ThyneTheme.textBody,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.mic),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Search Results
            Expanded(
              child: Center(
                child: Text(
                  'Start typing to search',
                  style: GoogleFonts.inter(
                    fontSize: ThyneTheme.textBody,
                    color: ThyneTheme.mutedForeground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}