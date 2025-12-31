import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/collection.dart';
import '../../data/models/product.dart';
import '../../data/services/api_service.dart';
import '../../../theme/thyne_theme.dart';
import '../viewmodels/cart_provider.dart';
import '../viewmodels/wishlist_provider.dart';
import '../../../utils/currency_formatter.dart';
import '../product/product_detail_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;

  const CollectionDetailScreen({
    Key? key,
    required this.collection,
  }) : super(key: key);

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCollectionProducts();
  }

  Future<void> _loadCollectionProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if this is a real collection ID (MongoDB ObjectID format) or a default one
      final isRealCollectionId = widget.collection.id.length == 24 &&
          !widget.collection.id.startsWith('default_');

      List<Product> products = [];

      if (isRealCollectionId) {
        // Try to fetch products from the collection endpoint
        try {
          final response = await ApiService.getCollectionProducts(widget.collection.id);
          if (response['success'] == true && response['data'] != null) {
            final productsData = response['data'] as List<dynamic>;
            products = productsData
                .map((p) => Product.fromJson(p as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          debugPrint('Failed to fetch collection products: $e');
        }
      }

      // If no products from collection endpoint, fallback to fetching all products
      if (products.isEmpty) {
        final allProductsResponse = await ApiService.getProducts();
        if (allProductsResponse['success'] == true && allProductsResponse['data'] != null) {
          // Handle both response formats: { data: [...] } or { data: { products: [...] } }
          final data = allProductsResponse['data'];
          final productsList = data is List ? data : (data['products'] as List<dynamic>? ?? []);
          final allProducts = productsList
              .map((p) => Product.fromJson(p as Map<String, dynamic>))
              .toList();

          // Filter products based on collection tags if available
          if (widget.collection.tags.isNotEmpty) {
            products = allProducts.where((product) {
              return product.tags.any((tag) =>
                widget.collection.tags.any((collectionTag) =>
                  tag.toLowerCase().contains(collectionTag.toLowerCase()) ||
                  collectionTag.toLowerCase().contains(tag.toLowerCase())
                )
              );
            }).toList();
          }

          // If still empty or tags didn't match, take products up to itemCount
          if (products.isEmpty) {
            final limit = widget.collection.itemCount > 0 ? widget.collection.itemCount : 20;
            products = allProducts.take(limit).toList();
          }
        }
      }

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load products: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header with Collection Image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: ThyneTheme.commerceGreen,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  CachedNetworkImage(
                    imageUrl: widget.collection.primaryImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 60),
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
                  // Collection Info
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.collection.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: ThyneTheme.commerceGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FEATURED COLLECTION',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        Text(
                          widget.collection.title,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.collection.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.collection.subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.diamond_outlined,
                              size: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.collection.itemCountLabel,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Description Section (if available)
          if (widget.collection.description.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.collection.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: ThyneTheme.mutedForeground,
                    height: 1.6,
                  ),
                ),
              ),
            ),

          // Tags Section (if available)
          if (widget.collection.tags.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.collection.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ThyneTheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ThyneTheme.border),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: ThyneTheme.foreground,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Products Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ThyneTheme.foreground,
                    ),
                  ),
                  Text(
                    '${_products.length} items',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: ThyneTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Products Grid
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(_error!, style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadCollectionProducts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _products.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No products in this collection yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = _products[index];
                                return _buildProductCard(product);
                              },
                              childCount: _products.length,
                            ),
                          ),
                        ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isInWishlist = wishlistProvider.isInWishlist(product.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: product.images.isNotEmpty
                          ? product.images.first
                          : 'https://via.placeholder.com/300',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  // Wishlist Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (isInWishlist) {
                          wishlistProvider.removeFromWishlist(product.id);
                        } else {
                          wishlistProvider.addToWishlist(product.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
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
                        child: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isInWishlist ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  // Discount Badge
                  if (product.discount > 0)
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
                          '-${product.discount.toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ThyneTheme.foreground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ThyneTheme.commerceGreen,
                          ),
                        ),
                        if (product.discount > 0 && product.originalPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            CurrencyFormatter.format(product.originalPrice!),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
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
}
