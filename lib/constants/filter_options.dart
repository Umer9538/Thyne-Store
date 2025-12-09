import 'package:flutter/material.dart';

/// Enum representing gender filter options.
enum GenderFilter {
  all(null, 'All', null),
  male('Male', 'Men', Icons.man),
  female('Female', 'Women', Icons.woman),
  child('Child', 'Child', Icons.child_care),
  unisex('Unisex', 'Unisex', Icons.people);

  final String? value;
  final String displayName;
  final IconData? icon;

  const GenderFilter(this.value, this.displayName, this.icon);

  /// Check if this is the "all" option
  bool get isAll => this == GenderFilter.all;

  /// Get GenderFilter from value string
  static GenderFilter fromValue(String? value) {
    if (value == null) return GenderFilter.all;
    return GenderFilter.values.firstWhere(
      (filter) => filter.value?.toLowerCase() == value.toLowerCase(),
      orElse: () => GenderFilter.all,
    );
  }

  /// Get all filter options excluding 'all'
  static List<GenderFilter> get filtersWithoutAll {
    return GenderFilter.values.where((f) => !f.isAll).toList();
  }
}

/// Price range filter presets
class PriceRangeFilter {
  final String label;
  final double? minPrice;
  final double? maxPrice;

  const PriceRangeFilter({
    required this.label,
    this.minPrice,
    this.maxPrice,
  });

  /// Common price range filters
  static const List<PriceRangeFilter> presets = [
    PriceRangeFilter(label: 'All Prices'),
    PriceRangeFilter(label: 'Under ₹5,000', maxPrice: 5000),
    PriceRangeFilter(label: '₹5,000 - ₹10,000', minPrice: 5000, maxPrice: 10000),
    PriceRangeFilter(label: '₹10,000 - ₹25,000', minPrice: 10000, maxPrice: 25000),
    PriceRangeFilter(label: '₹25,000 - ₹50,000', minPrice: 25000, maxPrice: 50000),
    PriceRangeFilter(label: 'Above ₹50,000', minPrice: 50000),
  ];

  bool get isAll => minPrice == null && maxPrice == null;
}

/// Default product categories
class ProductCategories {
  ProductCategories._();

  static const String rings = 'Rings';
  static const String earrings = 'Earrings';
  static const String bracelets = 'Bracelets & Bangles';
  static const String solitaires = 'Solitaires';
  static const String gold22kt = '22KT';
  static const String silver = 'Silver by Shaya';
  static const String mangalsutra = 'Mangalsutra';
  static const String necklaces = 'Necklaces';
  static const String pendants = 'Pendants';
  static const String chains = 'Chains';

  /// All categories as a list
  static const List<String> all = [
    rings,
    earrings,
    bracelets,
    solitaires,
    gold22kt,
    silver,
    mangalsutra,
    necklaces,
    pendants,
    chains,
  ];

  /// Main categories (shown in home page)
  static const List<String> main = [
    rings,
    earrings,
    bracelets,
    solitaires,
    gold22kt,
    silver,
    mangalsutra,
    necklaces,
  ];

  /// Category icons mapping
  static const Map<String, IconData> icons = {
    rings: Icons.circle_outlined,
    earrings: Icons.earbuds,
    bracelets: Icons.watch,
    solitaires: Icons.diamond,
    gold22kt: Icons.stars,
    silver: Icons.auto_awesome,
    mangalsutra: Icons.favorite,
    necklaces: Icons.stream,
    pendants: Icons.pending,
    chains: Icons.link,
  };
}

/// Material type filters
enum MaterialType {
  gold('Gold', 'gold'),
  silver('Silver', 'silver'),
  platinum('Platinum', 'platinum'),
  diamond('Diamond', 'diamond'),
  gemstone('Gemstone', 'gemstone');

  final String displayName;
  final String value;

  const MaterialType(this.displayName, this.value);

  static MaterialType? fromValue(String? value) {
    if (value == null) return null;
    return MaterialType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => MaterialType.gold,
    );
  }
}
