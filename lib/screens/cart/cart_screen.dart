import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/guest_session_provider.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final guestSessionProvider = Provider.of<GuestSessionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (cartProvider.items.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text(
                      'Are you sure you want to remove all items from your cart?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          cartProvider.clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: AppTheme.errorRed),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: cartProvider.items.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return _buildCartItem(context, item, cartProvider);
                    },
                  ),
                ),
                _buildOrderSummary(context, cartProvider),
              ],
            ),
      bottomNavigationBar: cartProvider.items.isNotEmpty
          ? _buildCheckoutButton(context, cartProvider, authProvider, guestSessionProvider)
          : null,
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add some beautiful jewelry to get started!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, item, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      product: item.product,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.product.images.first,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${item.product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                            ),
                      ),
                      if (item.product.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${item.product.originalPrice!.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quantity Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                cartProvider.decrementQuantity(item.product.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 30),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                item.quantity.toString(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (item.quantity < item.product.stockQuantity) {
                                  cartProvider.incrementQuantity(item.product.id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Maximum stock reached'),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
              onPressed: () {
                cartProvider.removeFromCart(item.product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.product.name} removed from cart'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        cartProvider.addToCart(item.product, quantity: item.quantity);
                      },
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

  Widget _buildOrderSummary(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coupon Code
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: const InputDecoration(
                    hintText: 'Enter coupon code',
                    prefixIcon: Icon(Icons.local_offer_outlined),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_couponController.text.isNotEmpty) {
                    cartProvider.applyCoupon(_couponController.text);
                    if (cartProvider.couponCode != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coupon applied successfully!'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid coupon code'),
                          backgroundColor: AppTheme.errorRed,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),
          if (cartProvider.couponCode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(cartProvider.couponCode!),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    cartProvider.removeCoupon();
                    _couponController.clear();
                  },
                  backgroundColor: AppTheme.successGreen.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                Text(
                  'Discount: -₹${cartProvider.discount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Price Breakdown
          _buildSummaryRow('Subtotal', '₹${cartProvider.subtotal.toStringAsFixed(0)}'),
          if (cartProvider.discount > 0)
            _buildSummaryRow(
              'Discount',
              '-₹${cartProvider.discount.toStringAsFixed(0)}',
              color: AppTheme.successGreen,
            ),
          _buildSummaryRow('Tax (GST 18%)', '₹${cartProvider.tax.toStringAsFixed(0)}'),
          _buildSummaryRow('Shipping', cartProvider.shipping == 0
              ? 'FREE'
              : '₹${cartProvider.shipping.toStringAsFixed(0)}',
              color: cartProvider.shipping == 0 ? AppTheme.successGreen : null),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '₹${cartProvider.total.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(
    BuildContext context,
    CartProvider cartProvider,
    AuthProvider authProvider,
    GuestSessionProvider guestSessionProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          if (authProvider.isAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CheckoutScreen(),
              ),
            );
          } else {
            // Route to guest checkout for both guest users and unauthenticated users
            Navigator.pushNamed(context, '/guest-checkout');
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 20),
            const SizedBox(width: 8),
            Text(
              'Proceed to Checkout (${cartProvider.itemCount} items)',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}