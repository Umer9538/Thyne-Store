import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../viewmodels/product_provider.dart';
import '../viewmodels/wishlist_provider.dart';
import '../widgets/product_card.dart';
import '../views/product/product_detail_screen.dart';
import '../constants/sort_options.dart';
import '../constants/filter_options.dart';
import '../constants/app_spacing.dart';

/// A widget that displays content as an overlay on top of the current screen
/// instead of navigating to a new route. This creates a "page upon page" effect.
class OverlayPage extends StatelessWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onClose;

  const OverlayPage({
    super.key,
    required this.child,
    this.title,
    this.onClose,
  });

  /// Shows an overlay page on top of the current screen
  static void show({
    required BuildContext context,
    required Widget child,
    String? title,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return OverlayPage(
          title: title,
          onClose: () => Navigator.of(context).pop(),
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Fade in with slight scale up - appears on the same screen
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));

        final scaleAnimation = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width - 40,
        height: MediaQuery.of(context).size.height - 40,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Custom app bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  if (title != null) ...[
                    Expanded(
                      child: Text(
                        title!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    color: AppTheme.primaryGold,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A version of ProductListScreen content that works well in an overlay
class OverlayProductList extends StatefulWidget {
  final String? category;

  const OverlayProductList({
    super.key,
    this.category,
  });

  @override
  State<OverlayProductList> createState() => _OverlayProductListState();
}

class _OverlayProductListState extends State<OverlayProductList> {
  bool _isGridView = true;
  SortOption _sortBy = SortOption.popularity;
  GenderFilter _selectedGender = GenderFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.category != null) {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        productProvider.filterByCategory(widget.category!);
      }
    });
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

    return Column(
      children: [
        // Gender Filter Chips
        Container(
          height: AppSpacing.filterBarHeight,
          padding: AppSpacing.paddingVerticalSm,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.paddingHorizontalLg,
            itemCount: GenderFilter.values.length - 1, // Exclude unisex
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
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              TextButton.icon(
                onPressed: _showSortOptions,
                icon: const Icon(Icons.sort),
                label: const Text('Sort'),
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
                  width: 80,
                  height: 80,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          Text(filter.displayName),
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
