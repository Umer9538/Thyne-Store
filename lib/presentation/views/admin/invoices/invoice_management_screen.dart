import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/api_service.dart';
import '../../../models/invoice.dart';
import '../../../../utils/theme.dart';

// Conditional imports for platform-specific code
import '../../../../data/services/csv_export_stub.dart'
    if (dart.library.io) '../../../../data/services/csv_export_io.dart'
    if (dart.library.html) '../../../../data/services/csv_export_web.dart' as csvExport;

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _selectedStatus;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getAdminInvoices(
        page: _currentPage,
        limit: _limit,
        status: _selectedStatus,
      );

      final data = response['data'] as Map<String, dynamic>;
      final invoicesData = data['invoices'] as List;
      final pagination = data['pagination'] as Map<String, dynamic>;

      setState(() {
        _invoices = invoicesData.map((json) => Invoice.fromJson(json)).toList();
        _totalPages = pagination['totalPages'] ?? 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoices: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final response = await ApiService.exportInvoicesCSV(
        status: _selectedStatus,
      );

      if (response.statusCode == 200) {
        final fileName = 'invoices_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
        final result = await csvExport.saveFile(response.bodyBytes, fileName, 'text/csv');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        }
      } else {
        throw Exception('Failed to export CSV');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting CSV: $e')),
        );
      }
    }
  }

  Future<void> _deleteInvoice(String invoiceId) async {
    try {
      await ApiService.deleteInvoice(invoiceId: invoiceId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted successfully')),
        );
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting invoice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV',
            onPressed: _exportToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Status',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...InvoiceStatus.values.map((status) => DropdownMenuItem(
                        value: status.value,
                        child: Text(status.displayName),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                        _currentPage = 1;
                      });
                      _loadInvoices();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Invoices list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 100,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No invoices found',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _invoices[index];
                          return _buildInvoiceCard(invoice);
                        },
                      ),
          ),

          // Pagination
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadInvoices();
                          }
                        : null,
                  ),
                  Text('Page $_currentPage of $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadInvoices();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          'Invoice #${invoice.invoiceNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Order: ${invoice.orderId} • ${_formatDate(invoice.invoiceDate)}',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getStatusColor(invoice.status)),
          ),
          child: Text(
            invoice.status.displayName,
            style: TextStyle(
              color: _getStatusColor(invoice.status),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Subtotal', '${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}'),
                _buildDetailRow('Tax', '${invoice.currency} ${invoice.tax.toStringAsFixed(2)}'),
                _buildDetailRow('Shipping', '${invoice.currency} ${invoice.shipping.toStringAsFixed(2)}'),
                if (invoice.discount > 0)
                  _buildDetailRow('Discount', '-${invoice.currency} ${invoice.discount.toStringAsFixed(2)}'),
                const Divider(),
                _buildDetailRow('Total', '${invoice.currency} ${invoice.total.toStringAsFixed(2)}', isBold: true),
                const SizedBox(height: 8),
                _buildDetailRow('Downloaded', invoice.isDownloaded ? 'Yes' : 'No'),
                if (invoice.downloadedAt != null)
                  _buildDetailRow('Downloaded At', _formatDateTime(invoice.downloadedAt!)),
                if (invoice.notes != null && invoice.notes!.isNotEmpty)
                  _buildDetailRow('Notes', invoice.notes!),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () => _showDeleteConfirmation(invoice.id),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                      onPressed: () => _showInvoiceDetails(invoice),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.issued:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.orange;
      case InvoiceStatus.refunded:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  void _showDeleteConfirmation(String invoiceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteInvoice(invoiceId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice #${invoice.invoiceNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Order ID', invoice.orderId),
              _buildDetailRow('Date', _formatDateTime(invoice.invoiceDate)),
              _buildDetailRow('Status', invoice.status.displayName),
              const Divider(),
              _buildDetailRow('Subtotal', '${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}'),
              _buildDetailRow('Tax', '${invoice.currency} ${invoice.tax.toStringAsFixed(2)}'),
              _buildDetailRow('Shipping', '${invoice.currency} ${invoice.shipping.toStringAsFixed(2)}'),
              if (invoice.discount > 0)
                _buildDetailRow('Discount', '-${invoice.currency} ${invoice.discount.toStringAsFixed(2)}'),
              const Divider(),
              _buildDetailRow('Total', '${invoice.currency} ${invoice.total.toStringAsFixed(2)}', isBold: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
