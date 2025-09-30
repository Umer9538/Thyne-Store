import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../utils/theme.dart';
import '../../services/pdf_service.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Order order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  bool _isProcessingAction = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.id}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, user),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'invoice',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('Download Invoice'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('Share Invoice'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, size: 20),
                    SizedBox(width: 8),
                    Text('Print Invoice'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Tracking Timeline
            if (widget.order.status.canTrack) ...[
              _buildTrackingTimeline(),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 16),

            // Order Details
            _buildOrderDetails(),
            const SizedBox(height: 16),

            // Items List
            _buildItemsList(),
            const SizedBox(height: 16),

            // Price Summary
            _buildPriceSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(widget.order.status)),
                  ),
                  child: Text(
                    widget.order.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(widget.order.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.order.trackingNumber != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.local_shipping, size: 20, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Tracking: ${widget.order.trackingNumber}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.order.trackingNumber!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tracking number copied')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final statuses = [
      OrderStatus.placed,
      OrderStatus.confirmed,
      OrderStatus.processing,
      OrderStatus.shipped,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];

    final currentIndex = statuses.indexOf(widget.order.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isCompleted = index <= currentIndex;
              final isActive = index == currentIndex;
              final isLast = index == statuses.length - 1;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted ? AppTheme.primaryGold : Colors.grey[300],
                              border: isActive ? Border.all(color: AppTheme.primaryGold, width: 3) : null,
                            ),
                            child: isCompleted
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 40,
                              color: isCompleted ? AppTheme.primaryGold : Colors.grey[300],
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.displayName,
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isCompleted ? Colors.black : Colors.grey,
                              ),
                            ),
                            if (isCompleted && _getStatusDate(status) != null)
                              Text(
                                _formatDateTime(_getStatusDate(status)!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final canCancel = widget.order.status.canCancel;
    final canReturn = widget.order.status.canReturn;

    if (!canCancel && !canReturn) return const SizedBox.shrink();

    return Row(
      children: [
        if (canCancel)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessingAction ? null : _cancelOrder,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (canCancel && canReturn) const SizedBox(width: 12),
        if (canReturn)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessingAction ? null : _returnOrder,
              icon: const Icon(Icons.assignment_return),
              label: const Text('Return Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Order Date', _formatDateTime(widget.order.createdAt)),
            _buildDetailRow('Payment Method', widget.order.paymentMethod),
            _buildDetailRow(
              'Shipping Address',
              '${widget.order.shippingAddress.street}\n'
              '${widget.order.shippingAddress.city}, ${widget.order.shippingAddress.state} ${widget.order.shippingAddress.zipCode}',
            ),
            if (widget.order.deliveredAt != null)
              _buildDetailRow('Delivered On', _formatDateTime(widget.order.deliveredAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${widget.order.items.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...widget.order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.images.first,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Qty: ${item.quantity} × \$${item.product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', widget.order.subtotal),
            _buildPriceRow('Tax', widget.order.tax),
            _buildPriceRow('Shipping', widget.order.shipping),
            if (widget.order.discount > 0)
              _buildPriceRow('Discount', -widget.order.discount, isDiscount: true),
            const Divider(),
            _buildPriceRow('Total', widget.order.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Colors.blue;
      case OrderStatus.confirmed:
        return Colors.indigo;
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.deepPurple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.returnRequested:
      case OrderStatus.returned:
        return Colors.orange;
      case OrderStatus.refunded:
        return Colors.grey;
    }
  }

  DateTime? _getStatusDate(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return widget.order.createdAt;
      case OrderStatus.processing:
        return widget.order.processedAt;
      case OrderStatus.shipped:
        return widget.order.shippedAt;
      case OrderStatus.delivered:
        return widget.order.deliveredAt;
      default:
        return null;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action, User user) async {
    setState(() => _isProcessingAction = true);

    try {
      final pdfData = await PdfService.generateInvoice(widget.order, user);

      switch (action) {
        case 'invoice':
          final file = await PdfService.savePdfToFile(pdfData, 'invoice_${widget.order.id}.pdf');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invoice saved to ${file.path}')),
          );
          break;
        case 'share':
          await PdfService.sharePdf(pdfData, 'invoice_${widget.order.id}.pdf');
          break;
        case 'print':
          await PdfService.printPdf(pdfData);
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isProcessingAction = false);
    }
  }

  void _cancelOrder() {
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
              setState(() => _isProcessingAction = true);
              
              try {
                final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                await orderProvider.cancelOrder(
                  widget.order.id,
                  reason: reasonController.text.isNotEmpty 
                      ? reasonController.text 
                      : 'Order cancelled by customer',
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled successfully')),
                  );
                  Navigator.pop(context); // Go back to orders list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling order: $e')),
                  );
                }
              } finally {
                setState(() => _isProcessingAction = false);
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

  void _returnOrder() {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for return:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Return reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a return reason')),
                );
                return;
              }
              
              Navigator.pop(context);
              setState(() => _isProcessingAction = true);
              
              try {
                final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                await orderProvider.returnOrder(widget.order.id, reasonController.text);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Return request submitted successfully')),
                  );
                  Navigator.pop(context); // Go back to orders list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error submitting return: $e')),
                  );
                }
              } finally {
                setState(() => _isProcessingAction = false);
              }
            },
            child: const Text('Submit Return'),
          ),
        ],
      ),
    );
  }
}