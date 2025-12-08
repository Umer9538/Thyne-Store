import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../models/custom_order.dart';
import '../../../services/api_service.dart';
import '../../../utils/theme.dart';
import '../../../utils/csv_download_helper.dart';

class CustomOrdersScreen extends StatefulWidget {
  const CustomOrdersScreen({super.key});

  @override
  State<CustomOrdersScreen> createState() => _CustomOrdersScreenState();
}

class _CustomOrdersScreenState extends State<CustomOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<CustomOrder> _orders = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadOrders();
      }
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _getStatusFilter() {
    switch (_tabController.index) {
      case 0:
        return null; // All
      case 1:
        return 'pending_contact';
      case 2:
        return 'contacted';
      case 3:
        return 'confirmed';
      default:
        return null;
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getAdminCustomOrders(
        status: _getStatusFilter(),
        limit: 50,
      );

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final ordersData = (data?['orders'] ?? []) as List;

        setState(() {
          _orders = ordersData
              .map((o) => CustomOrder.fromJson(o as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to load orders';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading orders: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadCsv() async {
    if (_orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders to export')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating CSV...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Generate CSV content
      final csvContent = _generateCsvContent();
      final fileName = 'custom_orders_${DateTime.now().millisecondsSinceEpoch}.csv';

      Navigator.pop(context); // Close loading dialog

      final success = await CsvDownloadHelper.downloadCsv(
        csvContent: csvContent,
        fileName: fileName,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(kIsWeb ? 'CSV downloaded successfully' : 'CSV exported successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateCsvContent() {
    // CSV Headers
    final headers = [
      'Order ID',
      'Status',
      'Customer Name',
      'Phone',
      'Email',
      'Design Prompt',
      'Estimated Min Price',
      'Estimated Max Price',
      'Confirmed Price',
      'Customer Notes',
      'Admin Notes',
      'Created Date',
      'Contacted Date',
      'Confirmed Date',
      'Design Image URL',
    ];

    final rows = <List<String>>[headers];

    // Add data rows
    for (final order in _orders) {
      rows.add([
        order.id,
        order.status.displayName,
        _escapeCsvField(order.customerInfo.name),
        order.customerInfo.phone,
        order.customerInfo.email ?? '',
        _escapeCsvField(order.designInfo.prompt),
        order.priceInfo?.estimatedMin?.toString() ?? '',
        order.priceInfo?.estimatedMax?.toString() ?? '',
        order.priceInfo?.confirmedPrice?.toString() ?? '',
        _escapeCsvField(order.customerNotes ?? ''),
        _escapeCsvField(order.adminNotes ?? ''),
        _formatDateForCsv(order.createdAt),
        order.contactedAt != null ? _formatDateForCsv(order.contactedAt!) : '',
        order.confirmedAt != null ? _formatDateForCsv(order.confirmedAt!) : '',
        order.designInfo.imageUrl ?? '',
      ]);
    }

    // Convert to CSV string
    return rows.map((row) => row.join(',')).join('\n');
  }

  String _escapeCsvField(String field) {
    // Escape double quotes and wrap in quotes if needed
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  String _formatDateForCsv(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Orders'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Need Contact'),
            Tab(text: 'Contacted'),
            Tab(text: 'Confirmed'),
          ],
        ),
        actions: [
          // CSV Download button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download CSV',
            onPressed: _orders.isEmpty ? null : _downloadCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.sparkles, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No custom orders yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Custom orders from AI designs will appear here',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
    );
  }

  Widget _buildOrderCard(CustomOrder order) {
    final statusColor = _getStatusColor(order.status);
    final needsAction = order.status == CustomOrderStatus.pendingContact;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: needsAction
            ? BorderSide(color: Colors.orange.withOpacity(0.5), width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: needsAction ? Colors.orange.withOpacity(0.1) : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Order icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CupertinoIcons.sparkles, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Order info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Customer info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer
                Row(
                  children: [
                    Icon(CupertinoIcons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.customerInfo.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Phone
                Row(
                  children: [
                    Icon(CupertinoIcons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      order.customerInfo.phone,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _callCustomer(order.customerInfo.phone),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Call',
                          style: TextStyle(color: Colors.green, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                if (order.customerInfo.email != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(CupertinoIcons.mail, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        order.customerInfo.email!,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Design info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Design Request',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Design image thumbnail
                      if (order.designInfo.imageUrl != null)
                        Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: _buildDesignImage(order.designInfo.imageUrl!),
                          ),
                        ),
                      // Design prompt
                      Expanded(
                        child: Text(
                          order.designInfo.prompt,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Price info
          if (order.priceInfo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.tag, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      order.priceInfo!.confirmedPrice != null
                          ? 'Confirmed: ${order.priceInfo!.confirmedPriceFormatted}'
                          : 'Estimated: ${order.priceInfo!.estimatedRange}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Customer notes
          if (order.customerNotes != null && order.customerNotes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.text_bubble, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Customer Notes',
                          style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customerNotes!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionButtons(order),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final imageBytes = base64Decode(base64Data);
        return Image.memory(imageBytes, fit: BoxFit.cover);
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(CupertinoIcons.photo, color: Colors.grey),
        );
      }
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Icon(CupertinoIcons.photo, color: Colors.grey),
      ),
    );
  }

  Widget _buildActionButtons(CustomOrder order) {
    switch (order.status) {
      case CustomOrderStatus.pendingContact:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrderDetails(order),
                icon: const Icon(Icons.visibility),
                label: const Text('View'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _showMarkContactedDialog(order),
                icon: const Icon(CupertinoIcons.phone_badge_plus),
                label: const Text('Mark as Contacted'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case CustomOrderStatus.contacted:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrderDetails(order),
                icon: const Icon(Icons.visibility),
                label: const Text('View'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _showConfirmOrderDialog(order),
                icon: const Icon(CupertinoIcons.checkmark_circle),
                label: const Text('Confirm Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case CustomOrderStatus.confirmed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrderDetails(order),
                icon: const Icon(Icons.visibility),
                label: const Text('View'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus(order, 'processing'),
                icon: const Icon(CupertinoIcons.hammer),
                label: const Text('Start Processing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case CustomOrderStatus.processing:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrderDetails(order),
                icon: const Icon(Icons.visibility),
                label: const Text('View'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _showShipOrderDialog(order),
                icon: const Icon(CupertinoIcons.paperplane),
                label: const Text('Ship Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case CustomOrderStatus.shipped:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrderDetails(order),
                icon: const Icon(Icons.visibility),
                label: const Text('View'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus(order, 'delivered'),
                icon: const Icon(CupertinoIcons.checkmark_seal),
                label: const Text('Mark Delivered'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      default:
        return OutlinedButton.icon(
          onPressed: () => _showOrderDetails(order),
          icon: const Icon(Icons.visibility),
          label: const Text('View Details'),
        );
    }
  }

  Color _getStatusColor(CustomOrderStatus status) {
    switch (status) {
      case CustomOrderStatus.pendingContact:
        return Colors.orange;
      case CustomOrderStatus.contacted:
        return Colors.blue;
      case CustomOrderStatus.confirmed:
        return Colors.green;
      case CustomOrderStatus.processing:
        return AppTheme.primaryGold;
      case CustomOrderStatus.shipped:
        return Colors.purple;
      case CustomOrderStatus.delivered:
        return Colors.teal;
      case CustomOrderStatus.cancelled:
        return Colors.red;
    }
  }

  void _callCustomer(String phone) {
    // In a real app, use url_launcher to make a call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phone...')),
    );
  }

  void _showOrderDetails(CustomOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full design image
                    if (order.designInfo.imageUrl != null)
                      Container(
                        height: 250,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: _buildDesignImage(order.designInfo.imageUrl!),
                        ),
                      ),

                    // Full prompt
                    _buildDetailSection('Design Prompt', order.designInfo.prompt),
                    if (order.designInfo.imageDescription != null)
                      _buildDetailSection('AI Description', order.designInfo.imageDescription!),

                    const SizedBox(height: 16),
                    _buildDetailSection('Customer', order.customerInfo.name),
                    _buildDetailSection('Phone', order.customerInfo.phone),
                    if (order.customerInfo.email != null)
                      _buildDetailSection('Email', order.customerInfo.email!),
                    if (order.customerNotes != null)
                      _buildDetailSection('Customer Notes', order.customerNotes!),
                    if (order.adminNotes != null)
                      _buildDetailSection('Admin Notes', order.adminNotes!),

                    const SizedBox(height: 16),
                    _buildDetailSection('Status', order.status.displayName),
                    _buildDetailSection('Created', _formatDate(order.createdAt)),
                    if (order.contactedAt != null)
                      _buildDetailSection('Contacted', _formatDate(order.contactedAt!)),
                    if (order.confirmedAt != null)
                      _buildDetailSection('Confirmed', _formatDate(order.confirmedAt!)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _showMarkContactedDialog(CustomOrder order) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(CupertinoIcons.phone_badge_plus, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('Mark as Contacted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.customerInfo.name}'),
            Text('Phone: ${order.customerInfo.phone}'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Contact Notes (Optional)',
                hintText: 'Summary of conversation...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
              Navigator.pop(context);
              await _updateStatus(
                order,
                'contacted',
                adminNotes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Contacted'),
          ),
        ],
      ),
    );
  }

  void _showConfirmOrderDialog(CustomOrder order) {
    final priceController = TextEditingController(
      text: order.priceInfo?.estimatedMax?.toString() ?? '',
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle, color: Colors.green),
            const SizedBox(width: 12),
            const Text('Confirm Order'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.customerInfo.name}'),
            if (order.priceInfo != null)
              Text('Estimated: ${order.priceInfo!.estimatedRange}'),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Final Price (₹) *',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
              final price = double.tryParse(priceController.text);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid price')),
                );
                return;
              }

              Navigator.pop(context);
              await _updateStatus(
                order,
                'confirmed',
                confirmedPrice: price,
                adminNotes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showShipOrderDialog(CustomOrder order) {
    final trackingController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.paperplane, color: Colors.purple),
            const SizedBox(width: 12),
            const Text('Ship Order'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: trackingController,
              decoration: InputDecoration(
                labelText: 'Tracking Number (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
              Navigator.pop(context);
              await _updateStatus(
                order,
                'shipped',
                trackingNumber: trackingController.text.trim().isEmpty
                    ? null
                    : trackingController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ship'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    CustomOrder order,
    String status, {
    String? adminNotes,
    double? confirmedPrice,
    String? trackingNumber,
  }) async {
    try {
      final result = await ApiService.updateCustomOrderStatus(
        orderId: order.id,
        status: status,
        adminNotes: adminNotes,
        confirmedPrice: confirmedPrice,
        trackingNumber: trackingNumber,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to ${CustomOrderStatus.fromString(status).displayName}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to update order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
