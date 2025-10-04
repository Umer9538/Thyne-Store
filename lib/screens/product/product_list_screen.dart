import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../utils/theme.dart';
import '../../utils/mock_data.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'filter_bottom_sheet.dart';

class ProductListScreen extends StatefulWidget {
  final String? category;

  const ProductListScreen({
    super.key,
    this.category,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _isGridView = true;
  String _sortBy = 'popularity';
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (widget.category != null) {
        productProvider.filterByCategory(widget.category!);
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort By',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildSortOption('Popularity', 'popularity'),
                _buildSortOption('Price: Low to High', 'price_low'),
                _buildSortOption('Price: High to Low', 'price_high'),
                _buildSortOption('Customer Rating', 'rating'),
                _buildSortOption('Newest First', 'newest'),
                _buildSortOption('Name: A to Z', 'name_asc'),
                _buildSortOption('Name: Z to A', 'name_desc'),
                _buildSortOption('Discount: High to Low', 'discount'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: _sortBy == value
          ? const Icon(Icons.check, color: AppTheme.primaryGold)
          : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Provider.of<ProductProvider>(context, listen: false).sortProducts(value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category ?? 'All Products'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Chips
          if (widget.category == null)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: MockData.categories.length,
                itemBuilder: (context, index) {
                  final category = MockData.categories[index];
                  final isSelected = productProvider.selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        productProvider.filterByCategory(category);
                      },
                      selectedColor: AppTheme.primaryGold,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Gender Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickFilterChip('All', null, true),
                const SizedBox(width: 8),
                _buildQuickFilterChip('Men', 'Male', false, Icons.man),
                const SizedBox(width: 8),
                _buildQuickFilterChip('Women', 'Female', false, Icons.woman),
                const SizedBox(width: 8),
                _buildQuickFilterChip('Unisex', 'Unisex', false, Icons.people),
              ],
            ),
          ),

          // Filter and Sort Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${productProvider.products.length} Products',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showSortOptions,
                  icon: const Icon(Icons.sort),
                  label: const Text('Sort'),
                ),
                TextButton.icon(
                  onPressed: _showFilterBottomSheet,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                ),
              ],
            ),
          ),

          // Product Grid/List
          Expanded(
            child: productProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGold,
                    ),
                  )
                : productProvider.products.isEmpty
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
                              'No products found',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                productProvider.clearFilters();
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      )
                    : _isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: productProvider.products.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.products[index];
                              return ProductCard(
                                product: product,
                                showDiscount: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(
                                        product: product,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: productProvider.products.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.products[index];
                              return _buildListItem(product);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.images.first,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGold,
                              ),
                        ),
                        if (product.originalPrice != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₹${product.originalPrice!.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Provider.of<WishlistProvider>(context).isInWishlist(product.id)
                      ? Icons.favorite
                      : Icons.favorite_outline,
                  color: AppTheme.errorRed,
                ),
                onPressed: () {
                  Provider.of<WishlistProvider>(context, listen: false)
                      .toggleWishlist(product.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String title, String? gender, bool isAll, [IconData? icon]) {
    final isSelected = _selectedGender == gender || (isAll && _selectedGender == null);

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.primaryGold,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedGender = isAll ? null : gender;
        });

        // Apply gender filter
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        if (isAll) {
          productProvider.clearGenderFilter();
        } else {
          productProvider.filterByGender(gender!);
        }
      },
      selectedColor: AppTheme.primaryGold,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontSize: 13,
      ),
    );
  }
}