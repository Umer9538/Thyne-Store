import 'package:flutter/material.dart';

/// Enum representing all available sort options for products.
enum SortOption {
  popularity('popularity', 'Popularity'),
  priceLow('price_low', 'Price: Low to High'),
  priceHigh('price_high', 'Price: High to Low'),
  rating('rating', 'Customer Rating'),
  newest('newest', 'Newest First'),
  nameAsc('name_asc', 'Name: A to Z'),
  nameDesc('name_desc', 'Name: Z to A'),
  discount('discount', 'Discount: High to Low');

  final String value;
  final String displayName;

  const SortOption(this.value, this.displayName);

  /// Get SortOption from value string
  static SortOption fromValue(String value) {
    return SortOption.values.firstWhere(
      (option) => option.value == value,
      orElse: () => SortOption.popularity,
    );
  }

  /// Get all sort options as a list of maps (for dropdowns, etc.)
  static List<Map<String, String>> toMapList() {
    return SortOption.values
        .map((option) => {
              'value': option.value,
              'label': option.displayName,
            })
        .toList();
  }
}

/// Extension to build sort option widgets
extension SortOptionWidget on SortOption {
  /// Build a ListTile for this sort option
  Widget buildListTile({
    required bool isSelected,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    return ListTile(
      title: Text(displayName),
      trailing: isSelected
          ? Icon(Icons.check, color: selectedColor ?? Colors.amber)
          : null,
      onTap: onTap,
    );
  }
}
