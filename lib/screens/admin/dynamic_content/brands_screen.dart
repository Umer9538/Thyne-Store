import 'package:flutter/material.dart';
import 'package:thyne_jewls/utils/theme.dart';
import 'package:thyne_jewls/services/api_service.dart';
import 'package:thyne_jewls/models/homepage.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  bool _loading = true;
  List<Brand> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() => _loading = true);

    try {
      final response = await ApiService.getHomepage();
      if (response['success'] == true && response['data'] != null) {
        final homepage = response['data'] as Map<String, dynamic>;
        if (homepage['brands'] != null) {
          _brands = (homepage['brands'] as List)
              .map((b) => Brand.fromJson(b))
              .toList();
        }
      }
    } catch (e) {
      print('Error loading brands: $e');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
            tooltip: 'Add Brand',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _brands.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBrands,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _brands.length,
                    itemBuilder: (context, index) => _buildBrandCard(_brands[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Brands',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add brands to showcase on homepage',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Brand'),
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

  Widget _buildBrandCard(Brand brand) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Brand Logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: brand.logo.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        brand.logo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.business, size: 32, color: Colors.grey.shade400);
                        },
                      ),
                    )
                  : Icon(Icons.business, size: 32, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 16),

            // Brand Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    brand.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: brand.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              brand.isActive ? Icons.check_circle : Icons.pause_circle,
                              size: 14,
                              color: brand.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              brand.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: brand.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Priority: ${brand.priority}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
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
                if (value == 'edit') _editBrand(brand);
                if (value == 'toggle') _toggleBrand(brand);
                if (value == 'delete') _deleteBrand(brand);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Brand Form - Coming Soon')),
    );
  }

  void _editBrand(Brand brand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${brand.name} - Coming Soon')),
    );
  }

  void _toggleBrand(Brand brand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${brand.name} ${brand.isActive ? "deactivated" : "activated"}'),
      ),
    );
  }

  void _deleteBrand(Brand brand) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Brand?'),
        content: Text('Are you sure you want to delete "${brand.name}"?'),
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
        SnackBar(content: Text('${brand.name} deleted')),
      );
      _loadBrands();
    }
  }
}
