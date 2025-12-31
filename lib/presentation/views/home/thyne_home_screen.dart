import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'dart:ui';

// Providers and models
import '../viewmodels/auth_provider.dart';
import '../viewmodels/cart_provider.dart';
import '../viewmodels/wishlist_provider.dart';
import '../viewmodels/product_provider.dart';
import '../viewmodels/address_provider.dart';
import '../../data/models/product.dart';
import '../../data/models/banner.dart' as app_banner;
import '../../data/services/api_service.dart';
import '../../../theme/thyne_theme.dart';

class ThyneHomeScreen extends StatefulWidget {
  const ThyneHomeScreen({Key? key}) : super(key: key);

  @override
  State<ThyneHomeScreen> createState() => _ThyneHomeScreenState();
}

class _ThyneHomeScreenState extends State<ThyneHomeScreen> {
  int _selectedNavIndex = 0;
  String _selectedCategory = 'all';
  List<app_banner.Banner> _banners = [];
  bool _isLoading = true;
  String _userLocation = 'Sector 2';

  // Categories for pills
  final List<String> _categories = ['all', 'women', 'men', 'inclusive'];

  // Shop by category items
  final List<Map<String, dynamic>> _shopCategories = [
    {'name': 'Rings', 'image': 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=400', 'route': '/rings'},
    {'name': 'Pendants', 'image': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=400', 'route': '/pendants'},
    {'name': 'Earrings', 'image': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400', 'route': '/earrings'},
    {'name': 'Bracelets', 'image': 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=400', 'route': '/bracelets'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserLocation();
  }

  Future<void> _loadData() async {
    try {
      final banners = await ApiService.getActiveBanners();
      if (mounted) {
        setState(() {
          if (banners['banners'] != null) {
            _banners = (banners['banners'] as List)
                .map((b) => app_banner.Banner.fromJson(b))
                .toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading banners: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserLocation() async {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    await addressProvider.loadAddresses();
    final defaultAddress = addressProvider.defaultAddress;
    if (defaultAddress != null && mounted) {
      setState(() {
        _userLocation = '${defaultAddress.city}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: ThyneTheme.background,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // Top Header
              SliverToBoxAdapter(
                child: _buildHeader(
                  context,
                  cartCount: cartProvider.itemCount,
                  wishlistCount: wishlistProvider.wishlist.length,
                  userName: authProvider.user?.name ?? 'U',
                ),
              ),

              // Location Bar
              SliverToBoxAdapter(
                child: _buildLocationBar(),
              ),

              // Category Pills
              SliverToBoxAdapter(
                child: _buildCategoryPills(),
              ),

              // Hero Carousel
              SliverToBoxAdapter(
                child: _buildHeroCarousel(),
              ),

              // Shop by Category
              SliverToBoxAdapter(
                child: _buildShopByCategory(),
              ),

              // Products Grid (based on selected category)
              SliverToBoxAdapter(
                child: _buildProductsSection(),
              ),

              // Bottom padding for navigation
              const SliverToBoxAdapter(
                child: SizedBox(height: 150),
              ),
            ],
          ),

          // Bottom Navigation and Search
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSection(context),
          ),

          // Floating Action Button
          Positioned(
            bottom: 100,
            left: 16,
            child: _buildFloatingActionButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {
    required int cartCount,
    required int wishlistCount,
    required String userName,
  }) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ThyneTheme.secondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '✧',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // THYNE text
          Text(
            'THYNE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: ThyneTheme.foreground,
            ),
          ),

          const Spacer(),

          // User Avatar
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ThyneTheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ThyneTheme.border,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  userName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThyneTheme.foreground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.location,
            size: 16,
            color: ThyneTheme.mutedForeground,
          ),
          const SizedBox(width: 4),
          Text(
            'deliver to ',
            style: TextStyle(
              fontSize: 14,
              color: ThyneTheme.mutedForeground,
            ),
          ),
          Text(
            _userLocation,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ThyneTheme.foreground,
            ),
          ),
          const Spacer(),

          // Gift icon
          IconButton(
            onPressed: () {},
            icon: Icon(
              CupertinoIcons.gift,
              size: 20,
              color: ThyneTheme.foreground,
            ),
          ),

          // Wishlist
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/wishlist'),
            icon: Icon(
              CupertinoIcons.heart,
              size: 20,
              color: ThyneTheme.foreground,
            ),
          ),

          // Cart
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: Badge(
              isLabelVisible: Provider.of<CartProvider>(context).itemCount > 0,
              label: Text('${Provider.of<CartProvider>(context).itemCount}'),
              backgroundColor: ThyneTheme.foreground,
              child: Icon(
                CupertinoIcons.bag,
                size: 20,
                color: ThyneTheme.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                _loadProductsByCategory(category);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFB4C5B4) // Selected green-grey
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: !isSelected
                      ? Border.all(color: ThyneTheme.border)
                      : null,
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected
                          ? ThyneTheme.foreground
                          : ThyneTheme.mutedForeground,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
    if (_banners.isEmpty) {
      // Default banner
      return _buildDefaultBanner();
    }

    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: carousel.CarouselSlider.builder(
        itemCount: _banners.length,
        itemBuilder: (context, index, realIndex) {
          final banner = _banners[index];
          return _buildBannerItem(banner);
        },
        options: carousel.CarouselOptions(
          height: 400,
          viewportFraction: 0.92,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          enlargeCenterPage: true,
        ),
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage('assets/images/bridal_banner.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Begin Your Bridal\nJourney',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Exquisite bridal jewelry with Khazana •\nAcross India & Middle East',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/products',
                      arguments: {'category': 'bridal'});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5A2D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'EXPLORE BRIDAL',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Page indicator
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '1 / 3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(app_banner.Banner banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: CachedNetworkImageProvider(banner.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (banner.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    banner.description!,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopByCategory() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop by Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ThyneTheme.foreground,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _shopCategories.length,
            itemBuilder: (context, index) {
              final category = _shopCategories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/products',
                      arguments: {'category': category['name'].toLowerCase()});
                },
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: ThyneTheme.secondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ThyneTheme.border,
                          width: 1,
                        ),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(category['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category['name'],
                      style: TextStyle(
                        fontSize: 12,
                        color: ThyneTheme.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    // This would load products based on selected category
    return Container(
      padding: const EdgeInsets.all(16),
      child: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final products = productProvider.products.take(4).toList();

          if (products.isEmpty) {
            return SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Featured Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ThyneTheme.foreground,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductCard(product);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product/${product.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: ThyneTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ThyneTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  color: ThyneTheme.secondary,
                  image: product.images.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(product.images.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ThyneTheme.commerceGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThyneTheme.background.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: ThyneTheme.border),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 48,
                decoration: BoxDecoration(
                  color: ThyneTheme.secondary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ThyneTheme.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 20,
                      color: ThyneTheme.mutedForeground,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'ask me anything',
                          hintStyle: TextStyle(
                            color: ThyneTheme.mutedForeground,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (query) {
                          Navigator.pushNamed(context, '/search',
                              arguments: {'query': query});
                        },
                      ),
                    ),
                    Icon(
                      CupertinoIcons.mic,
                      size: 20,
                      color: ThyneTheme.mutedForeground,
                    ),
                  ],
                ),
              ),

              // Bottom Navigation
              Container(
                height: 60,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: CupertinoIcons.bag,
                      isSelected: _selectedNavIndex == 0,
                      onTap: () => setState(() => _selectedNavIndex = 0),
                    ),
                    _buildNavItem(
                      icon: CupertinoIcons.person_2,
                      isSelected: _selectedNavIndex == 1,
                      onTap: () => setState(() => _selectedNavIndex = 1),
                    ),
                    _buildNavItem(
                      icon: CupertinoIcons.star,
                      isSelected: _selectedNavIndex == 2,
                      onTap: () => setState(() => _selectedNavIndex = 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB4C5B4) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? ThyneTheme.foreground : ThyneTheme.mutedForeground,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF2D5A2D),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {
          // Open create/add menu
          _showCreateMenu(context);
        },
        icon: Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(CupertinoIcons.camera),
                title: Text('Upload Photo'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/community/create');
                },
              ),
              ListTile(
                leading: Icon(CupertinoIcons.pencil),
                title: Text('Create Post'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/community/create');
                },
              ),
              ListTile(
                leading: Icon(CupertinoIcons.sparkles),
                title: Text('AI Design'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to AI section
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _loadProductsByCategory(String category) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    if (category == 'all') {
      productProvider.loadProducts();
    } else {
      // Filter by gender
      productProvider.filterByGender(category);
    }
  }
}