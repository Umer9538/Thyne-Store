import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';
import '../../utils/mock_data.dart';
import '../../widgets/product_card.dart';
import '../../constants/sort_options.dart';
import '../../constants/filter_options.dart';
import '../../constants/app_spacing.dart';
import 'product_detail_screen.dart';
import 'filter_bottom_sheet.dart';

class ProductListScreen extends StatefulWidget {
  final String? category;
  final bool isEmbedded;
  final int? minPrice;
  final int? maxPrice;
  final String? gender;
  final String? searchQuery;

  const ProductListScreen({
    super.key,
    this.category,
    this.isEmbedded = false,
    this.minPrice,
    this.maxPrice,
    this.gender,
    this.searchQuery,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _isGridView = true;
  SortOption _sortBy = SortOption.popularity;
  GenderFilter _selectedGender = GenderFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      // Apply search query filter (takes priority)
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        productProvider.searchProducts(widget.searchQuery!);
        return; // Don't apply other filters when searching
      }

      // Apply category filter
      if (widget.category != null) {
        productProvider.filterByCategory(widget.category!);
      }

      // Apply gender filter
      if (widget.gender != null) {
        setState(() => _selectedGender = GenderFilter.fromValue(widget.gender));
        productProvider.filterByGender(widget.gender!);
      }

      // Apply price range filter
      if (widget.minPrice != null || widget.maxPrice != null) {
        productProvider.filterByPriceRange(
          minPrice: widget.minPrice?.toDouble(),
          maxPrice: widget.maxPrice?.toDouble(),
        );
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
            padding: AppSpacing.paddingAllLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort By',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                AppSpacing.verticalLg,
                ...SortOption.values.map((option) => _buildSortOption(option)),
                AppSpacing.verticalLg,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(SortOption option) {
    final isSelected = _sortBy == option;
    return ListTile(
      title: Text(option.displayName),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryGold)
          : null,
      onTap: () {
        setState(() {
          _sortBy = option;
        });
        Provider.of<ProductProvider>(context, listen: false).sortProducts(option.value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    final body = Column(
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
            height: AppSpacing.filterBarHeight,
            padding: AppSpacing.paddingVerticalSm,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.paddingHorizontalLg,
              itemCount: GenderFilter.values.length - 1, // Exclude unisex for now
              separatorBuilder: (_, __) => AppSpacing.horizontalSm,
              itemBuilder: (context, index) {
                final filter = GenderFilter.values[index];
                return _buildGenderFilterChip(filter);
              },
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
                            padding: EdgeInsets.all(Responsive.padding(context, 16)),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: Responsive.gridCount(context, mobile: 2, tablet: 3, desktop: 4),
                              childAspectRatio: 0.75,
                              crossAxisSpacing: Responsive.spacing(context, 12),
                              mainAxisSpacing: Responsive.spacing(context, 12),
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
      );

    // If embedded, return body directly without Scaffold
    if (widget.isEmbedded) {
      return body;
    }

    // Otherwise, return with Scaffold and AppBar
    // Determine title based on context
    String appBarTitle;
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      appBarTitle = 'Results for "${widget.searchQuery}"';
    } else if (widget.category != null) {
      appBarTitle = widget.category!;
    } else {
      appBarTitle = 'All Products';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
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
      body: body,
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

  Widget _buildGenderFilterChip(GenderFilter filter) {
    final isSelected = _selectedGender == filter;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filter.icon != null) ...[
            Icon(
              filter.icon,
              size: AppSpacing.iconSm,
              color: isSelected ? Colors.white : AppTheme.primaryGold,
            ),
            AppSpacing.horizontalXs,
          ],
          Flexible(
            child: Text(
              filter.displayName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedGender = filter;
        });

        // Apply gender filter
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        if (filter.isAll) {
          productProvider.clearGenderFilter();
        } else {
          productProvider.filterByGender(filter.value!);
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