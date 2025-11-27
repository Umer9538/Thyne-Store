import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:flutter/cupertino.dart';

// Import existing providers and models
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../models/product.dart';
import '../../models/banner.dart' as app_banner;
import '../../services/api_service.dart';
import '../../theme/thyne_theme.dart';

class CommerceSection extends StatefulWidget {
  const CommerceSection({Key? key}) : super(key: key);

  @override
  State<CommerceSection> createState() => _CommerceSectionState();
}

class _CommerceSectionState extends State<CommerceSection> {

  // Data holders
  List<app_banner.Banner> _banners = [];
  List<Product> _featuredProducts = [];
  List<Product> _newArrivals = [];
  List<Product> _bestSellers = [];
  Map<String, dynamic>? _dealOfDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommerceData();
  }

  Future<void> _loadCommerceData() async {
    try {
      // Load all commerce data in parallel
      final banners = await ApiService.getActiveBanners();
      final featured = await ApiService.getFeaturedProducts();
      final newArrivals = await ApiService.getProducts(
        page: 1,
        limit: 10,
        sortBy: 'newest'
      );
      final bestSellers = await ApiService.getProducts(
        page: 1,
        limit: 10,
        sortBy: 'popularity'
      );
      final dealOfDay = await ApiService.getActiveDealOfDay();

      if (mounted) {
        setState(() {
          // Parse banners
          _banners = [];
          if (banners['banners'] != null) {
            _banners = (banners['banners'] as List)
                .map((b) => app_banner.Banner.fromJson(b))
                .toList();
          }

          // Parse products
          _featuredProducts = [];
          if (featured['products'] != null) {
            _featuredProducts = (featured['products'] as List)
                .map((p) => Product.fromJson(p))
                .toList();
          }

          _newArrivals = [];
          if (newArrivals['products'] != null) {
            _newArrivals = (newArrivals['products'] as List)
                .map((p) => Product.fromJson(p))
                .toList();
          }

          _bestSellers = [];
          if (bestSellers['products'] != null) {
            _bestSellers = (bestSellers['products'] as List)
                .map((p) => Product.fromJson(p))
                .toList();
          }

          _dealOfDay = dealOfDay;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading commerce data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    return RefreshIndicator(
      onRefresh: _loadCommerceData,
      color: ThyneTheme.commerceGreen,
      child: CustomScrollView(
        slivers: [
          // Hero Banner Carousel
          if (_banners.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildHeroBanner(),
            ),

          // Categories Grid
          SliverToBoxAdapter(
            child: _buildCategoriesSection(),
          ),

          // Deal of the Day
          if (_dealOfDay != null)
            SliverToBoxAdapter(
              child: _buildDealOfDay(),
            ),

          // Featured Products
          if (_featuredProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildProductCarousel(
                title: 'Featured Products',
                products: _featuredProducts,
              ),
            ),

          // New Arrivals
          if (_newArrivals.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildProductCarousel(
                title: 'New Arrivals',
                products: _newArrivals,
                badge: 'NEW',
              ),
            ),

          // Best Sellers
          if (_bestSellers.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildProductCarousel(
                title: 'Best Sellers',
                products: _bestSellers,
                badge: 'BESTSELLER',
              ),
            ),

          // Collections
          SliverToBoxAdapter(
            child: _buildCollectionsSection(),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        children: [
          Container(height: 200, color: Colors.white, margin: const EdgeInsets.all(16)),
          Container(height: 100, color: Colors.white, margin: const EdgeInsets.all(16)),
          Container(height: 250, color: Colors.white, margin: const EdgeInsets.all(16)),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 16),
      child: carousel.CarouselSlider.builder(
        itemCount: _banners.length,
        itemBuilder: (context, index, realIndex) {
          final banner = _banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: ThyneTheme.secondary,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: ThyneTheme.secondary,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  if (banner.title.isNotEmpty || banner.description != null)
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
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (banner.description != null)
                            Text(
                              banner.description!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
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
        options: carousel.CarouselOptions(
          height: 200,
          viewportFraction: 0.9,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          enlargeCenterPage: true,
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Rings', 'icon': '💍'},
      {'name': 'Necklaces', 'icon': '📿'},
      {'name': 'Earrings', 'icon': '💎'},
      {'name': 'Bracelets', 'icon': '⌚'},
      {'name': 'Bangles', 'icon': '🔮'},
      {'name': 'Pendants', 'icon': '🏵️'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop by Category',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                onTap: () {
                  // Navigate to category
                  Navigator.pushNamed(
                    context,
                    '/products',
                    arguments: {'category': category['name']!.toLowerCase()},
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: ThyneTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThyneTheme.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category['icon']!,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name']!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDealOfDay() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThyneTheme.commerceGreen.withOpacity(0.1),
            ThyneTheme.commerceGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThyneTheme.commerceGreen.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.bolt,
                color: ThyneTheme.commerceGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Deal of the Day',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ThyneTheme.commerceGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Countdown timer would go here
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ThyneTheme.commerceGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '23:59:59',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Deal product would go here based on _dealOfDay data
          Text(
            'Special offer on selected jewelry!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCarousel({
    required String title,
    required List<Product> products,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/products');
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: ThyneTheme.commerceGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product, badge: badge);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, {String? badge}) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isInWishlist = wishlistProvider.isInWishlist(product.id);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product/${product.id}');
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: ThyneTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThyneTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with badge
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: ThyneTheme.secondary,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product.images.isNotEmpty
                          ? product.images.first
                          : '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ThyneTheme.commerceGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                // Wishlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () async {
                      if (isInWishlist) {
                        await wishlistProvider.removeFromWishlist(product.id);
                      } else {
                        await wishlistProvider.addToWishlist(product.id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isInWishlist
                            ? Colors.red
                            : ThyneTheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Product details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ThyneTheme.commerceGreen,
                        ),
                      ),
                      if (product.originalPrice != null &&
                          product.originalPrice! > product.price) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${product.originalPrice!.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: ThyneTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount ?? 0})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThyneTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsSection() {
    final collections = [
      {
        'name': 'Wedding Collection',
        'image': 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338',
        'color': const Color(0xFFD4AF37),
      },
      {
        'name': 'Traditional',
        'image': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908',
        'color': const Color(0xFF8B4513),
      },
      {
        'name': 'Modern',
        'image': 'https://images.unsplash.com/photo-1602751584552-8ba73aad10e1',
        'color': const Color(0xFF708090),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Curated Collections',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...collections.map((collection) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(collection['image'] as String),
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
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              child: Text(
                collection['name'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
}