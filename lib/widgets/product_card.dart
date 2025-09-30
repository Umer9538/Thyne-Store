import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/theme.dart';

class ProductCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final isInWishlist = productProvider.isInWishlist(product.id);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                      imageUrl: product.images.isNotEmpty
                          ? product.images.first
                          : 'https://via.placeholder.com/300',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                // Discount Badge
                if (showDiscount && product.discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${product.discount.toStringAsFixed(0)}% OFF',
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
                  child: InkWell(
                    onTap: () {
                      productProvider.toggleWishlist(product);
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
                        isInWishlist ? Icons.favorite : Icons.favorite_outline,
                        size: 18,
                        color: isInWishlist
                            ? AppTheme.errorRed
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Product Details
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Expanded(
                      flex: 2,
                      child: Text(
                        product.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Rating (compact, only if exists)
                    if (product.rating > 0)
                      SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            ...List.generate(
                              5,
                              (index) => Icon(
                                index < product.rating.floor() ? Icons.star : Icons.star_border,
                                size: 7,
                                color: AppTheme.warningAmber,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '(${product.reviewCount})',
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
                              '₹${product.price.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGold,
                                    fontSize: 9,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.originalPrice != null)
                            Text(
                              '₹${product.originalPrice!.toStringAsFixed(0)}',
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
                      child: ElevatedButton(
                        onPressed: product.isAvailable
                            ? () {
                                cartProvider.addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} added to cart'),
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
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        child: Text(
                          product.isAvailable ? 'Add' : 'Out',
                          style: const TextStyle(fontSize: 7),
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