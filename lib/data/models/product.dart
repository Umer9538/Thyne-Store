import 'store_settings.dart';

/// Stock type enum for product inventory management
enum StockType {
  stocked,      // Regular inventory with limited quantity
  madeToOrder,  // Custom/on-demand, always available
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final List<String> images;
  final List<String> videos;
  final String category;
  final String subcategory;
  final String metalType;
  final String? stoneType;
  final double? weight;
  final String? size;
  final StockType stockType;  // "stocked" or "made_to_order"
  final int stockQuantity;
  final int stock;
  final double rating;
  final int reviewCount;
  final int ratingCount;
  final List<String> tags;
  final List<String> gender;
  final bool isAvailable;
  final bool isFeatured;
  final bool isNewArrival;
  // Customization options (legacy - kept for compatibility)
  final List<String> availableColors;
  final List<String> availablePolishTypes;
  final List<String> availableStoneColors;
  final List<String> availableGemstones;
  // Enhanced customization options (Diamondere style)
  final List<String> availableMetals; // e.g., ["14K Gold", "18K Gold", "925 Silver"]
  final List<String> availablePlatingColors; // e.g., ["White Gold", "Rose Gold"]
  final List<StoneConfig> stones; // Multiple stones with shape + colors
  final List<String> availableSizes; // Ring sizes
  final bool engravingEnabled;
  final int maxEngravingChars;
  final double? minThickness;
  final double? maxThickness;
  // Price modifiers for customization options
  final Map<String, double> metalPriceModifiers;
  final Map<String, double> platingPriceModifiers;

  final double engravingPrice; // Price for adding engraving
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.images,
    this.videos = const [],
    required this.category,
    required this.subcategory,
    required this.metalType,
    this.stoneType,
    this.weight,
    this.size,
    this.stockType = StockType.stocked,
    required this.stockQuantity,
    int? stock,
    this.rating = 0.0,
    this.reviewCount = 0,
    int? ratingCount,
    this.tags = const [],
    this.gender = const [],
    this.isAvailable = true,
    this.isFeatured = false,
    this.availableColors = const [],
    this.availablePolishTypes = const [],
    this.availableStoneColors = const [],
    this.availableGemstones = const [],
    this.availableMetals = const [],
    this.availablePlatingColors = const [],
    this.stones = const [],
    this.availableSizes = const [],
    this.engravingEnabled = false,
    this.maxEngravingChars = 15,
    this.minThickness,
    this.maxThickness,
    Map<String, double>? metalPriceModifiers,
    Map<String, double>? platingPriceModifiers,
    this.engravingPrice = 500.0,
    DateTime? createdAt,
    bool? isNewArrival,
  }) : stock = stock ?? stockQuantity,
       ratingCount = ratingCount ?? reviewCount,
       metalPriceModifiers = metalPriceModifiers ?? const {},
       platingPriceModifiers = platingPriceModifiers ?? const {},
       createdAt = createdAt ?? DateTime.now(),
       isNewArrival = isNewArrival ?? false;

  double get discount {
    if (originalPrice != null && originalPrice! > price) {
      return ((originalPrice! - price) / originalPrice! * 100);
    }
    return 0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse stock type from JSON
    StockType stockType = StockType.stocked;
    final stockTypeStr = json['stockType']?.toString();
    if (stockTypeStr == 'made_to_order') {
      stockType = StockType.madeToOrder;
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      category: json['category']?.toString() ?? '',
      subcategory: json['subcategory']?.toString() ?? '',
      metalType: json['metalType']?.toString() ?? '',
      stoneType: json['stoneType']?.toString(),
      weight: json['weight']?.toDouble(),
      size: json['size']?.toString(),
      stockType: stockType,
      stockQuantity: json['stockQuantity'] ?? 0,
      rating: json['rating']?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      gender: List<String>.from(json['gender'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      availableColors: List<String>.from(json['availableColors'] ?? []),
      availablePolishTypes: List<String>.from(json['availablePolishTypes'] ?? []),
      availableStoneColors: List<String>.from(json['availableStoneColors'] ?? []),
      availableGemstones: List<String>.from(json['availableGemstones'] ?? []),
      availableMetals: List<String>.from(json['availableMetals'] ?? []),
      availablePlatingColors: List<String>.from(json['availablePlatingColors'] ?? []),
      stones: json['stones'] != null
          ? (json['stones'] as List).map((s) => StoneConfig.fromJson(s)).toList()
          : [],
      availableSizes: List<String>.from(json['availableSizes'] ?? []),
      engravingEnabled: json['engravingEnabled'] ?? false,
      maxEngravingChars: json['maxEngravingChars'] ?? 15,
      minThickness: json['minThickness']?.toDouble(),
      maxThickness: json['maxThickness']?.toDouble(),
      metalPriceModifiers: json['metalPriceModifiers'] != null
          ? Map<String, double>.from(
              (json['metalPriceModifiers'] as Map).map(
                (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
              ),
            )
          : null,
      platingPriceModifiers: json['platingPriceModifiers'] != null
          ? Map<String, double>.from(
              (json['platingPriceModifiers'] as Map).map(
                (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
              ),
            )
          : null,
      engravingPrice: (json['engravingPrice'] ?? 500.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'images': images,
      'videos': videos,
      'category': category,
      'subcategory': subcategory,
      'metalType': metalType,
      'stoneType': stoneType,
      'weight': weight,
      'size': size,
      'stockType': stockType == StockType.madeToOrder ? 'made_to_order' : 'stocked',
      'stockQuantity': stockQuantity,
      'rating': rating,
      'reviewCount': reviewCount,
      'tags': tags,
      'gender': gender,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'availableColors': availableColors,
      'availablePolishTypes': availablePolishTypes,
      'availableStoneColors': availableStoneColors,
      'availableGemstones': availableGemstones,
      'availableMetals': availableMetals,
      'availablePlatingColors': availablePlatingColors,
      'stones': stones.map((s) => s.toJson()).toList(),
      'availableSizes': availableSizes,
      'engravingEnabled': engravingEnabled,
      'maxEngravingChars': maxEngravingChars,
      'minThickness': minThickness,
      'maxThickness': maxThickness,
      'metalPriceModifiers': metalPriceModifiers,
      'platingPriceModifiers': platingPriceModifiers,
      'engravingPrice': engravingPrice,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Calculate price with customizations
  double calculateCustomizedPrice(ProductCustomization? customization) {
    if (customization == null) return price;

    double totalPrice = price;

    // Add metal price modifier
    if (customization.metalType != null && metalPriceModifiers.containsKey(customization.metalType)) {
      totalPrice += metalPriceModifiers[customization.metalType]!;
    }

    // Add plating price modifier
    if (customization.platingColor != null && platingPriceModifiers.containsKey(customization.platingColor)) {
      totalPrice += platingPriceModifiers[customization.platingColor]!;
    }

    // Add stone color price modifiers and quality multipliers
    if (customization.stoneColorSelections != null) {
      for (final entry in customization.stoneColorSelections!.entries) {
        final stone = stones.firstWhere(
          (s) => s.name == entry.key,
          orElse: () => const StoneConfig(name: '', shape: '', availableColors: []),
        );
        if (stone.name.isNotEmpty) {
          double stoneCost = stone.getPriceModifier(entry.value);

          // Apply quality multiplier if selected
          if (customization.stoneQualitySelections != null &&
              customization.stoneQualitySelections!.containsKey(stone.name)) {
            final qualityName = customization.stoneQualitySelections![stone.name];
            final quality = stone.availableQualities.firstWhere(
              (q) => q.name == qualityName,
              orElse: () => stone.defaultQuality,
            );
            // Assuming stoneCost represents the base cost of that stone option.
            // If stoneCost is 0 (base price included), we might need a base stone price field.
            // For now, let's assume the modifier *is* the cost of the upgrade.
            // A better model might be: (BaseProductPrice) + (StoneBasePrice * QualityMultiplier)
            // But preserving existing logic:
            if (stoneCost > 0) {
              stoneCost *= quality.priceMultiplier;
            } else {
               // If stone has no specific color modifier, we might apply a general markup
               // based on the product price or a fixed amount per quality.
               // For this implementation, we'll assume the quality adds a % of the base product price
               // allocated to stones, or similar.
               // SIMPLE APPROACH: Add a fixed cost if multiplier > 1
               if (quality.priceMultiplier > 1.0) {
                 totalPrice += (price * 0.1) * (quality.priceMultiplier - 1.0);
               }
            }
          }

          // Apply shape price modifier
          if (customization.stoneShapeSelections != null &&
              customization.stoneShapeSelections!.containsKey(stone.name)) {
            final selectedShape = customization.stoneShapeSelections![stone.name];
            final shapeModifier = stone.getShapePriceModifier(selectedShape!);
            stoneCost += shapeModifier;
          }

          // Apply carat weight multiplier
          if (customization.stoneCaratWeights != null &&
              customization.stoneCaratWeights!.containsKey(stone.name)) {
            final caratWeight = customization.stoneCaratWeights![stone.name]!;
            final caratMultiplier = stone.getCaratMultiplier(caratWeight);
            // Price increases with carat weight
            if (stone.pricePerCarat != null) {
              stoneCost += stone.pricePerCarat! * caratWeight * caratMultiplier;
            } else {
              // Apply multiplier to existing stone cost
              stoneCost *= caratMultiplier;
            }
          }

          // Apply diamond 4Cs grading multiplier
          if (customization.stoneDiamondGrading != null &&
              customization.stoneDiamondGrading!.containsKey(stone.name)) {
            final grading = customization.stoneDiamondGrading![stone.name]!;
            final gradingMultiplier = grading.calculateMultiplier(
              colorMultipliers: stone.colorGradePriceModifiers ?? GradingPriceTable.colorMultipliers,
              clarityMultipliers: stone.clarityPriceModifiers ?? GradingPriceTable.clarityMultipliers,
              cutMultipliers: stone.cutGradePriceModifiers ?? GradingPriceTable.cutMultipliers,
            );
            stoneCost *= gradingMultiplier;
          }

          totalPrice += stoneCost;
        }
      }
    }

    // Add engraving price
    if (customization.engraving != null && customization.engraving!.isNotEmpty && engravingEnabled) {
      totalPrice += engravingPrice;
    }

    return totalPrice;
  }

  /// Check if product has any customization options
  bool get hasCustomization =>
      availableMetals.isNotEmpty ||
      availablePlatingColors.isNotEmpty ||
      stones.isNotEmpty ||
      availableSizes.isNotEmpty ||
      engravingEnabled;
}

class Review {
  final String id;
  final String userId;
  final String userName;
  final String productId;
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.productId,
    required this.rating,
    required this.comment,
    this.images = const [],
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      productId: json['productId'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}