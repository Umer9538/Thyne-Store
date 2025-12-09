import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';
import '../../utils/theme.dart';
import '../../constants/order_constants.dart';
import '../../constants/app_spacing.dart';
import '../../constants/routes.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedFilter = OrderFilters.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        context.read<OrderProvider>().loadOrders(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              if (authProvider.isAuthenticated) {
                context.read<OrderProvider>().loadOrders(authProvider.user!.id);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: AppSpacing.filterBarHeight,
            padding: AppSpacing.paddingVerticalSm,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.paddingHorizontalLg,
              itemCount: OrderFilters.historyFilters.length,
              separatorBuilder: (_, __) => AppSpacing.horizontalSm,
              itemBuilder: (context, index) {
                final filter = OrderFilters.historyFilters[index];
                final isSelected = _selectedFilter == filter;

                return FilterChip(
                  label: Text(OrderFilters.getDisplayName(filter)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedColor: AppTheme.primaryGold.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryGold,
                );
              },
            ),
          ),
          // Orders list
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final filteredOrders = _filterOrders(orderProvider.orders);

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 100,
                          color: Colors.grey.shade300,
                        ),
                        AppSpacing.verticalXxl,
                        Text(
                          _selectedFilter == OrderFilters.all
                              ? 'No orders found'
                              : 'No ${OrderFilters.getDisplayName(_selectedFilter).toLowerCase()} orders',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        AppSpacing.verticalSm,
                        Text(
                          _selectedFilter == OrderFilters.all
                              ? 'Your order history will appear here'
                              : 'Try selecting a different filter',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        AppSpacing.verticalXxl,
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, Routes.home),
                          child: const Text('Start Shopping'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _buildOrderCard(context, order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(order.status)),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Order date and total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(order.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  Text(
                    '₹${order.total.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Items preview
              Text(
                '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              
              // First few items
              ...order.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        item.product.images.isNotEmpty ? item.product.images.first : '',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 32,
                            height: 32,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 16),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Qty: ${item.quantity}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              )),
              
              if (order.items.length > 2)
                Text(
                  '+${order.items.length - 2} more items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryGold,
                      ),
                ),
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderTrackingScreen(order: order),
                          ),
                        );
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                  if (order.status.canCancel) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showCancelDialog(context, order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Order> _filterOrders(List<Order> orders) {
    if (_selectedFilter == OrderFilters.all) {
      return orders;
    }

    return orders.where((order) {
      switch (_selectedFilter) {
        case OrderFilters.placed:
          return order.status == OrderStatus.placed;
        case OrderFilters.confirmed:
          return order.status == OrderStatus.confirmed;
        case OrderFilters.processing:
          return order.status == OrderStatus.processing;
        case OrderFilters.shipped:
          return order.status == OrderStatus.shipped;
        case OrderFilters.delivered:
          return order.status == OrderStatus.delivered;
        case OrderFilters.cancelled:
          return order.status == OrderStatus.cancelled;
        default:
          return true;
      }
    }).toList();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return OrderStatusColors.placed;
      case OrderStatus.confirmed:
        return OrderStatusColors.confirmed;
      case OrderStatus.processing:
        return OrderStatusColors.processing;
      case OrderStatus.shipped:
        return OrderStatusColors.shipped;
      case OrderStatus.outForDelivery:
        return OrderStatusColors.outForDelivery;
      case OrderStatus.delivered:
        return OrderStatusColors.delivered;
      case OrderStatus.cancelled:
        return OrderStatusColors.cancelled;
      case OrderStatus.returnRequested:
        return OrderStatusColors.returnRequested;
      case OrderStatus.returned:
        return OrderStatusColors.returned;
      case OrderStatus.refunded:
        return OrderStatusColors.refunded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCancelDialog(BuildContext context, Order order) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final orderProvider = context.read<OrderProvider>();
                await orderProvider.cancelOrder(
                  order.id,
                  reason: reasonController.text.isNotEmpty 
                      ? reasonController.text 
                      : 'Order cancelled by customer',
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling order: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
