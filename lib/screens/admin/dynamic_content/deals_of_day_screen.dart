import 'package:flutter/material.dart';
import 'package:thyne_jewls/utils/theme.dart';
import 'package:thyne_jewls/services/api_service.dart';
import 'package:thyne_jewls/models/homepage.dart';
import 'package:thyne_jewls/models/product.dart';
import 'package:intl/intl.dart';

class DealsOfDayScreen extends StatefulWidget {
  const DealsOfDayScreen({super.key});

  @override
  State<DealsOfDayScreen> createState() => _DealsOfDayScreenState();
}

class _DealsOfDayScreenState extends State<DealsOfDayScreen> {
  bool _loading = true;
  DealOfDay? _activeDeal;
  Product? _dealProduct;

  @override
  void initState() {
    super.initState();
    _loadActiveDeal();
  }

  Future<void> _loadActiveDeal() async {
    setState(() => _loading = true);

    try {
      final response = await ApiService.getHomepage();
      if (response['success'] == true && response['data'] != null) {
        final homepage = response['data'] as Map<String, dynamic>;
        if (homepage['dealOfDay'] != null) {
          _activeDeal = DealOfDay.fromJson(homepage['dealOfDay']);

          // Load product details
          final productResp = await ApiService.getProduct(productId: _activeDeal!.productId);
          if (productResp['success'] == true && productResp['data'] != null) {
            _dealProduct = Product.fromJson(productResp['data']);
          }
        }
      }
    } catch (e) {
      print('Error loading deal: $e');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deal of Day'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDealDialog(),
            tooltip: 'Create New Deal',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadActiveDeal,
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    if (_activeDeal == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flash_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Active Deal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a deal to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateDealDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Deal'),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActiveDealCard(),
        const SizedBox(height: 24),
        _buildDealStats(),
      ],
    );
  }

  Widget _buildActiveDealCard() {
    if (_activeDeal == null || _dealProduct == null) return const SizedBox();

    final timeRemaining = _activeDeal!.timeRemaining;
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.deepOrange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.flash_on, color: Colors.orange.shade700),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACTIVE DEAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ends in ${hours}h ${minutes}m',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Deal'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'end',
                      child: Row(
                        children: [
                          Icon(Icons.stop, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('End Deal', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') _showEditDealDialog();
                    if (value == 'end') _endDeal();
                  },
                ),
              ],
            ),
          ),

          // Product Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Product Image
                    if (_dealProduct!.images.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _dealProduct!.images.first,
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

                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dealProduct!.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dealProduct!.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Pricing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Original Price',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${_activeDeal!.originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${_activeDeal!.discountPercent}%',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_activeDeal!.dealPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Stock Info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        'Stock',
                        '${_activeDeal!.availableStock}/${_activeDeal!.stock}',
                        Icons.inventory,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoChip(
                        'Sold',
                        _activeDeal!.soldCount.toString(),
                        Icons.shopping_cart,
                      ),
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

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deal Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Start Time', DateFormat('MMM dd, yyyy HH:mm').format(_activeDeal!.startTime)),
            const Divider(),
            _buildStatRow('End Time', DateFormat('MMM dd, yyyy HH:mm').format(_activeDeal!.endTime)),
            const Divider(),
            _buildStatRow(
              'Conversion Rate',
              '${(_activeDeal!.soldCount / _activeDeal!.stock * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCreateDealDialog() async {
    final result = await Navigator.pushNamed(context, '/admin/deals-of-day/create');
    if (result == true && mounted) {
      _loadActiveDeal();
    }
  }

  void _showEditDealDialog() {
    // TODO: Navigate to edit deal form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Deal Form - Coming Soon')),
    );
  }

  void _endDeal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Deal?'),
        content: const Text('Are you sure you want to end this deal early?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Deal'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Call API to deactivate deal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deal ended successfully')),
      );
      _loadActiveDeal();
    }
  }
}
