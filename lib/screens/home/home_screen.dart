import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badges/badges.dart' as badges;
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/guest_session_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_list_screen.dart';
import '../product/product_detail_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _timer;
  List<Map<String, String>> _banners = [];
  List<String> _visibleCategories = [];
  bool _loadingStorefront = true;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
    _loadStorefront();
    // Ensure products are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (productProvider.products.isEmpty) {
        productProvider.loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final total = _banners.isNotEmpty ? _banners.length : 1;
        final nextPage = (_currentCarouselIndex + 1) % total;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadStorefront() async {
    try {
      setState(() { _loadingStorefront = true; });
      
      // Try to get homepage config, but fallback gracefully if not available
      try {
        final resp = await ApiService.getHomePageConfig();
        if (resp['success'] == true && resp['data'] != null) {
          final data = resp['data'] as Map<String, dynamic>;
          final heroBanners = (data['heroBanners'] as List? ?? []);
          _banners = heroBanners.map<Map<String, String>>((b) => {
            'image': (b['imageUrl'] ?? '').toString(),
            'title': (b['title'] ?? ' ').toString(),
            'subtitle': (b['subtitle'] ?? ' ').toString(),
          }).toList();
        }
      } catch (e) {
        // Use default banners if homepage config fails
        _banners = [
          {
            'image': 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338',
            'title': 'Exquisite Jewelry Collection',
            'subtitle': 'Discover our handcrafted pieces',
          },
          {
            'image': 'https://images.unsplash.com/photo-1605100804763-247f67b3557e',
            'title': 'Diamond Collection',
            'subtitle': 'Brilliance that lasts forever',
          },
        ];
      }
      
      // Get categories from the working endpoint
      try {
        final catsResp = await ApiService.getCategories();
        if (catsResp['success'] == true && catsResp['data'] != null) {
          final cats = (catsResp['data'] as List<dynamic>);
          _visibleCategories = cats.map<String>((c) => c.toString()).toList();
        }
      } catch (e) {
        // Fallback to default categories
        _visibleCategories = ['Rings', 'Necklaces', 'Earrings', 'Bracelets'];
      }
    } catch (_) {
      // Final fallback
      _banners = [
        {
          'image': 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338',
          'title': 'Exquisite Jewelry Collection',
          'subtitle': 'Discover our handcrafted pieces',
        },
      ];
      _visibleCategories = ['Rings', 'Necklaces', 'Earrings', 'Bracelets'];
    } finally {
      if (mounted) setState(() { _loadingStorefront = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final guestSessionProvider = Provider.of<GuestSessionProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.diamond_outlined,
              color: AppTheme.primaryGold,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Thyne Jewels',
                style: Theme.of(context).textTheme.headlineLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        leading: _buildUserIndicator(authProvider, guestSessionProvider),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: badges.Badge(
              badgeContent: Text(
                wishlistProvider.wishlistCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
              showBadge: wishlistProvider.wishlistCount > 0,
              child: const Icon(Icons.favorite_outline),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/wishlist');
            },
          ),
          IconButton(
            icon: badges.Badge(
              badgeContent: Text(
                cartProvider.itemCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
              showBadge: cartProvider.itemCount > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await productProvider.loadProducts();
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Carousel
              _buildHeroCarousel(),

              // Categories Section
              _buildCategoriesSection(context),

              // Featured Products
              _buildFeaturedProducts(context, productProvider),

              // New Arrivals
              _buildNewArrivals(context, productProvider),

              // Special Offers
              _buildSpecialOffers(context, productProvider),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemCount: _banners.isNotEmpty ? _banners.length : 0,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: banner['image'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner['title'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner['subtitle'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to collection
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Shop Now'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (_banners.isNotEmpty) Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  entry.key,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentCarouselIndex == entry.key ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentCarouselIndex == entry.key
                      ? AppTheme.primaryGold
                      : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextButton(
                onPressed: () {
                  // View all categories
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _visibleCategories.isNotEmpty ? _visibleCategories.length : 0,
              itemBuilder: (context, index) {
                final category = _visibleCategories[index];
                // Map categories to appropriate images
                final categoryImages = {
                  'Rings': 'https://images.unsplash.com/photo-1605100804763-247f67b3557e',
                  'Necklaces': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f',
                  'Earrings': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908',
                  'Bracelets': 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338',
                };
                final image = categoryImages[category] ?? 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductListScreen(
                          category: category,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: image,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                    ),
                                  )
                                : Container(color: Colors.grey[200]),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    final featuredProducts = productProvider.featuredProducts;

    if (featuredProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Products',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListScreen(),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: featuredProducts.length,
              itemBuilder: (context, index) {
                final product = featuredProducts[index];
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: product,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewArrivals(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    final newProducts = productProvider.products
        .where((p) => p.createdAt.isAfter(
              DateTime.now().subtract(const Duration(days: 30)),
            ))
        .take(4)
        .toList();

    if (newProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Arrivals',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: newProducts.length,
            itemBuilder: (context, index) {
              final product = newProducts[index];
              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        product: product,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialOffers(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    final discountedProducts = productProvider.products
        .where((p) => p.originalPrice != null && p.discount > 0)
        .take(4)
        .toList();

    if (discountedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Special Offers',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextButton(
                onPressed: () {
                  // Navigate to offers
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: discountedProducts.length,
              itemBuilder: (context, index) {
                final product = discountedProducts[index];
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(
                    product: product,
                    showDiscount: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: product,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserIndicator(
    AuthProvider authProvider,
    GuestSessionProvider guestSessionProvider,
  ) {
    if (authProvider.isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: AppTheme.primaryGold,
          child: Text(
            authProvider.user!.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (guestSessionProvider.isActive) {
      return IconButton(
        icon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline,
              size: 20,
              color: AppTheme.primaryGold,
            ),
            Text(
              'Guest',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    color: AppTheme.primaryGold,
                  ),
            ),
          ],
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.person_outline),
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
      );
    }
  }
}