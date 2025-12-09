import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Enum representing the main navigation tabs in the app.
enum NavigationTab {
  shop('shop', 'Shop', CupertinoIcons.bag, CupertinoIcons.bag_fill),
  community('community', 'Community', CupertinoIcons.person_2, CupertinoIcons.person_2_fill),
  create('create', 'Create', CupertinoIcons.sparkles, CupertinoIcons.sparkles);

  final String value;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavigationTab(this.value, this.label, this.icon, this.activeIcon);

  /// Get tab from value string
  static NavigationTab fromValue(String value) {
    return NavigationTab.values.firstWhere(
      (tab) => tab.value == value,
      orElse: () => NavigationTab.shop,
    );
  }

  /// Check if this tab matches a value
  bool matches(String value) => this.value == value;
}

/// Enum for shop sub-filters
enum ShopFilter {
  all('all', 'All'),
  trending('trending', 'Trending'),
  newArrivals('new', 'New Arrivals'),
  bestsellers('bestsellers', 'Bestsellers'),
  offers('offers', 'Offers');

  final String value;
  final String displayName;

  const ShopFilter(this.value, this.displayName);

  static ShopFilter fromValue(String value) {
    return ShopFilter.values.firstWhere(
      (filter) => filter.value == value,
      orElse: () => ShopFilter.all,
    );
  }
}

/// Admin navigation sections
class AdminSections {
  AdminSections._();

  static const List<AdminSectionItem> items = [
    AdminSectionItem(
      title: 'Dashboard',
      icon: Icons.dashboard,
      route: '/admin',
    ),
    AdminSectionItem(
      title: 'Products',
      icon: Icons.inventory,
      route: '/admin/products',
    ),
    AdminSectionItem(
      title: 'Categories',
      icon: Icons.category,
      route: '/admin/categories',
    ),
    AdminSectionItem(
      title: 'Orders',
      icon: Icons.shopping_cart,
      route: '/admin/orders',
    ),
    AdminSectionItem(
      title: 'Custom Orders',
      icon: Icons.design_services,
      route: '/admin/custom-orders',
    ),
    AdminSectionItem(
      title: 'Customers',
      icon: Icons.people,
      route: '/admin/customers',
    ),
    AdminSectionItem(
      title: 'Analytics',
      icon: Icons.analytics,
      route: '/admin/analytics',
    ),
    AdminSectionItem(
      title: 'Inventory',
      icon: Icons.warehouse,
      route: '/admin/inventory',
    ),
    AdminSectionItem(
      title: 'Dynamic Content',
      icon: Icons.dynamic_feed,
      route: '/admin/dynamic-content',
    ),
    AdminSectionItem(
      title: 'Storefront',
      icon: Icons.storefront,
      route: '/admin/storefront',
    ),
    AdminSectionItem(
      title: 'Community',
      icon: Icons.forum,
      route: '/admin/community',
    ),
    AdminSectionItem(
      title: 'Settings',
      icon: Icons.settings,
      route: '/admin/store-settings',
    ),
  ];
}

/// Admin section item data class
class AdminSectionItem {
  final String title;
  final IconData icon;
  final String route;

  const AdminSectionItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}
