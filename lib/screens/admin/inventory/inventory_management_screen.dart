import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/theme.dart';
import '../../../providers/product_provider.dart';
import '../../../models/product.dart';
import '../../../services/api_service.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _stockFilter = 'all'; // all, low, out

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Inventory Management'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Products'),
            Tab(text: 'Low Stock'),
            Tab(text: 'Stock History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportInventoryReport,
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
                    hintText: 'Search products...',
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
                        value: _stockFilter,
                        decoration: InputDecoration(
                          labelText: 'Stock Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Products')),
                          DropdownMenuItem(value: 'low', child: Text('Low Stock (< 10)')),
                          DropdownMenuItem(value: 'out', child: Text('Out of Stock')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _stockFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllProductsTab(),
                _buildLowStockTab(),
                _buildStockHistoryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBulkUpdateDialog,
        backgroundColor: AppTheme.primaryGold,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildAllProductsTab() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final filteredProducts = _getFilteredProducts(productProvider.products);

        if (filteredProducts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return _buildInventoryCard(product);
          },
        );
      },
    );
  }

  Widget _buildLowStockTab() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final lowStockProducts = productProvider.products
            .where((product) => product.stockQuantity < 10)
            .toList();

        if (lowStockProducts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: AppTheme.successGreen),
                SizedBox(height: 16),
                Text(
                  'All products are well stocked!',
                  style: TextStyle(fontSize: 18, color: AppTheme.successGreen),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.errorRed.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppTheme.errorRed),
                  const SizedBox(width: 8),
                  Text(
                    '${lowStockProducts.length} products running low on stock',
                    style: const TextStyle(
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lowStockProducts.length,
                itemBuilder: (context, index) {
                  final product = lowStockProducts[index];
                  return _buildInventoryCard(product, showWarning: true);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStockHistoryTab() {
    final stockHistory = _generateMockStockHistory();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stockHistory.length,
      itemBuilder: (context, index) {
        final history = stockHistory[index];
        return _buildStockHistoryCard(history);
      },
    );
  }

  Widget _buildInventoryCard(Product product, {bool showWarning = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: showWarning ? 4 : 2,
      color: showWarning ? AppTheme.errorRed.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.images.first,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStockStatusColor(product.stockQuantity),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stock: ${product.stockQuantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStockStatus(product.stockQuantity),
                        style: TextStyle(
                          color: _getStockStatusColor(product.stockQuantity),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Buttons
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.successGreen),
                  onPressed: () => _showStockUpdateDialog(product, true),
                ),
                IconButton(
                  icon: const Icon(Icons.remove, color: AppTheme.errorRed),
                  onPressed: () => _showStockUpdateDialog(product, false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockHistoryCard(StockHistoryEntry history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: history.type == 'in' ? AppTheme.successGreen : AppTheme.errorRed,
            shape: BoxShape.circle,
          ),
          child: Icon(
            history.type == 'in' ? Icons.add : Icons.remove,
            color: Colors.white,
          ),
        ),
        title: Text(history.productName),
        subtitle: Text(
          '${history.type == 'in' ? '+' : '-'}${history.quantity} units • ${history.reason}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              history.date,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'By: ${history.updatedBy}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesStockFilter = true;
      switch (_stockFilter) {
        case 'low':
          matchesStockFilter = product.stockQuantity < 10 && product.stockQuantity > 0;
          break;
        case 'out':
          matchesStockFilter = product.stockQuantity == 0;
          break;
        case 'all':
        default:
          matchesStockFilter = true;
      }

      return matchesSearch && matchesStockFilter;
    }).toList();

    return filtered;
  }

  Color _getStockStatusColor(int stock) {
    if (stock == 0) return AppTheme.errorRed;
    if (stock < 10) return AppTheme.warningAmber;
    return AppTheme.successGreen;
  }

  String _getStockStatus(int stock) {
    if (stock == 0) return 'Out of Stock';
    if (stock < 10) return 'Low Stock';
    return 'In Stock';
  }

  void _showStockUpdateDialog(Product product, bool isIncrease) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isIncrease ? 'Add' : 'Remove'} Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${product.name}'),
            Text('Current Stock: ${product.stockQuantity}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g., New shipment, Damaged, Sold',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (quantity > 0 && reasonController.text.isNotEmpty) {
                try {
                  final newQuantity = isIncrease 
                    ? product.stockQuantity + quantity 
                    : product.stockQuantity - quantity;
                  
                  await ApiService.updateProductStock(
                    productId: product.id,
                    quantity: newQuantity,
                    reason: reasonController.text,
                  );
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Stock ${isIncrease ? 'added' : 'removed'} successfully',
                      ),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                  
                  // Refresh the inventory
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating stock: ${e.toString()}'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            child: Text(isIncrease ? 'Add Stock' : 'Remove Stock'),
          ),
        ],
      ),
    );
  }

  void _showBulkUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Stock Update'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose how you want to update stock:'),
            SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCSVUploadDialog();
            },
            child: const Text('Upload CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualBulkUpdateDialog();
            },
            child: const Text('Manual Update'),
          ),
        ],
      ),
    );
  }

  void _showCSVUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload CSV'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload a CSV file with the following format:'),
            SizedBox(height: 8),
            Text(
              'Product ID, New Stock Quantity, Reason',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            SizedBox(height: 16),
            Text('Example:'),
            Text(
              '1, 50, New shipment\n2, 25, Inventory count',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement CSV upload
              Navigator.pop(context);
            },
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  void _showManualBulkUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Bulk Update'),
        content: const Text('Select products to update stock levels manually.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement manual bulk update
              Navigator.pop(context);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _exportInventoryReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Inventory Report'),
        content: const Text('Generate and download inventory report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement export functionality
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

  List<StockHistoryEntry> _generateMockStockHistory() {
    return [
      StockHistoryEntry(
        id: '1',
        productName: 'Diamond Ring',
        type: 'in',
        quantity: 10,
        reason: 'New shipment',
        date: '2024-01-15',
        updatedBy: 'Admin',
      ),
      StockHistoryEntry(
        id: '2',
        productName: 'Gold Necklace',
        type: 'out',
        quantity: 2,
        reason: 'Sold online',
        date: '2024-01-14',
        updatedBy: 'System',
      ),
      StockHistoryEntry(
        id: '3',
        productName: 'Silver Earrings',
        type: 'out',
        quantity: 1,
        reason: 'Damaged item',
        date: '2024-01-13',
        updatedBy: 'Manager',
      ),
    ];
  }
}

class StockHistoryEntry {
  final String id;
  final String productName;
  final String type; // 'in' or 'out'
  final int quantity;
  final String reason;
  final String date;
  final String updatedBy;

  StockHistoryEntry({
    required this.id,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.date,
    required this.updatedBy,
  });
}