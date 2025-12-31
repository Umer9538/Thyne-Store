import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/cart_provider.dart';
import '../../viewmodels/product_provider.dart';
import '../../viewmodels/wishlist_provider.dart';
import '../../viewmodels/recently_viewed_provider.dart';
import '../../../theme/thyne_theme.dart';
import '../../../data/models/product.dart';
import '../../../data/models/category.dart';
import '../../../data/models/collection.dart';
import '../../../data/services/api_service.dart';
import '../../../utils/currency_formatter.dart';
import '../../../constants/navigation_tabs.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/style_options.dart';
import '../product/product_detail_screen.dart';
import '../product/product_list_screen.dart';
import '../cart/cart_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../community/community_section_figma.dart';
import '../create/create_section.dart';
import '../collection/collection_detail_screen.dart';
import '../collection/collection_list_screen.dart';
import '../bundle/bundle_detail_screen.dart';
import '../community/create_post_screen.dart';

class ThyneHomeComplete extends StatefulWidget {
  const ThyneHomeComplete({Key? key}) : super(key: key);

  @override
  State<ThyneHomeComplete> createState() => _ThyneHomeCompleteState();
}

class _ThyneHomeCompleteState extends State<ThyneHomeComplete> with TickerProviderStateMixin {
  // Navigation State - using string values from NavigationTab enum
  String selectedTab = NavigationTab.shop.value;
  String selectedFilter = ShopFilter.all.value;
  int currentCarouselIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // Shop By toggle state (true = price, false = style)
  bool _shopByPrice = true;

  // Dynamic Content Data
  List<dynamic> _banners = [];
  List<dynamic> _flashSales = [];
  Map<String, dynamic>? _dealOfDay; // Single deal with product
  List<dynamic> _bundles = [];
  List<dynamic> _showcases = [];
  List<Category> _categories = [];
  List<Collection> _collections = [];
  bool _isLoadingContent = false;
  bool _isLoadingCollections = false;

  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDynamicContent();
    // Defer product loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
      _loadRecentlyViewed();
    });
  }

  Future<void> _loadRecentlyViewed() async {
    final recentlyViewedProvider = context.read<RecentlyViewedProvider>();
    await recentlyViewedProvider.loadRecentlyViewed();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  Future<void> _loadDynamicContent() async {
    setState(() => _isLoadingContent = true);

    try {
      final results = await Future.wait([
        ApiService.getActiveBanners().catchError((_) => {'data': []}),
        ApiService.getFlashSales().catchError((_) => {'data': []}),
        ApiService.getDealsOfDay().catchError((_) => {'data': []}),
        ApiService.getBundleDeals().catchError((_) => {'data': []}),
        ApiService.getShowcases().catchError((_) => {'data': []}),
        ApiService.getCategories().catchError((_) => {'data': []}),
        ApiService.getCollections().catchError((_) => {'data': []}),
      ]);

      setState(() {
        // Transform API banners to match expected format and filter only live ones
        final apiBanners = results[0]['data'] as List<dynamic>? ?? [];
        final transformedBanners = apiBanners
            .map((banner) => _transformBanner(banner))
            .where((banner) => banner['isLive'] == true)
            .toList();
        _banners = transformedBanners.isNotEmpty
            ? transformedBanners
            : _getDefaultBanners();
        debugPrint('🎯 Banners loaded: ${apiBanners.length} from API, ${transformedBanners.length} live, displaying ${_banners.length}');
        _flashSales = results[1]['data'] ?? [];
        // Deal of day is a single object, not a list
        _dealOfDay = results[2]['data'] as Map<String, dynamic>?;
        _bundles = results[3]['data'] ?? [];
        _showcases = results[4]['data'] ?? [];

        // Parse categories
        final categoriesData = results[5]['data'] as List<dynamic>? ?? [];
        _categories = categoriesData
            .map((cat) => Category.fromJson(cat as Map<String, dynamic>))
            .where((cat) => cat.isActive)
            .toList();

        // Use default categories if API returns empty
        if (_categories.isEmpty) {
          _categories = _getDefaultCategories();
        }

        // Parse collections
        final collectionsData = results[6]['data'] as List<dynamic>? ?? [];
        _collections = collectionsData
            .map((col) => Collection.fromJson(col as Map<String, dynamic>))
            .toList();

        // Use default collections if API returns empty
        if (_collections.isEmpty) {
          _collections = _getDefaultCollections();
        }

        // Debug logging
        debugPrint('📦 Loaded ${_categories.length} categories');
        debugPrint('🎁 Loaded ${_collections.length} collections');
        debugPrint('🔥 Loaded ${_flashSales.length} flash sales');
        debugPrint('Flash sales data: $_flashSales');
        for (var cat in _categories) {
          debugPrint('  - ${cat.name} (${cat.slug}) - Gender: ${cat.gender}');
        }

        _isLoadingContent = false;
      });
    } catch (e) {
      setState(() {
        _banners = _getDefaultBanners();
        _categories = _getDefaultCategories();
        _collections = _getDefaultCollections();
        _isLoadingContent = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    final productProvider = context.read<ProductProvider>();
    await productProvider.loadProducts();
    await productProvider.loadFeaturedProducts();
  }

  List<Map<String, String>> _getDefaultBanners() {
    return [
      {
        'imageUrl': 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800',
        'title': 'Begin Your Bridal\nJourney',
        'subtitle': 'Exquisite bridal jewelry with Khazana\nAcross India & Middle East',
        'ctaText': 'EXPLORE BRIDAL',
      },
      {
        'imageUrl': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800',
        'title': 'Luxury Collection',
        'subtitle': 'Discover our premium range',
        'ctaText': 'SHOP NOW',
      },
      {
        'imageUrl': 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=800',
        'title': 'New Arrivals',
        'subtitle': 'Latest designs just for you',
        'ctaText': 'VIEW COLLECTION',
      },
    ];
  }

  /// Transform API banner data to match expected format for display
  Map<String, dynamic> _transformBanner(dynamic banner) {
    if (banner is! Map) return {};

    // Check if banner is active and within date range
    final now = DateTime.now();
    final startDate = banner['startDate'] != null
        ? DateTime.tryParse(banner['startDate'].toString())
        : null;
    final endDate = banner['endDate'] != null
        ? DateTime.tryParse(banner['endDate'].toString())
        : null;

    final isActive = banner['isActive'] == true;
    final isLive = isActive &&
        (startDate == null || now.isAfter(startDate)) &&
        (endDate == null || now.isBefore(endDate));

    if (!isLive) {
      debugPrint('⚠️ Banner "${banner['title']}" is not live (isActive: $isActive, startDate: $startDate, endDate: $endDate)');
    }

    return {
      'id': banner['id']?.toString() ?? banner['_id']?.toString() ?? '',
      'imageUrl': banner['imageUrl']?.toString() ?? '',
      'title': banner['title']?.toString() ?? '',
      'subtitle': banner['subtitle']?.toString() ??
                  banner['description']?.toString() ?? '',  // Fallback to description
      'ctaText': banner['ctaText']?.toString() ??
                 banner['buttonText']?.toString() ?? 'SHOP NOW',  // Default CTA
      'targetUrl': banner['targetUrl']?.toString() ?? '',
      'targetCategory': banner['targetCategory']?.toString() ?? '',
      'targetProductId': banner['targetProductId']?.toString() ?? '',
      'type': banner['type']?.toString() ?? 'main',
      'isLive': isLive,
    };
  }

  List<Category> _getDefaultCategories() {
    return [
      Category(
        id: '1',
        name: 'Rings',
        slug: 'rings',
        description: 'Beautiful rings collection',
        image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=400',
        gender: ['women', 'men'],
      ),
      Category(
        id: '2',
        name: 'Earrings',
        slug: 'earrings',
        description: 'Elegant earrings',
        image: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400',
        gender: ['women'],
      ),
      Category(
        id: '3',
        name: 'Bracelets & Bangles',
        slug: 'bracelets',
        description: 'Stunning bracelets',
        image: 'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=400',
        gender: ['women', 'men'],
      ),
      Category(
        id: '4',
        name: 'Solitaires',
        slug: 'solitaires',
        description: 'Premium solitaires',
        image: 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=400',
        gender: ['women'],
      ),
      Category(
        id: '5',
        name: '22KT',
        slug: '22kt',
        description: '22 Karat gold jewelry',
        image: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400',
        gender: ['women', 'men'],
      ),
      Category(
        id: '6',
        name: 'Silver by Shaya',
        slug: 'silver',
        description: 'Silver collection',
        image: 'https://images.unsplash.com/photo-1603561591411-07134e71a2a9?w=400',
        gender: ['women', 'men'],
      ),
      Category(
        id: '7',
        name: 'Mangalsutra',
        slug: 'mangalsutra',
        description: 'Traditional mangalsutras',
        image: 'https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=400',
        gender: ['women'],
      ),
      Category(
        id: '8',
        name: 'Necklaces',
        slug: 'necklaces',
        description: 'Beautiful necklaces',
        image: 'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?w=400',
        gender: ['women'],
      ),
    ];
  }

  List<Collection> _getDefaultCollections() {
    return [
      Collection(
        id: 'heritage-gold',
        title: 'Heritage Gold',
        subtitle: 'Timeless pieces crafted with tradition',
        description: 'Timeless pieces crafted with tradition',
        imageUrls: ['https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800'],
        isFeatured: true,
      ),
      Collection(
        id: 'executive-collection',
        title: 'Executive Collection',
        subtitle: 'Refined pieces for the modern man',
        description: 'Refined pieces for the modern man',
        imageUrls: ['https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=800'],
        isFeatured: false,
      ),
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      body: Stack(
        children: [
          if (selectedTab == 'shop')
            _buildShopContent()
          else if (selectedTab == 'community')
            _buildCommunityContent()
          else if (selectedTab == 'create')
            _buildCreateContent(),

          // Floating Search Bar (not shown on create tab)
          if (selectedTab != 'create')
            Positioned(
              bottom: 80 + bottomPadding, // Account for bottom nav + safe area
              left: 20,
              right: 20,
              child: _buildFloatingSearchBar(),
            ),

          // Bottom Navigation (Always visible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildShopContent() {
    return Column(
      children: [
        // App Bar
        _buildAppBar(),
        // Filter Pills
        _buildFilterPills(),
        // Main Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDynamicContent,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: selectedFilter == 'all'
                    ? _buildAllFilterContent()
                    : _buildCategoryFilterContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllFilterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Carousel
        _buildHeroCarousel(),

        // Flash Sales Section
        if (_flashSales.isNotEmpty) _buildFlashSalesSection(),

        // Shop by Category
        _buildShopByCategory(),

        // Handpicked Products
        _buildHandpickedSection(),

        // Trending Now
        _buildTrendingSection(),

        // New Arrivals
        _buildNewArrivalsSection(),

        // Bundle Deals
        if (_bundles.isNotEmpty) _buildBundleSection(),

        // Deals of the Day
        if (_dealOfDay != null) _buildDealOfDaySection(),

        // Collections
        _buildCollectionsSection(),

        // 360° Showcases
        if (_showcases.isNotEmpty) _build360ShowcaseSection(),

        // Recently Viewed
        _buildRecentlyViewedSection(),

        // Footer Space
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCategoryFilterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Top Categories
        _buildTopCategories(),

        const SizedBox(height: 24),
        // Trending Section
        _buildTrendingProductsGrid(),

        const SizedBox(height: 24),
        // Shop By Price
        _buildShopByPrice(),

        const SizedBox(height: 24),
        // More Categories
        _buildMoreCategories(),

        const SizedBox(height: 24),
        // Collection Banner
        _buildCollectionBanner(),

        // Footer Space
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildCommunityContent() {
    return const CommunitySectionFigma();
  }

  Widget _buildCreateContent() {
    return Column(
      children: [
        // App Bar
        _buildAppBar(),
        // AI Create Section Content
        const Expanded(
          child: CreateSection(),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
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
                  Text(
                    'THYNE',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  // User Avatar
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return GestureDetector(
                        onTap: () {
                          if (auth.isAuthenticated) {
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
                          child: Center(
                            child: Text(
                              auth.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
                    size: 15,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final address = authProvider.user?.defaultAddress;
                        String deliveryLocation = 'Set Location';
                        if (address != null) {
                          // Use shortAddress for compact display, fallback to city
                          if (address.shortAddress.isNotEmpty) {
                            deliveryLocation = address.shortAddress;
                          } else if (address.city.isNotEmpty) {
                            deliveryLocation = address.city;
                          }
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'deliver to ',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF666666),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Flexible(
                              child: Text(
                                deliveryLocation,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Gift Icon - Loyalty/Rewards
                  _buildIconButton(
                    CupertinoIcons.gift,
                    () => Navigator.pushNamed(context, '/loyalty'),
                  ),
                  const SizedBox(width: 16),
                  // Heart Icon
                  Consumer<WishlistProvider>(
                    builder: (context, wishlist, _) {
                      return _buildIconButton(
                        CupertinoIcons.heart,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WishlistScreen()),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  // Shopping Bag Icon with Badge - aligned with profile avatar (40px width)
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildIconButton(
                                CupertinoIcons.bag,
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                ),
                              ),
                              if (cart.items.isNotEmpty)
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1A1A1A),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${cart.items.length}',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 22,
        color: const Color(0xFF666666),
      ),
    );
  }

  Widget _buildFilterPills() {
    final filters = ['all', 'women', 'men', 'inclusive'];

    return Container(
      height: 56,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B9A7D)
                      : const Color(0xFFF5F5F0),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B9A7D)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCarousel() {
    final banners = _banners.isEmpty ? _getDefaultBanners() : _banners;

    return Container(
      height: 520,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          carousel.CarouselSlider(
            options: carousel.CarouselOptions(
              height: 520,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (index, reason) {
                setState(() {
                  currentCarouselIndex = index;
                });
              },
            ),
            items: banners.map((banner) {
              final imageUrl = banner['imageUrl']?.toString() ?? '';
              final isValidImageUrl = imageUrl.isNotEmpty &&
                  (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) &&
                  !imageUrl.contains('unsplash.com/photos/'); // Block page URLs

              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image with error handling
                    if (isValidImageUrl)
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF2A2A2A),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint('❌ Banner image error: $error for URL: $url');
                          return Container(
                            color: const Color(0xFF2A2A2A),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.white38,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: const Color(0xFF2A2A2A),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white38,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Invalid image URL',
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.75),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    // Text content overlay
                    Positioned(
                      left: 32,
                      right: 32,
                      bottom: 32,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            banner['title']?.toString() ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            banner['subtitle']?.toString() ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.95),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate based on targetUrl or targetCategory
                              final targetUrl = banner['targetUrl']?.toString();
                              if (targetUrl != null && targetUrl.isNotEmpty) {
                                // Handle navigation
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A1A1A),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  banner['ctaText']?.toString() ?? 'SHOP NOW',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A1A),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  CupertinoIcons.arrow_right,
                                  size: 16,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          // Carousel Indicators
          Positioned(
            bottom: 120,
            left: 32,
            child: Row(
              children: List.generate(
                banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: index == currentCarouselIndex ? 28 : 8,
                  height: 4,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: index == currentCarouselIndex
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          // Page Counter
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentCarouselIndex + 1} / ${banners.length}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashSalesSection() {
    // Get the first flash sale's time remaining for subtitle
    String subtitle = 'Limited time offer';
    if (_flashSales.isNotEmpty) {
      final firstSale = _flashSales.first;
      final endTime = DateTime.tryParse(firstSale['endTime']?.toString() ?? '');
      if (endTime != null) {
        final remaining = endTime.difference(DateTime.now());
        if (remaining.isNegative) {
          subtitle = 'Sale ended';
        } else {
          final hours = remaining.inHours;
          final minutes = remaining.inMinutes % 60;
          subtitle = 'Ending in ${hours}h ${minutes}m';
        }
      }
    }

    // Collect all products from all flash sales
    final List<Map<String, dynamic>> flashSaleProducts = [];
    for (final sale in _flashSales) {
      final products = sale['products'] as List<dynamic>? ?? [];
      final discount = sale['discount'] ?? 0;
      for (final productData in products) {
        flashSaleProducts.add({
          'product': productData['product'],
          'originalPrice': productData['originalPrice'],
          'salePrice': productData['salePrice'],
          'discount': productData['discount'] ?? discount,
        });
      }
    }

    if (flashSaleProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Flash Sales ⚡',
      subtitle: subtitle,
      child: SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: flashSaleProducts.length,
          itemBuilder: (context, index) {
            final item = flashSaleProducts[index];
            final productJson = item['product'] as Map<String, dynamic>? ?? {};
            final product = Product.fromJson(productJson);
            final salePrice = (item['salePrice'] as num?)?.toDouble() ?? product.price;
            final originalPrice = (item['originalPrice'] as num?)?.toDouble() ?? product.price;
            final discount = item['discount'] as int? ?? 0;

            return _buildFlashSaleProductCard(
              product: product,
              salePrice: salePrice,
              originalPrice: originalPrice,
              discount: discount,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlashSaleProductCard({
    required Product product,
    required double salePrice,
    required double originalPrice,
    required int discount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: product,
              salePrice: salePrice,
              originalPrice: originalPrice,
              discountPercent: discount,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badge
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: const Color(0xFFF8F4F0),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                          ),
                  ),
                ),
                // Discount badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$discount% OFF',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Wishlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price with strikethrough for original
                    Row(
                      children: [
                        Text(
                          '₹${salePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '₹${originalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopByCategory() {
    final categories = [
      {'name': 'Rings', 'image': 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=200'},
      {'name': 'Necklaces', 'image': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=200'},
      {'name': 'Earrings', 'image': 'https://images.unsplash.com/photo-1535632787350-4e68ef0ac584?w=200'},
      {'name': 'Bracelets', 'image': 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=200'},
    ];

    return _buildSection(
      title: 'Shop by Category',
      subtitle: 'Find what you\'re looking for',
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                // Navigate to product list screen filtered by category
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductListScreen(
                      category: category['name']!.toLowerCase(),
                    ),
                  ),
                );
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(category['image']!),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 100,
                      child: Text(
                        category['name']!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildHandpickedSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final products = provider.featuredProducts.take(4).toList();
        if (products.isEmpty) return const SizedBox.shrink();

        return _buildSection(
          title: 'Handpicked for You',
          subtitle: 'Curated collection',
          viewAllAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductListScreen(),
              ),
            );
          },
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
                  badgeColor: const Color(0xFF094010),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendingSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final products = provider.products
            .where((p) => p.rating > 4.5)
            .take(4)
            .toList();

        if (products.isEmpty) return const SizedBox.shrink();

        return _buildSection(
          title: 'Trending Now 🔥',
          subtitle: 'Most loved by customers',
          viewAllAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductListScreen(),
              ),
            );
          },
          child: SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  products[index],
                  badge: '#${index + 1} Trending',
                  badgeColor: Colors.orange,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewArrivalsSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final products = provider.products.take(4).toList();
        if (products.isEmpty) return const SizedBox.shrink();

        return _buildSection(
          title: 'New Arrivals ✨',
          subtitle: 'Fresh additions',
          viewAllAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductListScreen(),
              ),
            );
          },
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
                  badgeColor: Colors.blue,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBundleSection() {
    return _buildSection(
      title: 'Bundle Deals 🎁',
      subtitle: 'Save more with sets',
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _bundles.length,
          itemBuilder: (context, index) {
            final bundle = _bundles[index] as Map<String, dynamic>;
            return _buildBundleCard(bundle);
          },
        ),
      ),
    );
  }

  Widget _buildBundleCard(Map<String, dynamic> bundle) {
    final title = bundle['title'] ?? 'Bundle Deal';
    final description = bundle['description'] ?? '';
    final bundlePrice = (bundle['bundlePrice'] ?? 0).toDouble();
    final originalPrice = (bundle['originalPrice'] ?? bundlePrice).toDouble();
    final items = bundle['items'] as List<dynamic>? ?? [];
    final discountPercent = originalPrice > 0
        ? ((originalPrice - bundlePrice) / originalPrice * 100).round()
        : 0;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF094010).withOpacity(0.1),
            const Color(0xFF094010).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF094010).withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.gift_fill,
                  color: Color(0xFF094010),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                description.isNotEmpty ? description : '${items.length} items in this bundle',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF666666),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${bundlePrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF094010),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (originalPrice > bundlePrice)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '₹${originalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                  color: const Color(0xFF999999),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Save $discountPercent%',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BundleDetailScreen(bundle: bundle),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF094010),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'View Bundle',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealOfDaySection() {
    if (_dealOfDay == null) return const SizedBox.shrink();

    final deal = _dealOfDay!;
    final productJson = deal['product'] as Map<String, dynamic>? ?? {};
    final product = Product.fromJson(productJson);
    final dealPrice = (deal['dealPrice'] as num?)?.toDouble() ?? product.price;
    final originalPrice = (deal['originalPrice'] as num?)?.toDouble() ?? product.price;
    final discountPercent = deal['discountPercent'] as int? ?? 0;

    // Calculate time remaining
    String subtitle = 'Limited time offer';
    final endTimeStr = deal['endTime']?.toString();
    if (endTimeStr != null) {
      final endTime = DateTime.tryParse(endTimeStr);
      if (endTime != null) {
        final remaining = endTime.difference(DateTime.now());
        if (remaining.isNegative) {
          subtitle = 'Deal ended';
        } else {
          final hours = remaining.inHours;
          final minutes = remaining.inMinutes % 60;
          subtitle = 'Ends in ${hours}h ${minutes}m';
        }
      }
    }

    return _buildSection(
      title: 'Deal of the Day 🔥',
      subtitle: subtitle,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: product,
                salePrice: dealPrice,
                originalPrice: originalPrice,
                discountPercent: discountPercent,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: Stack(
                  children: [
                    Container(
                      width: 150,
                      height: 180,
                      color: const Color(0xFFF8F4F0),
                      child: product.images.isNotEmpty
                          ? Image.network(
                              product.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                            ),
                    ),
                    // Discount badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$discountPercent% OFF',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DEAL OF THE DAY',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '₹${dealPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${originalPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  product: product,
                                  salePrice: dealPrice,
                                  originalPrice: originalPrice,
                                  discountPercent: discountPercent,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF094010),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Shop Now'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionsSection() {
    // Default collections for fallback when API returns empty
    final defaultCollections = [
      Collection(
        id: 'default_gold',
        title: 'Gold Collection',
        subtitle: 'Timeless elegance',
        imageUrls: ['https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800'],
        itemCount: 124,
        isFeatured: true,
      ),
      Collection(
        id: 'default_diamond',
        title: 'Diamond Collection',
        subtitle: 'Brilliance redefined',
        imageUrls: ['https://images.unsplash.com/photo-1601121141461-9d6647bca1ed?w=800'],
        itemCount: 89,
        isFeatured: true,
      ),
      Collection(
        id: 'default_pearl',
        title: 'Pearl Collection',
        subtitle: 'Classic sophistication',
        imageUrls: ['https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=800'],
        itemCount: 56,
        isFeatured: false,
      ),
    ];

    // Use API collections if available, otherwise use defaults
    final displayCollections = _collections.isNotEmpty ? _collections : defaultCollections;

    return _buildSection(
      title: 'Exclusive Collections',
      subtitle: 'Curated with love',
      viewAllAction: () {
        // Navigate to all collections screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollectionListScreen(collections: displayCollections),
          ),
        );
      },
      child: SizedBox(
        height: 200,
        child: _isLoadingCollections
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayCollections.length,
                itemBuilder: (context, index) {
                  final collection = displayCollections[index];
                  return GestureDetector(
                    onTap: () => _navigateToCollectionDetail(collection),
                    child: Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background Image
                            CachedNetworkImage(
                              imageUrl: collection.primaryImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 40),
                              ),
                            ),
                            // Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Featured Badge
                                  if (collection.isFeatured)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: ThyneTheme.commerceGreen,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'FEATURED',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  // Collection Title
                                  Text(
                                    collection.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // Item Count
                                  Text(
                                    collection.itemCountLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
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
    );
  }

  void _navigateToCollectionDetail(Collection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionDetailScreen(collection: collection),
      ),
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

  Widget _build360ShowcaseSection() {
    return _buildSection(
      title: '360° Product View',
      subtitle: 'Interactive experience',
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 160,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: _buildShowcaseImage(showcase),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 176,
                            child: Text(
                              showcase['title'] ?? 'View in 360°',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 176,
                            child: Text(
                              'Tap to interact',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF666666),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShowcaseImage(Map<String, dynamic> showcase) {
    // Get the first image from images360 array
    final images360 = showcase['images360'] as List<dynamic>?;
    final thumbnailUrl = showcase['thumbnailUrl'] as String?;

    // Use thumbnail if available, otherwise use first image from images360
    String? imageUrl;
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      imageUrl = thumbnailUrl;
    } else if (images360 != null && images360.isNotEmpty) {
      imageUrl = images360.first as String?;
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      // Fallback to placeholder icon if no images
      return Stack(
        fit: StackFit.expand,
        children: [
          const Center(
            child: Icon(
              Icons.threed_rotation,
              size: 48,
              color: Color(0xFF094010),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rotate_right, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('360°', style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.threed_rotation,
                size: 48,
                color: Color(0xFF094010),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: const Color(0xFF094010),
              ),
            );
          },
        ),
        // 360° badge overlay
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rotate_right, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text('360°', style: TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyViewedSection() {
    return Consumer<RecentlyViewedProvider>(
      builder: (context, provider, _) {
        final products = provider.recentlyViewed;

        return _buildSection(
          title: 'Recently Viewed',
          subtitle: 'Your browsing history',
          child: SizedBox(
            height: products.isEmpty ? 100 : 280,
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No recently viewed items',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Products you view will appear here',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(products[index]);
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
    VoidCallback? viewAllAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 48, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (viewAllAction != null)
                  TextButton(
                    onPressed: viewAllAction,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.arrow_right,
                          size: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, {String? badge, Color? badgeColor}) {
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
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image with Badges
            Stack(
              children: [
                Container(
                  height: 170,
                  width: 180,
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
                if (badge != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFF094010),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<WishlistProvider>(
                    builder: (context, wishlist, _) {
                      final isWishlisted = wishlist.isInWishlist(product.id);
                      return GestureDetector(
                        onTap: () => wishlist.toggleWishlist(product.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            size: 16,
                            color: isWishlisted ? Colors.red : const Color(0xFF666666),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Product Name
            SizedBox(
              width: 180,
              child: Text(
                product.name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            // Price Row
            SizedBox(
              width: 180,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      CurrencyFormatter.format(product.price),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.originalPrice != null) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        CurrencyFormatter.format(product.originalPrice!),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                          color: const Color(0xFF999999),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Rating Row
            if (product.rating > 0)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: SizedBox(
                  width: 180,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < product.rating.floor()
                              ? CupertinoIcons.star_fill
                              : CupertinoIcons.star,
                          size: 10,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${product.rating}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF666666),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 3),
            // Add to Cart Button
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                return SizedBox(
                  width: 180,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () {
                      cart.addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'VIEW CART',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF094010),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(CupertinoIcons.bag, 'Shop', 'shop'),
              _buildNavItem(CupertinoIcons.person_2, 'Community', 'community'),
              _buildNavItem(CupertinoIcons.sparkles, 'Create', 'create'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String tab) {
    final isActive = selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = tab),
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive ? const Color(0xFF094010) : const Color(0xFF999999),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? const Color(0xFF094010) : const Color(0xFF999999),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Green circular button with plus icon - Create Post
          GestureDetector(
            onTap: () {
              _navigateToCreatePost();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF094010),
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
                _showSearchModal(context);
              },
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.search,
                      size: 20,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ask me anything',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.mic,
                      size: 20,
                      color: Color(0xFF666666),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';
    List<Product> searchResults = [];
    List<Collection> collectionResults = [];
    bool isSearching = false;

    // Recent searches - In a real app, load from SharedPreferences
    final List<String> recentSearches = [
      'Gold Rings',
      'Anniversary Gifts',
      'Diamond Necklace',
    ];

    // Trending searches
    final List<String> trendingSearches = [
      'Wedding Bands',
      'Rose Gold',
      'Minimalist Jewelry',
      'Vintage Collection',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final screenHeight = MediaQuery.of(context).size.height;
            final productProvider = Provider.of<ProductProvider>(context, listen: false);

            // Function to perform search
            void performSearch(String query) {
              if (query.isEmpty) {
                setModalState(() {
                  searchQuery = '';
                  searchResults = [];
                  collectionResults = [];
                  isSearching = false;
                });
                return;
              }

              setModalState(() {
                searchQuery = query;
                isSearching = true;
              });

              final queryLower = query.toLowerCase();
              final allProducts = productProvider.products;

              // Prioritize products that START with the query, then those that contain it
              final startsWithProducts = allProducts.where((p) {
                final nameLower = p.name.toLowerCase();
                return nameLower.startsWith(queryLower);
              }).toList();

              final containsProducts = allProducts.where((p) {
                final nameLower = p.name.toLowerCase();
                final categoryLower = p.category.toLowerCase();
                // Exclude already matched "starts with" products
                return !nameLower.startsWith(queryLower) &&
                       (nameLower.contains(queryLower) || categoryLower.contains(queryLower));
              }).toList();

              // Combine: starts with first, then contains
              final filtered = [...startsWithProducts, ...containsProducts].take(6).toList();

              // Filter collections - prioritize starts with
              final allCollections = _collections;
              final startsWithCollections = allCollections.where((c) {
                final titleLower = c.title.toLowerCase();
                return titleLower.startsWith(queryLower);
              }).toList();

              final containsCollections = allCollections.where((c) {
                final titleLower = c.title.toLowerCase();
                final descLower = c.description.toLowerCase();
                return !titleLower.startsWith(queryLower) &&
                       (titleLower.contains(queryLower) || descLower.contains(queryLower));
              }).toList();

              final filteredCollections = [...startsWithCollections, ...containsCollections].take(3).toList();

              setModalState(() {
                searchResults = filtered;
                collectionResults = filteredCollections;
                isSearching = false;
              });
            }

            // Build search results content
            Widget buildSearchResults() {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                      child: Row(
                        children: [
                          Text(
                            'SHOP',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Products Section
                    if (searchResults.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: Text(
                          'PRODUCTS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final product = searchResults[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image with Wishlist
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                          child: CachedNetworkImage(
                                            imageUrl: product.images.isNotEmpty ? product.images.first : '',
                                            height: 100,
                                            width: 120,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: Colors.grey[200],
                                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image_not_supported),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.favorite_border,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹${product.price.toStringAsFixed(0)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Collections Section
                    if (collectionResults.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Text(
                          'COLLECTIONS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...collectionResults.map((collection) => GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductListScreen(category: collection.id),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              // Collection images preview
                              SizedBox(
                                width: 80,
                                height: 50,
                                child: Stack(
                                  children: [
                                    if (collection.imageUrls.isNotEmpty)
                                      Positioned(
                                        left: 0,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: CachedNetworkImage(
                                            imageUrl: collection.imageUrls.first,
                                            width: 40,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    if (collection.imageUrls.length > 1)
                                      Positioned(
                                        left: 25,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: CachedNetworkImage(
                                            imageUrl: collection.imageUrls[1],
                                            width: 40,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      collection.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      collection.description,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],

                    // No results
                    if (searchResults.isEmpty && collectionResults.isEmpty && searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'No results found for "$searchQuery"',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              );
            }

            // Build default content (recent + trending)
            Widget buildDefaultContent() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                    child: Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'RECENT SEARCHES',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Recent Searches Chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentSearches.map((search) {
                          return GestureDetector(
                            onTap: () {
                              searchController.text = search;
                              performSearch(search);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E8E0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                search,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3D3D3D),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Trending Now Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TRENDING NOW',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Trending Searches Chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: trendingSearches.map((search) {
                          return GestureDetector(
                            onTap: () {
                              searchController.text = search;
                              performSearch(search);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E8E0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                search,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3D3D3D),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Empty state / hint
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 36,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Start typing to search across shop,',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                        Text(
                          'community, and AI...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main card content
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: searchQuery.isEmpty ? buildDefaultContent() : buildSearchResults(),
                ),

                // Search bar area - matches the floating search bar position
                Container(
                  padding: EdgeInsets.fromLTRB(4, 16, 16, bottomPadding + 70),
                  child: Row(
                    children: [
                      // Green circular button with plus icon (same as original)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          // Add action for plus button
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFF094010),
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
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.search,
                                size: 20,
                                color: Color(0xFF666666),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  autofocus: false,
                                  decoration: InputDecoration(
                                    hintText: 'ask me anything',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF999999),
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                  onChanged: performSearch,
                                  onSubmitted: (query) {
                                    if (query.trim().isNotEmpty) {
                                      Navigator.pop(context);
                                      _navigateToSearchResults(query);
                                    }
                                  },
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.mic,
                                size: 20,
                                color: Color(0xFF666666),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToSearchResults(String query) {
    // Navigate to product list with search query
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          searchQuery: query,
        ),
      ),
    );
  }

  Widget _buildTopCategories() {
    // Filter categories based on selected gender filter
    final filteredCategories = _categories.where((category) {
      if (selectedFilter == 'all') return true;
      // If category has no gender specified, show for all filters
      if (category.gender.isEmpty) return true;
      // Case-insensitive check
      return category.gender.any((g) => g.toLowerCase() == selectedFilter.toLowerCase());
    }).toList();

    debugPrint('🔍 Filter: $selectedFilter, Total categories: ${_categories.length}, Filtered: ${filteredCategories.length}');

    // If no filtered categories, show all categories
    final categoriesToShow = filteredCategories.isNotEmpty ? filteredCategories : _categories;

    if (categoriesToShow.isEmpty) {
      debugPrint('⚠️ No categories found');
      return const SizedBox();
    }

    // Show first 2 categories
    final topCategories = categoriesToShow.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categories',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          if (topCategories.length >= 2)
            Row(
              children: [
                Expanded(
                  child: _buildCategoryCard(
                    topCategories[0],
                    true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryCard(
                    topCategories[1],
                    false,
                  ),
                ),
              ],
            )
          else if (topCategories.length == 1)
            _buildCategoryCard(topCategories[0], false),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category, bool hasDropdown) {
    // Get icon for category (could be from category.image or default emoji)
    final icon = _getCategoryIcon(category.name);

    return GestureDetector(
      onTap: () {
        // Navigate to product list filtered by this category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductListScreen(
              category: category.slug,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: category.image.isNotEmpty && category.image.startsWith('http')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: category.image,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Center(
                          child: Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
            Icon(
              hasDropdown ? Icons.keyboard_arrow_down : Icons.chevron_right,
              size: 20,
              color: const Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('ring')) return '💍';
    if (name.contains('necklace')) return '📿';
    if (name.contains('earring')) return '👂';
    if (name.contains('bracelet')) return '⌚';
    if (name.contains('bangle')) return '📿';
    if (name.contains('solitaire')) return '💎';
    if (name.contains('pendant')) return '🔮';
    return '💎'; // Default icon
  }

  Widget _buildTrendingProductsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              final products = productProvider.products.take(6).toList();
              if (products.isEmpty) {
                return const SizedBox();
              }
              return SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildTrendingProductCard(products[index]);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingProductCard(Product product) {
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
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 100,
                width: 120,
                child: CachedNetworkImage(
                  imageUrl: product.images.isNotEmpty
                      ? product.images[0]
                      : 'https://via.placeholder.com/200',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF5F5F0),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF5F5F0),
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopByPrice() {
    // Use style options from constants (first 6 for compact display)
    final displayStyles = ProductStyles.all.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Shop By Style Button
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _shopByPrice = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_shopByPrice ? const Color(0xFF094010) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_shopByPrice ? const Color(0xFF094010) : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Shop By Style',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: !_shopByPrice ? Colors.white : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Shop By Price Button
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _shopByPrice = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _shopByPrice ? const Color(0xFF094010) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _shopByPrice ? const Color(0xFF094010) : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Shop By Price ( ₹ )',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _shopByPrice ? Colors.white : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Show Price chips or Style chips based on selection
          if (_shopByPrice)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: [
                _buildPriceRangeChip('Under 10K', minPrice: 0, maxPrice: 10000),
                _buildPriceRangeChip('10K - 20K', minPrice: 10000, maxPrice: 20000),
                _buildPriceRangeChip('20K - 30K', minPrice: 20000, maxPrice: 30000),
                _buildPriceRangeChip('30K - 50K', minPrice: 30000, maxPrice: 50000),
                _buildPriceRangeChip('50K - 75K', minPrice: 50000, maxPrice: 75000),
                _buildPriceRangeChip('75K & Above', minPrice: 75000, maxPrice: null),
              ],
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: displayStyles.map((style) => _buildStyleChip(style.name, style.slug)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStyleChip(String label, String slug) {
    return GestureDetector(
      onTap: () {
        // Navigate to product list with style tag filter
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductListScreen(
              styleTag: slug,  // Use styleTag for filtering by product tags
              gender: selectedFilter == 'all' ? null : selectedFilter,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRangeChip(String label, {required int minPrice, int? maxPrice}) {
    return GestureDetector(
      onTap: () {
        // Navigate to product list with price filter
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductListScreen(
              minPrice: minPrice,
              maxPrice: maxPrice,
              gender: selectedFilter == 'all' ? null : selectedFilter,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreCategories() {
    // Filter categories based on selected gender filter
    final filteredCategories = _categories.where((category) {
      if (selectedFilter == 'all') return true;
      // If category has no gender specified, show for all filters
      if (category.gender.isEmpty) return true;
      // Case-insensitive check
      return category.gender.any((g) => g.toLowerCase() == selectedFilter.toLowerCase());
    }).toList();

    // If no filtered categories, show all categories
    final categoriesToShow = filteredCategories.isNotEmpty ? filteredCategories : _categories;

    // Skip first 2 categories (already shown in Top Categories)
    final moreCategories = categoriesToShow.skip(2).toList();

    if (moreCategories.isEmpty) {
      return const SizedBox();
    }

    // Create pairs for 2-column grid
    final List<List<Category>> categoryPairs = [];
    for (int i = 0; i < moreCategories.length; i += 2) {
      if (i + 1 < moreCategories.length) {
        categoryPairs.add([moreCategories[i], moreCategories[i + 1]]);
      } else {
        categoryPairs.add([moreCategories[i]]);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: categoryPairs.map((pair) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: _buildMoreCategoryCard(pair[0])),
                const SizedBox(width: 12),
                if (pair.length > 1)
                  Expanded(child: _buildMoreCategoryCard(pair[1]))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMoreCategoryCard(Category category) {
    final icon = _getCategoryIcon(category.name);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductListScreen(
              category: category.slug,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: category.image.isNotEmpty && category.image.startsWith('http')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: category.image,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Center(
                          child: Text(icon, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(icon, style: const TextStyle(fontSize: 16)),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionBanner() {
    // Get featured collection or first collection
    final featuredCollection = _collections.isNotEmpty
        ? _collections.firstWhere(
            (c) => c.isFeatured,
            orElse: () => _collections.first,
          )
        : null;

    if (featuredCollection == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductListScreen(category: featuredCollection.id),
            ),
          );
        },
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                featuredCollection.primaryImageUrl,
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  featuredCollection.title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  featuredCollection.subtitle.isNotEmpty
                      ? featuredCollection.subtitle
                      : featuredCollection.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.white,
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
}