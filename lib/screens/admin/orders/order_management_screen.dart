import 'package:flutter/material.dart';
import '../../../utils/theme.dart';
import '../../../models/order.dart';
import '../../../services/api_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Orders'),
            Tab(text: 'Pending'),
            Tab(text: 'Processing'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportOrderReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search orders by ID or customer...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Order Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Status')),
                          DropdownMenuItem(value: 'placed', child: Text('Placed')),
                          DropdownMenuItem(value: 'processing', child: Text('Processing')),
                          DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                          DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Orders Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList('all'),
                _buildOrdersList('placed'),
                _buildOrdersList('processing'),
                _buildOrdersList('delivered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String statusFilter) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getAdminOrders(
        page: 1,
        limit: 50,
        status: statusFilter == 'all' ? null : statusFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load orders: ${snapshot.error}'),
          );
        }

        final data = snapshot.data ?? {};
        final orders = ((data['data'] ?? {})['orders'] ?? []) as List;

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No orders found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final o = orders[index] as Map<String, dynamic>;
            final adminOrder = AdminOrder(
              id: (o['id'] ?? o['_id'] ?? '').toString(),
              customerName: (o['userId'] ?? o['guestSessionId'] ?? 'Customer').toString(),
              customerPhone: '',
              customerEmail: '',
              orderDate: (o['createdAt'] ?? '').toString(),
              status: (o['status'] ?? '').toString(),
              totalAmount: ((o['total'] ?? 0) as num).toDouble(),
              itemCount: ((o['items'] ?? []) as List).length,
              paymentMethod: (o['paymentMethod'] ?? '').toString(),
              paymentStatus: (o['paymentStatus'] ?? '').toString(),
              shippingAddress: _formatAddress(o['shippingAddress'] as Map<String, dynamic>?),
              items: List<Map<String, dynamic>>.from(
                (o['items'] ?? []) as List,
              ),
            );
            return _buildOrderCard(adminOrder);
          },
        );
      },
    );
  }

  String _formatAddress(Map<String, dynamic>? a) {
    if (a == null) return '';
    final parts = [a['street'], a['city'], a['state'], a['zipCode'], a['country']]
        .where((e) => e != null && e.toString().isNotEmpty)
        .map((e) => e.toString())
        .toList();
    return parts.join(', ');
  }

  Widget _buildOrderCard(AdminOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Customer Info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order.customerName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.phone, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order.customerPhone,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Order Details
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order.orderDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.shopping_cart, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${order.itemCount} items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.currency_rupee, size: 16, color: AppTheme.primaryGold),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showOrderDetails(order),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showUpdateStatusDialog(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Update Status'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return Colors.blue;
      case 'processing':
        return AppTheme.warningAmber;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return AppTheme.successGreen;
      case 'cancelled':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  // Backend provides filtering via query params; remove local mock filtering

  void _showOrderDetails(AdminOrder order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Details #${order.id}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Information
                      _buildDetailSection('Customer Information', [
                        _buildDetailRow('Name', order.customerName),
                        _buildDetailRow('Phone', order.customerPhone),
                        _buildDetailRow('Email', order.customerEmail),
                      ]),
                      const SizedBox(height: 16),

                      // Shipping Address
                      _buildDetailSection('Shipping Address', [
                        Text(order.shippingAddress),
                      ]),
                      const SizedBox(height: 16),

                      // Order Items
                      _buildDetailSection('Order Items', [
                        ...order.items.map((item) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    item['image'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(item['name']),
                                subtitle: Text('Qty: ${item['quantity']}'),
                                trailing: Text(
                                  '₹${item['price']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGold,
                                  ),
                                ),
                              ),
                            )).toList(),
                      ]),
                      const SizedBox(height: 16),

                      // Payment Information
                      _buildDetailSection('Payment Information', [
                        _buildDetailRow('Payment Method', order.paymentMethod),
                        _buildDetailRow('Payment Status', order.paymentStatus),
                        _buildDetailRow('Total Amount', '₹${order.totalAmount.toStringAsFixed(0)}'),
                      ]),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold,
              ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(AdminOrder order) {
    String selectedStatus = order.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.id}'),
            Text('Customer: ${order.customerName}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'placed', child: Text('Placed')),
                DropdownMenuItem(value: 'processing', child: Text('Processing')),
                DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                selectedStatus = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.updateOrderStatus(
                  orderId: order.id,
                  status: selectedStatus,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order status updated successfully'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
                // Refresh orders
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating status: ${e.toString()}'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _exportOrderReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Order Report'),
        content: const Text('Generate and download order report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report exported successfully'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  List<AdminOrder> _getMockOrders() {
    return [
      AdminOrder(
        id: 'ORD001',
        customerName: 'Priya Sharma',
        customerPhone: '+91 9876543210',
        customerEmail: 'priya@example.com',
        orderDate: '2024-01-15',
        status: 'delivered',
        totalAmount: 25000,
        itemCount: 2,
        paymentMethod: 'Razorpay',
        paymentStatus: 'Paid',
        shippingAddress: '123 Main St, Mumbai, Maharashtra 400001',
        items: [
          {
            'name': 'Diamond Ring',
            'quantity': 1,
            'price': 20000,
            'image': 'https://example.com/ring.jpg',
          },
          {
            'name': 'Gold Earrings',
            'quantity': 1,
            'price': 5000,
            'image': 'https://example.com/earrings.jpg',
          },
        ],
      ),
      AdminOrder(
        id: 'ORD002',
        customerName: 'Rajesh Kumar',
        customerPhone: '+91 9876543211',
        customerEmail: 'rajesh@example.com',
        orderDate: '2024-01-14',
        status: 'processing',
        totalAmount: 15000,
        itemCount: 1,
        paymentMethod: 'Razorpay',
        paymentStatus: 'Paid',
        shippingAddress: '456 Park Avenue, Delhi, Delhi 110001',
        items: [
          {
            'name': 'Silver Necklace',
            'quantity': 1,
            'price': 15000,
            'image': 'https://example.com/necklace.jpg',
          },
        ],
      ),
      AdminOrder(
        id: 'ORD003',
        customerName: 'Anita Desai',
        customerPhone: '+91 9876543212',
        customerEmail: 'anita@example.com',
        orderDate: '2024-01-13',
        status: 'placed',
        totalAmount: 8000,
        itemCount: 2,
        paymentMethod: 'Razorpay',
        paymentStatus: 'Paid',
        shippingAddress: '789 Garden Road, Bangalore, Karnataka 560001',
        items: [
          {
            'name': 'Gold Bracelet',
            'quantity': 1,
            'price': 5000,
            'image': 'https://example.com/bracelet.jpg',
          },
          {
            'name': 'Silver Ring',
            'quantity': 1,
            'price': 3000,
            'image': 'https://example.com/silver-ring.jpg',
          },
        ],
      ),
    ];
  }
}

class AdminOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String orderDate;
  final String status;
  final double totalAmount;
  final int itemCount;
  final String paymentMethod;
  final String paymentStatus;
  final String shippingAddress;
  final List<Map<String, dynamic>> items;

  AdminOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    required this.itemCount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.shippingAddress,
    required this.items,
  });
}