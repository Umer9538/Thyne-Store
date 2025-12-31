import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../data/models/product.dart';
import '../../../data/models/homepage.dart';
import '../../viewmodels/cart_provider.dart';
import '../../../data/services/api_service.dart';
import '../../../utils/theme.dart';
import '../product/product_detail_screen.dart';

class BundleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bundle;

  const BundleDetailScreen({
    super.key,
    required this.bundle,
  });

  @override
  State<BundleDetailScreen> createState() => _BundleDetailScreenState();
}

class _BundleDetailScreenState extends State<BundleDetailScreen> {
  bool _loading = true;
  List<Product> _products = [];
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadBundleProducts();
  }

  Future<void> _loadBundleProducts() async {
    setState(() => _loading = true);

    try {
      final items = widget.bundle['items'] as List<dynamic>? ?? [];
      List<Product> products = [];

      for (var item in items) {
        final productId = item['productId'] as String?;
        if (productId != null) {
          try {
            final response = await ApiService.getProduct(productId: productId);
            if (response['success'] == true && response['data'] != null) {
              products.add(Product.fromJson(response['data']));
            }
          } catch (e) {
            debugPrint('Error loading product $productId: $e');
          }
        }
      }

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading bundle products: $e');
      setState(() => _loading = false);
    }
  }

  void _addBundleToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final items = widget.bundle['items'] as List<dynamic>? ?? [];

    // Calculate discount percentage
    final bundlePrice = (widget.bundle['bundlePrice'] ?? 0).toDouble();
    final originalPrice = (widget.bundle['originalPrice'] ?? bundlePrice).toDouble();
    final discountPercent = originalPrice > 0
        ? ((originalPrice - bundlePrice) / originalPrice * 100).round()
        : 0;

    // Create bundle info for all items in this bundle
    final bundleId = widget.bundle['id']?.toString() ??
                     widget.bundle['_id']?.toString() ??
                     DateTime.now().millisecondsSinceEpoch.toString();
    final bundleName = widget.bundle['title'] ?? 'Bundle Deal';
    final bundleInfo = BundleInfo(
      bundleId: bundleId,
      bundleName: bundleName,
      bundlePrice: bundlePrice,
      originalPrice: originalPrice,
      discountPercent: discountPercent,
    );

    // Add each product in the bundle to cart with their quantities
    for (int i = 0; i < _products.length && i < items.length; i++) {
      final product = _products[i];
      final itemQuantity = (items[i]['quantity'] as int? ?? 1) * _quantity;

      // Calculate discounted price per item based on bundle discount
      final discountRatio = originalPrice > 0 ? bundlePrice / originalPrice : 1.0;
      final discountedPrice = product.price * discountRatio;

      cartProvider.addToCart(
        product,
        quantity: itemQuantity,
        salePrice: discountedPrice,
        originalPrice: product.price,
        discountPercent: discountPercent,
        bundleInfo: bundleInfo,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bundle added to cart! (${_products.length} items)'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.bundle['title'] ?? 'Bundle Deal';
    final description = widget.bundle['description'] ?? '';
    final bundlePrice = (widget.bundle['bundlePrice'] ?? 0).toDouble();
    final originalPrice = (widget.bundle['originalPrice'] ?? bundlePrice).toDouble();
    final bannerImage = widget.bundle['bannerImage'] as String?;
    final stock = widget.bundle['stock'] as int? ?? 0;
    final soldCount = widget.bundle['soldCount'] as int? ?? 0;
    final availableStock = stock - soldCount;
    final discountPercent = originalPrice > 0
        ? ((originalPrice - bundlePrice) / originalPrice * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // App Bar with Banner
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF094010),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (bannerImage != null && bannerImage.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: bannerImage,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _buildDefaultBanner(),
                    )
                  else
                    _buildDefaultBanner(),
                  // Gradient overlay
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
                  // Bundle info overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (discountPercent > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SAVE $discountPercent%',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${bundlePrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF094010),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (originalPrice > bundlePrice) ...[
                        Text(
                          '₹${originalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'You save ₹${(originalPrice - bundlePrice).toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                if (description.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this Bundle',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Bundle Items Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.gift_fill,
                            color: Color(0xFF094010),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What\'s Included (${_products.length} items)',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        _buildProductsShimmer()
                      else if (_products.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No products found in this bundle',
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_products.length, (index) {
                          final product = _products[index];
                          final items = widget.bundle['items'] as List<dynamic>? ?? [];
                          final itemQuantity = index < items.length
                              ? (items[index]['quantity'] as int? ?? 1)
                              : 1;
                          return _buildProductItem(product, itemQuantity);
                        }),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Stock Info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Icon(
                        availableStock > 5
                            ? Icons.check_circle
                            : availableStock > 0
                                ? Icons.warning
                                : Icons.cancel,
                        color: availableStock > 5
                            ? Colors.green
                            : availableStock > 0
                                ? Colors.orange
                                : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        availableStock > 5
                            ? 'In Stock'
                            : availableStock > 0
                                ? 'Only $availableStock left!'
                                : 'Out of Stock',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: availableStock > 5
                              ? Colors.green
                              : availableStock > 0
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Text(
                      '$_quantity',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _quantity < availableStock
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Add to Cart Button
              Expanded(
                child: ElevatedButton(
                  onPressed: availableStock > 0 && !_loading ? _addBundleToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF094010),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add Bundle to Cart',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

  Widget _buildDefaultBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF094010),
            const Color(0xFF094010).withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.gift_fill,
          size: 80,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product, int quantity) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.images.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (quantity > 1)
                    Text(
                      'Qty: $quantity',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF094010),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer loading effect for products list
  Widget _buildProductsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Image placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                // Text placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
