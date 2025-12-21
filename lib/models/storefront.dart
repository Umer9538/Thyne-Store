/// Storefront data models for home screen sections
/// These models represent data from the backend storefront APIs

/// Budget Range model for "Shop by Budget" section
class BudgetRange {
  final String id;
  final String label;
  final double minPrice;
  final double maxPrice;
  final int itemCount;
  final bool isPopular;
  final int priority;

  const BudgetRange({
    required this.id,
    required this.label,
    required this.minPrice,
    required this.maxPrice,
    this.itemCount = 0,
    this.isPopular = false,
    this.priority = 0,
  });

  factory BudgetRange.fromJson(Map<String, dynamic> json) {
    return BudgetRange(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0,
      maxPrice: (json['maxPrice'] as num?)?.toDouble() ?? 0,
      itemCount: json['itemCount'] as int? ?? 0,
      isPopular: json['isPopular'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'itemCount': itemCount,
      'isPopular': isPopular,
      'priority': priority,
    };
  }

  /// Default budget ranges (fallback)
  static List<BudgetRange> get defaults => [
        const BudgetRange(id: '1', label: 'Under 10K', minPrice: 0, maxPrice: 10000),
        const BudgetRange(id: '2', label: '10K - 20K', minPrice: 10000, maxPrice: 20000),
        const BudgetRange(id: '3', label: '20K - 30K', minPrice: 20000, maxPrice: 30000),
        const BudgetRange(id: '4', label: '30K - 50K', minPrice: 30000, maxPrice: 50000),
        const BudgetRange(id: '5', label: '50K - 75K', minPrice: 50000, maxPrice: 75000),
        const BudgetRange(id: '6', label: '75K & Above', minPrice: 75000, maxPrice: 10000000),
      ];
}

/// Occasion model for "Shop by Occasion" section
class Occasion {
  final String id;
  final String name;
  final String icon;
  final String description;
  final int itemCount;
  final List<String> tags;
  final int priority;

  const Occasion({
    required this.id,
    required this.name,
    this.icon = '',
    this.description = '',
    this.itemCount = 0,
    this.tags = const [],
    this.priority = 0,
  });

  factory Occasion.fromJson(Map<String, dynamic> json) {
    return Occasion(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      itemCount: json['itemCount'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      priority: json['priority'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'itemCount': itemCount,
      'tags': tags,
      'priority': priority,
    };
  }

  /// Get the first tag for filtering, or use name as fallback
  String get filterTag => tags.isNotEmpty ? tags.first : name.toLowerCase();
}

/// Category model for product categories
class ProductCategory {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String image;
  final List<String> subcategories;
  final List<String> gender;
  final int sortOrder;
  final bool isActive;

  const ProductCategory({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    this.image = '',
    this.subcategories = const [],
    this.gender = const ['all'],
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      gender: (json['gender'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['all'],
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image': image,
      'subcategories': subcategories,
      'gender': gender,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  /// Check if category is available for given gender
  bool isAvailableForGender(String genderFilter) {
    if (gender.isEmpty || gender.contains('all')) return true;
    return gender.any((g) => g.toLowerCase() == genderFilter.toLowerCase());
  }
}

/// Collection model for curated collections
class Collection {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String image;
  final List<String> productIds;
  final bool isActive;
  final int priority;

  const Collection({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.image = '',
    this.productIds = const [],
    this.isActive = true,
    this.priority = 0,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      productIds: (json['productIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'image': image,
      'productIds': productIds,
      'isActive': isActive,
      'priority': priority,
    };
  }
}
