import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../models/event_promotion.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/promotion_manager.dart';
import '../utils/theme.dart';
import 'glass/glass_ui.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showDiscount;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showDiscount = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  EventPromotion? _promotion;
  bool _loadingPromotion = false;

  @override
  void initState() {
    super.initState();
    _checkPromotion();
  }

  Future<void> _checkPromotion() async {
    setState(() => _loadingPromotion = true);
    try {
      // Check for product-specific or category promotion
      final promo = await PromotionManager.getPromotionForProduct(widget.product.id);
      if (promo == null && widget.product.category.isNotEmpty) {
        final categoryPromo = await PromotionManager.getPromotionForCategory(widget.product.category);
        if (mounted) {
          setState(() {
            _promotion = categoryPromo;
            _loadingPromotion = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _promotion = promo;
            _loadingPromotion = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPromotion = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isInWishlist = wishlistProvider.isInWishlist(widget.product.id);

    // Determine which discount to show
    final hasEventDiscount = _promotion != null && _promotion!.isLive;
    final eventDiscountText = hasEventDiscount ? _promotion!.discountText : null;
    final hasRegularDiscount = widget.showDiscount && widget.product.discount > 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: GlassCard(
        padding: EdgeInsets.zero,
        elevation: 2,
        blur: GlassConfig.softBlur,
        showGlow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Wishlist Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: widget.product.images.isNotEmpty
                          ? widget.product.images.first
                          : 'https://via.placeholder.com/300',
                      fit: BoxFit.cover,
                      memCacheWidth: 400, // Optimize for product card size
                      maxWidthDiskCache: 400,
                      fadeInDuration: const Duration(milliseconds: 300),
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Event Promotion Badge (priority over regular discount)
                if (hasEventDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          blur: GlassConfig.mediumBlur,
                          borderRadius: BorderRadius.circular(12),
                          showGlow: true,
                          tintColor: AppTheme.primaryGold,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryGold, AppTheme.accentPurple],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.celebration,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                eventDiscountText!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          blur: GlassConfig.mediumBlur,
                          borderRadius: BorderRadius.circular(8),
                          child: Text(
                            _promotion!.eventName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                // Regular Discount Badge (if no event promotion)
                else if (hasRegularDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      blur: GlassConfig.mediumBlur,
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.errorRed.withOpacity(0.9),
                      child: Text(
                        '${widget.product.discount.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Wishlist Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      wishlistProvider.toggleWishlist(widget.product.id);
                    },
                    child: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_outline,
                      color: isInWishlist ? AppTheme.errorRed : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Expanded(
                      flex: 2,
                      child: Text(
                        widget.product.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Rating (compact, only if exists)
                    if (widget.product.rating > 0)
                      SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            ...List.generate(
                              5,
                              (index) => Icon(
                                index < widget.product.rating.floor() ? Icons.star : Icons.star_border,
                                size: 7,
                                color: AppTheme.warningAmber,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '(${widget.product.reviewCount})',
                              style: const TextStyle(fontSize: 7),
                            ),
                          ],
                        ),
                      ),
                    // Price row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '₹${widget.product.price.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGold,
                                    fontSize: 9,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.product.originalPrice != null || hasEventDiscount)
                            Text(
                              '₹${(widget.product.originalPrice ?? widget.product.price).toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppTheme.textSecondary,
                                    fontSize: 7,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 18,
                      child: GlassButton(
                        text: widget.product.isAvailable ? 'Add' : 'Out',
                        onPressed: widget.product.isAvailable
                            ? () {
                                cartProvider.addToCart(widget.product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${widget.product.name} added to cart'),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'View Cart',
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/cart');
                                      },
                                    ),
                                  ),
                                );
                              }
                            : null,
                        enabled: widget.product.isAvailable,
                        height: 18,
                        padding: EdgeInsets.zero,
                        blur: GlassConfig.softBlur,
                        tintColor: AppTheme.primaryGold,
                        borderRadius: BorderRadius.circular(3),
                        child: Text(
                          widget.product.isAvailable ? 'Add' : 'Out',
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}