/// Unified filter parameters model for consistent filtering across the app
/// This makes it easy to pass filters between screens and to the API

import 'package:flutter/material.dart';

/// Gender type enum with unified mapping
enum GenderType {
  all('all', 'All', null),
  men('men', 'Men', Icons.man),
  women('women', 'Women', Icons.woman),
  children('children', 'Children', Icons.child_care),
  unisex('unisex', 'Unisex', Icons.people);

  final String value;
  final String displayName;
  final IconData? icon;

  const GenderType(this.value, this.displayName, this.icon);

  /// Get GenderType from any string value (handles all variations)
  static GenderType fromString(String? value) {
    if (value == null || value.isEmpty) return GenderType.all;

    final normalized = value.toLowerCase().trim();

    // Map all variations to standard types
    const mapping = {
      'all': GenderType.all,
      'men': GenderType.men,
      'male': GenderType.men,
      'man': GenderType.men,
      'women': GenderType.women,
      'female': GenderType.women,
      'woman': GenderType.women,
      'children': GenderType.children,
      'child': GenderType.children,
      'kids': GenderType.children,
      'kid': GenderType.children,
      'unisex': GenderType.unisex,
      'inclusive': GenderType.unisex,
    };

    return mapping[normalized] ?? GenderType.all;
  }

  bool get isAll => this == GenderType.all;
}

/// Unified filter parameters class
class FilterParams {
  final String? category;
  final String? subcategory;
  final String? styleTag;
  final GenderType gender;
  final double? minPrice;
  final double? maxPrice;
  final String? searchQuery;
  final List<String> metalTypes;
  final List<String> stoneTypes;
  final bool inStockOnly;
  final String sortBy;

  const FilterParams({
    this.category,
    this.subcategory,
    this.styleTag,
    this.gender = GenderType.all,
    this.minPrice,
    this.maxPrice,
    this.searchQuery,
    this.metalTypes = const [],
    this.stoneTypes = const [],
    this.inStockOnly = false,
    this.sortBy = 'popularity',
  });

  /// Create empty filter params
  factory FilterParams.empty() => const FilterParams();

  /// Create from category only
  factory FilterParams.category(String category, {GenderType? gender}) {
    return FilterParams(
      category: category,
      gender: gender ?? GenderType.all,
    );
  }

  /// Create from price range only
  factory FilterParams.priceRange(double? min, double? max, {GenderType? gender}) {
    return FilterParams(
      minPrice: min,
      maxPrice: max,
      gender: gender ?? GenderType.all,
    );
  }

  /// Create from style tag only
  factory FilterParams.styleTag(String tag, {String? category, GenderType? gender}) {
    return FilterParams(
      styleTag: tag,
      category: category,
      gender: gender ?? GenderType.all,
    );
  }

  /// Create from search query
  factory FilterParams.search(String query) {
    return FilterParams(searchQuery: query);
  }

  /// Check if any filter is active
  bool get hasActiveFilters {
    return category != null ||
        subcategory != null ||
        styleTag != null ||
        !gender.isAll ||
        minPrice != null ||
        maxPrice != null ||
        searchQuery != null ||
        metalTypes.isNotEmpty ||
        stoneTypes.isNotEmpty ||
        inStockOnly;
  }

  /// Copy with new values
  FilterParams copyWith({
    String? category,
    String? subcategory,
    String? styleTag,
    GenderType? gender,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    List<String>? metalTypes,
    List<String>? stoneTypes,
    bool? inStockOnly,
    String? sortBy,
  }) {
    return FilterParams(
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      styleTag: styleTag ?? this.styleTag,
      gender: gender ?? this.gender,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      searchQuery: searchQuery ?? this.searchQuery,
      metalTypes: metalTypes ?? this.metalTypes,
      stoneTypes: stoneTypes ?? this.stoneTypes,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Clear specific filters
  FilterParams clearCategory() => copyWith(category: null);
  FilterParams clearSubcategory() => copyWith(subcategory: null);
  FilterParams clearStyleTag() => copyWith(styleTag: null);
  FilterParams clearGender() => copyWith(gender: GenderType.all);
  FilterParams clearPriceRange() => FilterParams(
        category: category,
        subcategory: subcategory,
        styleTag: styleTag,
        gender: gender,
        searchQuery: searchQuery,
        metalTypes: metalTypes,
        stoneTypes: stoneTypes,
        inStockOnly: inStockOnly,
        sortBy: sortBy,
      );

  /// Clear all filters
  FilterParams clear() => const FilterParams();

  /// Convert to map for API calls
  Map<String, dynamic> toMap() {
    return {
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (styleTag != null) 'tag': styleTag,
      if (!gender.isAll) 'gender': gender.value,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (searchQuery != null) 'search': searchQuery,
      if (metalTypes.isNotEmpty) 'metalType': metalTypes,
      if (stoneTypes.isNotEmpty) 'stoneType': stoneTypes,
      if (inStockOnly) 'inStock': true,
      'sortBy': sortBy,
    };
  }

  /// Get display title for app bar
  String getDisplayTitle() {
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      return 'Results for "$searchQuery"';
    }
    if (styleTag != null) {
      return styleTag!;
    }
    if (subcategory != null && category != null) {
      return '$category - $subcategory';
    }
    if (category != null) {
      return category!;
    }
    if (minPrice != null || maxPrice != null) {
      if (minPrice != null && maxPrice != null) {
        return '₹${minPrice!.toInt()} - ₹${maxPrice!.toInt()}';
      } else if (minPrice != null) {
        return 'Above ₹${minPrice!.toInt()}';
      } else {
        return 'Under ₹${maxPrice!.toInt()}';
      }
    }
    return 'All Products';
  }

  @override
  String toString() {
    return 'FilterParams(category: $category, subcategory: $subcategory, '
        'styleTag: $styleTag, gender: ${gender.value}, '
        'minPrice: $minPrice, maxPrice: $maxPrice, '
        'searchQuery: $searchQuery)';
  }
}
