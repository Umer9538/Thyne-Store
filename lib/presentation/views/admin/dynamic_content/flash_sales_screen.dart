import 'package:flutter/material.dart';
import 'package:thyne_jewls/utils/theme.dart';
import 'package:thyne_jewls/data/services/api_service.dart';
import 'package:thyne_jewls/data/models/homepage.dart';
import 'package:thyne_jewls/presentation/views/admin/dynamic_content/edit_flash_sale_form.dart';

class FlashSalesScreen extends StatefulWidget {
  const FlashSalesScreen({super.key});

  @override
  State<FlashSalesScreen> createState() => _FlashSalesScreenState();
}

class _FlashSalesScreenState extends State<FlashSalesScreen> {
  bool _loading = true;
  List<FlashSale> _sales = [];
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Live, Ended

  @override
  void initState() {
    super.initState();
    _loadFlashSales();
  }

  Future<void> _loadFlashSales() async {
    setState(() => _loading = true);

    try {
      // Use getAllFlashSales to get all flash sales (including inactive) for admin management
      final response = await ApiService.getAllFlashSales();
      if (response['success'] == true && response['data'] != null) {
        final salesList = response['data'] as List;
        _sales = salesList
            .map((s) => FlashSale.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        // Fallback to homepage data if admin endpoint fails
        final homepageResponse = await ApiService.getHomepage();
        if (homepageResponse['success'] == true && homepageResponse['data'] != null) {
          final homepage = homepageResponse['data'] as Map<String, dynamic>;
          if (homepage['activeFlashSales'] != null) {
            _sales = (homepage['activeFlashSales'] as List)
                .map((s) => FlashSale.fromJson(s as Map<String, dynamic>))
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading flash sales: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading flash sales: $e')),
        );
      }
    }

    setState(() => _loading = false);
  }

  List<FlashSale> get _filteredSales {
    return _sales.where((sale) {
      // Filter by search query
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          sale.title.toLowerCase().contains(query) ||
          sale.description.toLowerCase().contains(query);

      // Filter by status
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Live' && sale.isLive) ||
          (_statusFilter == 'Ended' && !sale.isLive);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash Sales'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
            tooltip: 'Create Flash Sale',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Search and Filter Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade50,
                      child: Column(
                        children: [
                          // Search Bar
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search flash sales...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          // Status Filter Chips
                          Row(
                            children: [
                              _buildFilterChip('All', _statusFilter == 'All'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Live', _statusFilter == 'Live'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Ended', _statusFilter == 'Ended'),
                              const Spacer(),
                              Text(
                                '${_filteredSales.length} of ${_sales.length}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Flash Sales List
                    Expanded(
                      child: _filteredSales.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No flash sales found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try a different search term or filter',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadFlashSales,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredSales.length,
                                itemBuilder: (context, index) => _buildSaleCard(_filteredSales[index]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_fire_department, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Flash Sales',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create sales to boost revenue',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Flash Sale'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(FlashSale sale) {
    final timeRemaining = sale.timeRemaining;
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sale.isLive ? Colors.red.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sale.isLive ? Icons.local_fire_department : Icons.schedule,
                        size: 14,
                        color: sale.isLive ? Colors.red.shade700 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sale.isLive ? 'LIVE' : 'Ended',
                        style: TextStyle(
                          color: sale.isLive ? Colors.red.shade700 : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (sale.isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ends in ${hours}h ${minutes}m',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'end', child: Text('End Sale')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') _editSale(sale);
                    if (value == 'end') _endSale(sale);
                    if (value == 'delete') _deleteSale(sale);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sale.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              sale.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.inventory_2,
                  label: '${sale.productIds.length} Products',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.local_offer,
                  label: '-${sale.discount}%',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showCreateDialog() async {
    final result = await Navigator.pushNamed(context, '/admin/flash-sales/create');
    if (result == true && mounted) {
      _loadFlashSales();
    }
  }

  void _editSale(FlashSale sale) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditFlashSaleForm(sale: sale)),
    );
    if (result == true && mounted) {
      _loadFlashSales();
    }
  }

  void _endSale(FlashSale sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Sale?'),
        content: Text('Are you sure you want to end "${sale.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Sale'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final response = await ApiService.updateFlashSale(
          id: sale.id,
          title: sale.title,
          description: sale.description,
          bannerImage: sale.bannerImage,
          productIds: sale.productIds,
          discount: sale.discount,
          startTime: sale.startTime,
          endTime: DateTime.now(), // End the sale now
          isActive: false,
        );

        if (mounted) {
          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${sale.title} ended successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadFlashSales();
          } else {
            final errorMsg = response['error'] ?? response['message'] ?? 'Unknown error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $errorMsg')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error ending sale: $e')),
          );
        }
      }
    }
  }

  void _deleteSale(FlashSale sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sale?'),
        content: Text('Are you sure you want to delete "${sale.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final response = await ApiService.deleteFlashSale(sale.id);

        if (mounted) {
          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${sale.title} deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadFlashSales();
          } else {
            final errorMsg = response['error'] ?? response['message'] ?? 'Unknown error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $errorMsg')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting sale: $e')),
          );
        }
      }
    }
  }
}
