/// Filter configuration for the app
/// Contains default filter options that can be overridden by backend data

import '../data/models/filter_params.dart';

/// Metal type options for filtering
class MetalTypeOption {
  final String value;
  final String displayName;

  const MetalTypeOption(this.value, this.displayName);

  static const List<MetalTypeOption> defaults = [
    MetalTypeOption('18k-white-gold', '18K White Gold'),
    MetalTypeOption('18k-yellow-gold', '18K Yellow Gold'),
    MetalTypeOption('14k-rose-gold', '14K Rose Gold'),
    MetalTypeOption('14k-white-gold', '14K White Gold'),
    MetalTypeOption('22k-yellow-gold', '22K Yellow Gold'),
    MetalTypeOption('platinum', 'Platinum'),
    MetalTypeOption('silver', 'Silver'),
  ];
}

/// Stone type options for filtering
class StoneTypeOption {
  final String value;
  final String displayName;

  const StoneTypeOption(this.value, this.displayName);

  static const List<StoneTypeOption> defaults = [
    StoneTypeOption('diamond', 'Diamond'),
    StoneTypeOption('lab-diamond', 'Lab Diamond'),
    StoneTypeOption('emerald', 'Emerald'),
    StoneTypeOption('ruby', 'Ruby'),
    StoneTypeOption('pearl', 'Pearl'),
    StoneTypeOption('sapphire', 'Sapphire'),
  ];
}

/// Category options (can be loaded from backend)
class CategoryOption {
  final String value;
  final String displayName;

  const CategoryOption(this.value, this.displayName);

  static const List<CategoryOption> defaults = [
    CategoryOption('rings', 'Rings'),
    CategoryOption('necklaces', 'Necklaces'),
    CategoryOption('earrings', 'Earrings'),
    CategoryOption('bracelets', 'Bracelets'),
    CategoryOption('pendants', 'Pendants'),
    CategoryOption('bangles', 'Bangles'),
    CategoryOption('chains', 'Chains'),
    CategoryOption('watches', 'Watches'),
    CategoryOption('cufflinks', 'Cufflinks'),
    CategoryOption('brooches', 'Brooches'),
  ];
}

/// Filter configuration holder
class FilterConfig {
  final List<GenderType> genders;
  final List<CategoryOption> categories;
  final List<MetalTypeOption> metalTypes;
  final List<StoneTypeOption> stoneTypes;
  final double minPriceLimit;
  final double maxPriceLimit;
  final int priceDivisions;

  const FilterConfig({
    this.genders = const [
      GenderType.men,
      GenderType.women,
      GenderType.children,
      GenderType.unisex,
    ],
    this.categories = CategoryOption.defaults,
    this.metalTypes = MetalTypeOption.defaults,
    this.stoneTypes = StoneTypeOption.defaults,
    this.minPriceLimit = 0,
    this.maxPriceLimit = 100000,
    this.priceDivisions = 20,
  });

  /// Default configuration
  static const FilterConfig defaultConfig = FilterConfig();

  /// Create config with custom categories
  FilterConfig withCategories(List<CategoryOption> categories) {
    return FilterConfig(
      genders: genders,
      categories: categories,
      metalTypes: metalTypes,
      stoneTypes: stoneTypes,
      minPriceLimit: minPriceLimit,
      maxPriceLimit: maxPriceLimit,
      priceDivisions: priceDivisions,
    );
  }

  /// Create config with custom price range
  FilterConfig withPriceRange(double min, double max, {int? divisions}) {
    return FilterConfig(
      genders: genders,
      categories: categories,
      metalTypes: metalTypes,
      stoneTypes: stoneTypes,
      minPriceLimit: min,
      maxPriceLimit: max,
      priceDivisions: divisions ?? priceDivisions,
    );
  }
}

/// Sort options for product listing
enum SortOption {
  popularity('popularity', 'Popularity'),
  priceLowToHigh('price_asc', 'Price: Low to High'),
  priceHighToLow('price_desc', 'Price: High to Low'),
  newest('newest', 'Newest First'),
  rating('rating', 'Customer Rating'),
  discount('discount', 'Discount');

  final String value;
  final String displayName;

  const SortOption(this.value, this.displayName);

  static SortOption fromString(String? value) {
    if (value == null) return SortOption.popularity;
    return SortOption.values.firstWhere(
      (option) => option.value == value,
      orElse: () => SortOption.popularity,
    );
  }
}
