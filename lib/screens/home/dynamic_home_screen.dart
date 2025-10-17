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
import '../../utils/responsive.dart';
import '../../services/api_service.dart';
import '../../models/homepage.dart';
import '../../models/product.dart';
import '../../widgets/deal_of_day_widget.dart';
import '../../widgets/flash_sale_widget.dart';
import '../../widgets/recently_viewed_widget.dart';
import '../../widgets/product_card.dart';
import '../../widgets/showcase_360_widget.dart';
import '../../widgets/bundle_deal_widget.dart';
import '../../widgets/overlay_page.dart';
import '../product/product_list_screen.dart';
import '../product/product_detail_screen.dart';
import '../search/search_screen.dart';

class DynamicHomeScreen extends StatefulWidget {
  final Function(String category)? onCategoryTap;
  final VoidCallback? onViewAllProducts;

  const DynamicHomeScreen({
    super.key,
    this.onCategoryTap,
    this.onViewAllProducts,
  });

  @override
  State<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends State<DynamicHomeScreen> {
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _timer;
  HomepageData? _homepageData;
  bool _loading = true;
  String? _error;
  List<Map<String, String>> _banners = [];
  List<String> _visibleCategories = [];
  Map<String, Product> _productCache = {};
  Map<String, List<Product>> _flashSaleProductsCache = {};
  Map<String, Product> _showcase360ProductsCache = {};
  Map<String, List<Product>> _bundleProductsCache = {};

  @override
  void initState() {
    super.initState();
    _loadHomepageData();
    _startAutoSlide();

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
      if (_pageController.hasClients && _banners.isNotEmpty) {
        final nextPage = (_currentCarouselIndex + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadHomepageData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Fetch homepage data
      final response = await ApiService.getHomepage();

      if (response['success'] == true && response['data'] != null) {
        _homepageData = HomepageData.fromJson(response['data']);

        // Load product details for deal of day
        if (_homepageData!.dealOfDay != null) {
          try {
            final productResp = await ApiService.getProduct(
              productId: _homepageData!.dealOfDay!.productId,
            );
            if (productResp['success'] == true && productResp['data'] != null) {
              _productCache[_homepageData!.dealOfDay!.productId] =
                  Product.fromJson(productResp['data']);
            }
          } catch (e) {
            print('Error loading deal product: $e');
          }
        }

        // Load products for each flash sale
        for (var sale in _homepageData!.activeFlashSales) {
          if (sale.productIds.isNotEmpty) {
            List<Product> saleProducts = [];
            for (var productId in sale.productIds.take(10)) {
              // Limit to 10 products
              try {
                if (_productCache.containsKey(productId)) {
                  saleProducts.add(_productCache[productId]!);
                } else {
                  final productResp = await ApiService.getProduct(
                    productId: productId,
                  );
                  if (productResp['success'] == true &&
                      productResp['data'] != null) {
                    final product = Product.fromJson(productResp['data']);
                    _productCache[productId] = product;
                    saleProducts.add(product);
                  }
                }
              } catch (e) {
                print('Error loading product $productId: $e');
              }
            }
            _flashSaleProductsCache[sale.id] = saleProducts;
          }
        }

        // Load products for 360° showcases
        for (var showcase in _homepageData!.showcases360) {
          try {
            if (_productCache.containsKey(showcase.productId)) {
              _showcase360ProductsCache[showcase.id] = _productCache[showcase.productId]!;
            } else {
              final productResp = await ApiService.getProduct(
                productId: showcase.productId,
              );
              if (productResp['success'] == true && productResp['data'] != null) {
                final product = Product.fromJson(productResp['data']);
                _productCache[showcase.productId] = product;
                _showcase360ProductsCache[showcase.id] = product;
              }
            }
          } catch (e) {
            print('Error loading showcase product: $e');
          }
        }

        // Load products for bundle deals
        for (var bundle in _homepageData!.bundleDeals) {
          if (bundle.items.isNotEmpty) {
            List<Product> bundleProducts = [];
            for (var item in bundle.items) {
              try {
                if (_productCache.containsKey(item.productId)) {
                  bundleProducts.add(_productCache[item.productId]!);
                } else {
                  final productResp = await ApiService.getProduct(
                    productId: item.productId,
                  );
                  if (productResp['success'] == true && productResp['data'] != null) {
                    final product = Product.fromJson(productResp['data']);
                    _productCache[item.productId] = product;
                    bundleProducts.add(product);
                  }
                }
              } catch (e) {
                print('Error loading bundle product ${item.productId}: $e');
              }
            }
            _bundleProductsCache[bundle.id] = bundleProducts;
          }
        }

        // Load banners
        try {
          final bannersResp = await ApiService.getActiveBanners();
          if (bannersResp['success'] == true && bannersResp['data'] != null) {
            final activeBanners = (bannersResp['data'] as List? ?? []);
            if (activeBanners.isNotEmpty) {
              _banners = activeBanners
                  .map<Map<String, String>>((b) => {
                        'image': (b['imageUrl'] ?? '').toString(),
                        'title': (b['title'] ?? 'Featured').toString(),
                        'subtitle': (b['description'] ?? 'Shop now').toString(),
                        'festivalTag': (b['festivalTag'] ?? '').toString(),
                      })
                  .toList();
            }
          }
        } catch (e) {
          print('Error loading banners: $e');
        }

        // Fallback banners if none loaded
        if (_banners.isEmpty) {
          _banners = [
            {
              'image':
                  'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338',
              'title': 'Exquisite Jewelry Collection',
              'subtitle': 'Discover our handcrafted pieces',
              'festivalTag': '',
            },
            {
              'image':
                  'https://images.unsplash.com/photo-1605100804763-247f67b3557e',
              'title': 'Diamond Collection',
              'subtitle': 'Brilliance that lasts forever',
              'festivalTag': '',
            },
          ];
        }

        // Load categories
        try {
          final catsResp = await ApiService.getCategories();
          if (catsResp['success'] == true && catsResp['data'] != null) {
            _visibleCategories = (catsResp['data'] as List<dynamic>)
                .map<String>((c) => c.toString())
                .toList();
          }
        } catch (e) {
          _visibleCategories = ['Rings', 'Necklaces', 'Earrings', 'Bracelets'];
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      print('Error loading homepage data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final guestSessionProvider = Provider.of<GuestSessionProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

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
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: badges.Badge(
              badgeContent: Text(
                wishlistProvider.wishlistCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              showBadge: wishlistProvider.wishlistCount > 0,
              child: const Icon(Icons.favorite_outline),
            ),
            onPressed: () => Navigator.pushNamed(context, '/wishlist'),
          ),
          IconButton(
            icon: badges.Badge(
              badgeContent: Text(
                cartProvider.itemCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              showBadge: cartProvider.itemCount > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadHomepageData();
          await productProvider.loadProducts();
        },
        child: _buildBody(productProvider),
      ),
    );
  }

  Widget _buildBody(ProductProvider productProvider) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGold),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading homepage'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadHomepageData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Carousel
          _buildHeroCarousel(),

          // Deal of Day
          if (_homepageData?.dealOfDay != null &&
              _productCache.containsKey(_homepageData!.dealOfDay!.productId))
            DealOfDayWidget(
              deal: _homepageData!.dealOfDay!,
              product: _productCache[_homepageData!.dealOfDay!.productId],
            ),

          // Flash Sales
          for (var sale in _homepageData?.activeFlashSales ?? [])
            if (_flashSaleProductsCache.containsKey(sale.id))
              FlashSaleWidget(
                sale: sale,
                products: _flashSaleProductsCache[sale.id]!,
              ),

          // Categories
          _buildCategoriesSection(),

          // 360° Showcases
          for (var showcase in _homepageData?.showcases360 ?? [])
            if (_showcase360ProductsCache.containsKey(showcase.id))
              Showcase360Widget(
                showcase: showcase,
                product: _showcase360ProductsCache[showcase.id],
              ),

          // Bundle Deals
          for (var bundle in _homepageData?.bundleDeals ?? [])
            if (_bundleProductsCache.containsKey(bundle.id))
              BundleDealWidget(
                bundle: bundle,
                products: _bundleProductsCache[bundle.id]!,
              ),

          // Featured Products
          _buildFeaturedProducts(productProvider),

          // Recently Viewed
          if (_homepageData?.recentlyViewed.isNotEmpty ?? false)
            RecentlyViewedWidget(
              products: _homepageData!.recentlyViewed,
            ),

          // New Arrivals
          _buildNewArrivals(productProvider),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel() {
    return Column(
      children: [
        SizedBox(
          height: Responsive.valueByDevice(
            context: context,
            mobile: 200.0,
            tablet: 300.0,
            desktop: 400.0,
          ),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentCarouselIndex = index);
            },
            itemCount: _banners.length,
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
                    if (banner['festivalTag']?.isNotEmpty ?? false)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryGold,
                                AppTheme.accentPurple,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.celebration,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                banner['festivalTag']!.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                                ?.copyWith(color: Colors.white),
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
                            onPressed: () {},
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
        if (_banners.isNotEmpty)
          Row(
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

  Widget _buildCategoriesSection() {
    if (_visibleCategories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shop by Category',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  if (widget.onViewAllProducts != null) {
                    widget.onViewAllProducts!();
                  }
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
              itemCount: _visibleCategories.length,
              itemBuilder: (context, index) {
                final category = _visibleCategories[index];
                final categoryImages = {
                  'Rings':
                      'https://images.unsplash.com/photo-1605100804763-247f67b3557e',
                  'Necklaces':
                      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f',
                  'Earrings':
                      'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908',
                  'Bracelets':
                      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338',
                };
                final image = categoryImages[category] ??
                    'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338';

                return GestureDetector(
                  onTap: () {
                    // Call callback to change content
                    if (widget.onCategoryTap != null) {
                      widget.onCategoryTap!(category);
                    }
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
                            child: CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[200]),
                            ),
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

  Widget _buildFeaturedProducts(ProductProvider productProvider) {
    final products = productProvider.featuredProducts;
    if (products.isEmpty) return const SizedBox.shrink();

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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  if (widget.onViewAllProducts != null) {
                    widget.onViewAllProducts!();
                  }
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
              itemCount: products.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: EdgeInsets.only(right: index < products.length - 1 ? 12 : 0),
                  child: ProductCard(
                    product: products[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(product: products[index]),
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

  Widget _buildNewArrivals(ProductProvider productProvider) {
    final products = productProvider.products
        .where((p) =>
            p.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .take(4)
        .toList();

    if (products.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Arrivals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: EdgeInsets.only(right: index < products.length - 1 ? 12 : 0),
                  child: ProductCard(
                    product: products[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(product: products[index]),
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
            const Icon(Icons.person_outline, size: 20, color: AppTheme.primaryGold),
            Text(
              'Guest',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 8, color: AppTheme.primaryGold),
            ),
          ],
        ),
        onPressed: () => Navigator.pushNamed(context, '/login'),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.person_outline),
        onPressed: () => Navigator.pushNamed(context, '/login'),
      );
    }
  }
}
