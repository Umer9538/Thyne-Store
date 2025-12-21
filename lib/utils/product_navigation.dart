/// Product navigation helper for consistent navigation across the app
/// Use this instead of directly pushing ProductListScreen

import 'package:flutter/material.dart';
import '../models/filter_params.dart';
import '../models/storefront.dart';
import '../screens/product/product_list_screen.dart';

/// Helper class for navigating to product screens with filters
class ProductNavigation {
  ProductNavigation._();

  /// Navigate to products with filter params
  static void toProducts(BuildContext context, FilterParams params) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(
          category: params.category,
          subcategory: params.subcategory,
          styleTag: params.styleTag,
          gender: params.gender.isAll ? null : params.gender.value,
          minPrice: params.minPrice?.toInt(),
          maxPrice: params.maxPrice?.toInt(),
          searchQuery: params.searchQuery,
        ),
      ),
    );
  }

  /// Navigate to products by category
  static void toCategory(BuildContext context, String category, {GenderType? gender}) {
    toProducts(context, FilterParams.category(category, gender: gender));
  }

  /// Navigate to products by category model
  static void toCategoryModel(BuildContext context, ProductCategory category, {GenderType? gender}) {
    toProducts(context, FilterParams.category(category.name, gender: gender));
  }

  /// Navigate to products by subcategory
  static void toSubcategory(BuildContext context, String category, String subcategory, {GenderType? gender}) {
    toProducts(
      context,
      FilterParams(
        category: category,
        subcategory: subcategory,
        gender: gender ?? GenderType.all,
      ),
    );
  }

  /// Navigate to products by price range
  static void toPriceRange(BuildContext context, double? minPrice, double? maxPrice, {GenderType? gender}) {
    toProducts(context, FilterParams.priceRange(minPrice, maxPrice, gender: gender));
  }

  /// Navigate to products by budget range model
  static void toBudgetRange(BuildContext context, BudgetRange budget, {GenderType? gender}) {
    toProducts(
      context,
      FilterParams.priceRange(
        budget.minPrice,
        budget.maxPrice > 0 ? budget.maxPrice : null,
        gender: gender,
      ),
    );
  }

  /// Navigate to products by style tag
  static void toStyleTag(BuildContext context, String tag, {String? category, GenderType? gender}) {
    toProducts(context, FilterParams.styleTag(tag, category: category, gender: gender));
  }

  /// Navigate to products by occasion model
  static void toOccasion(BuildContext context, Occasion occasion, {GenderType? gender}) {
    toProducts(
      context,
      FilterParams.styleTag(occasion.filterTag, gender: gender),
    );
  }

  /// Navigate to search results
  static void toSearch(BuildContext context, String query) {
    toProducts(context, FilterParams.search(query));
  }

  /// Navigate to all products
  static void toAllProducts(BuildContext context, {GenderType? gender}) {
    toProducts(context, FilterParams(gender: gender ?? GenderType.all));
  }

  /// Navigate with custom filter combination
  static void toFiltered(
    BuildContext context, {
    String? category,
    String? subcategory,
    String? styleTag,
    GenderType? gender,
    double? minPrice,
    double? maxPrice,
  }) {
    toProducts(
      context,
      FilterParams(
        category: category,
        subcategory: subcategory,
        styleTag: styleTag,
        gender: gender ?? GenderType.all,
        minPrice: minPrice,
        maxPrice: maxPrice,
      ),
    );
  }
}

/// Extension on BuildContext for easier navigation
extension ProductNavigationExtension on BuildContext {
  /// Navigate to products with filters
  void goToProducts(FilterParams params) => ProductNavigation.toProducts(this, params);

  /// Navigate to category
  void goToCategory(String category, {GenderType? gender}) =>
      ProductNavigation.toCategory(this, category, gender: gender);

  /// Navigate to price range
  void goToPriceRange(double? min, double? max, {GenderType? gender}) =>
      ProductNavigation.toPriceRange(this, min, max, gender: gender);

  /// Navigate to style tag
  void goToStyleTag(String tag, {String? category, GenderType? gender}) =>
      ProductNavigation.toStyleTag(this, tag, category: category, gender: gender);

  /// Navigate to search
  void goToSearch(String query) => ProductNavigation.toSearch(this, query);

  /// Navigate to all products
  void goToAllProducts({GenderType? gender}) =>
      ProductNavigation.toAllProducts(this, gender: gender);
}
