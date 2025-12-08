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
  List<BundleDeal> _filteredBundles = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBundles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterBundles();
    });
  }

  void _filterBundles() {
    if (_searchQuery.isEmpty) {
      _filteredBundles = List.from(_bundles);
    } else {
      _filteredBundles = _bundles.where((bundle) {
        return bundle.title.toLowerCase().contains(_searchQuery) ||
            bundle.description.toLowerCase().contains(_searchQuery) ||
            bundle.category.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadBundles() async {
    setState(() => _loading = true);

    try {
      // Use admin endpoint to get all bundle deals (including inactive)
      final response = await ApiService.getAllBundleDeals();
      if (response['success'] == true && response['data'] != null) {
        final bundlesData = response['data'] as List;
        _bundles = bundlesData
            .map((b) => BundleDeal.fromJson(b as Map<String, dynamic>))
            .toList();
        _filterBundles();
      }
    } catch (e) {
      print('Error loading bundles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bundles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search bundles...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _bundles.isEmpty
                    ? _buildEmptyState()
                    : _filteredBundles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                                Text(
                                  'Try a different search term',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade500,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBundles,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredBundles.length,
                              itemBuilder: (context, index) => _buildBundleCard(_filteredBundles[index]),
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
    showDialog(
      context: context,
      builder: (context) => EditBundleDealForm(
        bundle: bundle,
        onSave: () {
          _loadBundles();
        },
      ),
    );
  }

  Future<void> _toggleBundle(BundleDeal bundle) async {
    try {
      final response = await ApiService.updateBundleDeal(
        id: bundle.id,
        title: bundle.title,
        description: bundle.description,
        items: bundle.items.map((item) => {
          'productId': item.productId,
          'quantity': item.quantity,
        }).toList(),
        bundlePrice: bundle.bundlePrice,
        stock: bundle.stock,
        isActive: !bundle.isActive,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${bundle.title} ${bundle.isActive ? "deactivated" : "activated"}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadBundles();
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to toggle bundle');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling bundle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBundle(BundleDeal bundle) async {
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
      try {
        final response = await ApiService.deleteBundleDeal(bundle.id);

        if (response['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${bundle.title} deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadBundles();
          }
        } else {
          throw Exception(response['error'] ?? 'Failed to delete bundle');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting bundle: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Edit Bundle Deal Form Widget
class EditBundleDealForm extends StatefulWidget {
  final BundleDeal bundle;
  final VoidCallback onSave;

  const EditBundleDealForm({
    super.key,
    required this.bundle,
    required this.onSave,
  });

  @override
  State<EditBundleDealForm> createState() => _EditBundleDealFormState();
}

class _EditBundleDealFormState extends State<EditBundleDealForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bundle.title);
    _descriptionController = TextEditingController(text: widget.bundle.description);
    _priceController = TextEditingController(text: widget.bundle.bundlePrice.toString());
    _stockController = TextEditingController(text: widget.bundle.stock.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final response = await ApiService.updateBundleDeal(
        id: widget.bundle.id,
        title: _titleController.text,
        description: _descriptionController.text,
        items: widget.bundle.items.map((item) => {
          'productId': item.productId,
          'quantity': item.quantity,
        }).toList(),
        bundlePrice: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        isActive: widget.bundle.isActive,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bundle Deal updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          widget.onSave();
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to update bundle');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating bundle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Edit Bundle Deal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Bundle Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter stock';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid stock';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
