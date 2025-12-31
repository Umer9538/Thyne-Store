import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/wishlist_provider.dart';
import '../viewmodels/auth_provider.dart';
import '../viewmodels/cart_provider.dart';
import '../../data/models/product.dart';
import '../../../utils/theme.dart';
import '../widgets/product_card.dart';
import '../widgets/glass/glass_ui.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        context.read<WishlistProvider>().loadWishlist();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('My Wishlist'),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              if (wishlistProvider.wishlistCount > 0) {
                return TextButton.icon(
                  onPressed: () => _showClearWishlistDialog(context),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, WishlistProvider>(
        builder: (context, authProvider, wishlistProvider, child) {
          // Check if user is not authenticated
          if (!authProvider.isAuthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Please login to view your wishlist',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save your favorite items for later',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  GlassPrimaryButton(
                    text: 'Login',
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                  ),
                ],
              ),
            );
          }

          if (wishlistProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (wishlistProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading wishlist',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      wishlistProvider.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassPrimaryButton(
                    text: 'Retry',
                    onPressed: () => wishlistProvider.loadWishlist(),
                  ),
                ],
              ),
            );
          }

          if (wishlistProvider.wishlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your wishlist is empty',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items you love to your wishlist',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  GlassPrimaryButton(
                    text: 'Start Shopping',
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Wishlist count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppTheme.surfaceGray,
                child: Text(
                  '${wishlistProvider.wishlistCount} item${wishlistProvider.wishlistCount == 1 ? '' : 's'} in your wishlist',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
              // Wishlist items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: wishlistProvider.wishlist.length,
                  itemBuilder: (context, index) {
                    final product = wishlistProvider.wishlist[index];
                    return _buildWishlistItem(context, product);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWishlistItem(BuildContext context, Product product) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      elevation: 2,
      blur: GlassConfig.softBlur,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.images.isNotEmpty ? product.images.first : '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (product.originalPrice != null && product.originalPrice! > product.price) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${product.originalPrice!.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          text: '',
                          onPressed: () => _addToCart(context, product),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          blur: GlassConfig.softBlur,
                          tintColor: AppTheme.primaryGold,
                          child: const Text('Add to Cart'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GlassIconButton(
                        icon: Icons.favorite,
                        onPressed: () => _removeFromWishlist(context, product),
                        size: 40,
                        tintColor: AppTheme.errorRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, Product product) async {
    try {
      final cartProvider = context.read<CartProvider>();
      cartProvider.addToCart(product);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to cart: $e')),
        );
      }
    }
  }

  void _removeFromWishlist(BuildContext context, Product product) async {
    final wishlistProvider = context.read<WishlistProvider>();
    final success = await wishlistProvider.removeFromWishlist(product.id);
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} removed from wishlist'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => wishlistProvider.addToWishlist(product.id),
          ),
        ),
      );
    }
  }

  void _showClearWishlistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GlassDialog(
        title: 'Clear Wishlist',
        message: 'Are you sure you want to remove all items from your wishlist?',
        actions: [
          GlassButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
            blur: GlassConfig.softBlur,
          ),
          GlassButton(
            text: 'Clear All',
            onPressed: () {
              Navigator.pop(context);
              _clearWishlist(context);
            },
            tintColor: AppTheme.errorRed,
            blur: GlassConfig.mediumBlur,
          ),
        ],
      ),
    );
  }

  void _clearWishlist(BuildContext context) async {
    final wishlistProvider = context.read<WishlistProvider>();
    final items = List<Product>.from(wishlistProvider.wishlist);
    
    // Remove all items
    for (final product in items) {
      await wishlistProvider.removeFromWishlist(product.id);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wishlist cleared')),
      );
    }
  }
}

