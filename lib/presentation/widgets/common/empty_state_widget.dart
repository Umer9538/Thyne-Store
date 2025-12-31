import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/core.dart';
import 'app_buttons.dart';

/// A widget to display when there's no data or content.
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imagePath;
  final String? actionText;
  final VoidCallback? onAction;
  final double iconSize;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imagePath,
    this.actionText,
    this.onAction,
    this.iconSize = 80.0,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultIconColor = iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.5);

    return Center(
      child: Padding(
        padding: AppDimensions.paddingAll24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 150,
                height: 150,
              )
            else if (icon != null)
              Icon(
                icon,
                size: iconSize,
                color: defaultIconColor,
              ),
            AppDimensions.verticalSpace24,
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              AppDimensions.verticalSpace8,
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              AppDimensions.verticalSpace24,
              AppPrimaryButton(
                text: actionText!,
                onPressed: onAction,
                isFullWidth: false,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pre-built empty state for cart.
class EmptyCartWidget extends StatelessWidget {
  final VoidCallback? onContinueShopping;

  const EmptyCartWidget({
    super.key,
    this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.shopping_cart_outlined,
      title: AppStrings.cartEmpty,
      subtitle: AppStrings.cartEmptySubtitle,
      actionText: AppStrings.continueShopping,
      onAction: onContinueShopping,
    );
  }
}

/// Pre-built empty state for wishlist.
class EmptyWishlistWidget extends StatelessWidget {
  final VoidCallback? onBrowseProducts;

  const EmptyWishlistWidget({
    super.key,
    this.onBrowseProducts,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.favorite_outline,
      title: AppStrings.noItemsInWishlist,
      subtitle: 'Save items you love to your wishlist',
      actionText: 'Browse Products',
      onAction: onBrowseProducts,
    );
  }
}

/// Pre-built empty state for orders.
class EmptyOrdersWidget extends StatelessWidget {
  final VoidCallback? onStartShopping;

  const EmptyOrdersWidget({
    super.key,
    this.onStartShopping,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: AppStrings.noOrders,
      subtitle: 'Your order history will appear here',
      actionText: 'Start Shopping',
      onAction: onStartShopping,
    );
  }
}

/// Pre-built empty state for search results.
class EmptySearchWidget extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback? onClearSearch;

  const EmptySearchWidget({
    super.key,
    this.searchQuery,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: AppStrings.noSearchResults,
      subtitle: searchQuery != null
          ? 'No results found for "$searchQuery"'
          : 'Try a different search term',
      actionText: onClearSearch != null ? 'Clear Search' : null,
      onAction: onClearSearch,
    );
  }
}

/// Pre-built empty state for products.
class EmptyProductsWidget extends StatelessWidget {
  final VoidCallback? onRefresh;

  const EmptyProductsWidget({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      title: AppStrings.noProducts,
      subtitle: 'No products available at the moment',
      actionText: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
    );
  }
}

/// Pre-built empty state for notifications.
class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.notifications_none,
      title: AppStrings.noNotifications,
      subtitle: 'You\'re all caught up!',
    );
  }
}

/// Pre-built empty state for addresses.
class EmptyAddressesWidget extends StatelessWidget {
  final VoidCallback? onAddAddress;

  const EmptyAddressesWidget({
    super.key,
    this.onAddAddress,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.location_off_outlined,
      title: AppStrings.noAddresses,
      subtitle: 'Add an address for faster checkout',
      actionText: 'Add Address',
      onAction: onAddAddress,
    );
  }
}

/// Generic "No Data" empty state.
class NoDataWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const NoDataWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.inbox_outlined,
      title: message ?? 'No Data',
      subtitle: 'There\'s nothing here yet',
      actionText: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }
}
