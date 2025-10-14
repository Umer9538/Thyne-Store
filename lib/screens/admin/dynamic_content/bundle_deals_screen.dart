import 'package:flutter/material.dart';
import 'package:thyne_jewls/utils/theme.dart';
import 'package:thyne_jewls/services/api_service.dart';
import 'package:thyne_jewls/models/homepage.dart';

class BundleDealsScreen extends StatefulWidget {
  const BundleDealsScreen({super.key});

  @override
  State<BundleDealsScreen> createState() => _BundleDealsScreenState();
}

class _BundleDealsScreenState extends State<BundleDealsScreen> {
  bool _loading = true;
  List<BundleDeal> _bundles = [];

  @override
  void initState() {
    super.initState();
    _loadBundles();
  }

  Future<void> _loadBundles() async {
    setState(() => _loading = true);

    try {
      final response = await ApiService.getHomepage();
      if (response['success'] == true && response['data'] != null) {
        final homepage = response['data'] as Map<String, dynamic>;
        if (homepage['bundleDeals'] != null) {
          _bundles = (homepage['bundleDeals'] as List)
              .map((b) => BundleDeal.fromJson(b))
              .toList();
        }
      }
    } catch (e) {
      print('Error loading bundles: $e');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bundle Deals'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateBundleDialog,
            tooltip: 'Create Bundle',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bundles.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBundles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bundles.length,
                    itemBuilder: (context, index) => _buildBundleCard(_bundles[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Bundle Deals',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create bundles to increase sales',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateBundleDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Bundle'),
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

  Widget _buildBundleCard(BundleDeal bundle) {
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bundle.category.toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bundle.isLive ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        bundle.isLive ? Icons.check_circle : Icons.pause_circle,
                        size: 14,
                        color: bundle.isLive ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        bundle.isLive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: bundle.isLive ? Colors.green.shade700 : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'toggle', child: Text('Toggle Active')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') _editBundle(bundle);
                    if (value == 'toggle') _toggleBundle(bundle);
                    if (value == 'delete') _deleteBundle(bundle);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bundle.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              bundle.description,
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
                  label: '${bundle.items.length} Items',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.local_offer,
                  label: '-${bundle.discountPercent}%',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.shopping_cart,
                  label: '${bundle.soldCount} Sold',
                  color: Colors.green,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Original Price',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${bundle.originalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Bundle Price',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${bundle.bundlePrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.savings, color: Colors.green.shade700, size: 16),
                      Text(
                        'Save \$${bundle.savings.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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

  void _showCreateBundleDialog() async {
    final result = await Navigator.pushNamed(context, '/admin/bundle-deals/create');
    if (result == true && mounted) {
      _loadBundles();
    }
  }

  void _editBundle(BundleDeal bundle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${bundle.title} - Coming Soon')),
    );
  }

  void _toggleBundle(BundleDeal bundle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${bundle.title} ${bundle.isActive ? "deactivated" : "activated"}'),
      ),
    );
  }

  void _deleteBundle(BundleDeal bundle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bundle?'),
        content: Text('Are you sure you want to delete "${bundle.title}"?'),
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

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${bundle.title} deleted')),
      );
      _loadBundles();
    }
  }
}
