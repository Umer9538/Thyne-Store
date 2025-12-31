/// Store settings model for GST, shipping, and other configurations
class StoreSettings {
  final String id;
  // Tax Settings
  final double gstRate;
  final String gstNumber;
  final bool enableGst;
  // Shipping Settings
  final double freeShippingThreshold;
  final double shippingCost;
  final bool enableFreeShipping;
  // COD Settings
  final bool enableCod;
  final double codCharge;
  final double codMaxAmount;
  // Store Info
  final String storeName;
  final String storeEmail;
  final String storePhone;
  final String storeAddress;
  final String currency;
  final String currencySymbol;
  // Order ID Settings
  final String orderIdPrefix;
  final int orderIdCounter;
  // Product Customization Options (Admin Editable)
  final List<MetalOption> metalOptions;
  final List<PlatingColor> platingColors;
  final List<SizeOption> sizeOptions;
  final List<StoneType> stoneTypes;
  final int maxEngravingChars;
  // Metadata
  final String? updatedAt;

  StoreSettings({
    this.id = '',
    this.gstRate = 18.0,
    this.gstNumber = '',
    this.enableGst = true,
    this.freeShippingThreshold = 1000.0,
    this.shippingCost = 99.0,
    this.enableFreeShipping = true,
    this.enableCod = true,
    this.codCharge = 0.0,
    this.codMaxAmount = 50000.0,
    this.storeName = 'Thyne Jewels',
    this.storeEmail = '',
    this.storePhone = '',
    this.storeAddress = '',
    this.currency = 'INR',
    this.currencySymbol = '\u20B9',
    this.orderIdPrefix = 'TJ',
    this.orderIdCounter = 1000,
    List<MetalOption>? metalOptions,
    List<PlatingColor>? platingColors,
    List<SizeOption>? sizeOptions,
    List<StoneType>? stoneTypes,
    this.maxEngravingChars = 15,
    this.updatedAt,
  }) : metalOptions = metalOptions ?? MetalOption.defaults,
       platingColors = platingColors ?? PlatingColor.defaults,
       sizeOptions = sizeOptions ?? SizeOption.defaults,
       stoneTypes = stoneTypes ?? StoneType.defaults;

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      id: json['id']?.toString() ?? '',
      gstRate: (json['gstRate'] ?? 18.0).toDouble(),
      gstNumber: json['gstNumber']?.toString() ?? '',
      enableGst: json['enableGst'] ?? true,
      freeShippingThreshold: (json['freeShippingThreshold'] ?? 1000.0).toDouble(),
      shippingCost: (json['shippingCost'] ?? 99.0).toDouble(),
      enableFreeShipping: json['enableFreeShipping'] ?? true,
      enableCod: json['enableCod'] ?? true,
      codCharge: (json['codCharge'] ?? 0.0).toDouble(),
      codMaxAmount: (json['codMaxAmount'] ?? 50000.0).toDouble(),
      storeName: json['storeName']?.toString() ?? 'Thyne Jewels',
      storeEmail: json['storeEmail']?.toString() ?? '',
      storePhone: json['storePhone']?.toString() ?? '',
      storeAddress: json['storeAddress']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'INR',
      currencySymbol: json['currencySymbol']?.toString() ?? '\u20B9',
      orderIdPrefix: json['orderIdPrefix']?.toString() ?? 'TJ',
      orderIdCounter: (json['orderIdCounter'] ?? 1000) is int
          ? json['orderIdCounter']
          : int.tryParse(json['orderIdCounter']?.toString() ?? '1000') ?? 1000,
      metalOptions: json['metalOptions'] != null
          ? (json['metalOptions'] as List).map((e) => MetalOption.fromJson(e)).toList()
          : null,
      platingColors: json['platingColors'] != null
          ? (json['platingColors'] as List).map((e) => PlatingColor.fromJson(e)).toList()
          : null,
      sizeOptions: json['sizeOptions'] != null
          ? (json['sizeOptions'] as List).map((e) => SizeOption.fromJson(e)).toList()
          : null,
      stoneTypes: json['stoneTypes'] != null
          ? (json['stoneTypes'] as List).map((e) => StoneType.fromJson(e)).toList()
          : null,
      maxEngravingChars: json['maxEngravingChars'] ?? 15,
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gstRate': gstRate,
      'gstNumber': gstNumber,
      'enableGst': enableGst,
      'freeShippingThreshold': freeShippingThreshold,
      'shippingCost': shippingCost,
      'enableFreeShipping': enableFreeShipping,
      'enableCod': enableCod,
      'codCharge': codCharge,
      'codMaxAmount': codMaxAmount,
      'storeName': storeName,
      'storeEmail': storeEmail,
      'storePhone': storePhone,
      'storeAddress': storeAddress,
      'currency': currency,
      'currencySymbol': currencySymbol,
      'orderIdPrefix': orderIdPrefix,
      'orderIdCounter': orderIdCounter,
      'metalOptions': metalOptions.map((e) => e.toJson()).toList(),
      'platingColors': platingColors.map((e) => e.toJson()).toList(),
      'sizeOptions': sizeOptions.map((e) => e.toJson()).toList(),
      'stoneTypes': stoneTypes.map((e) => e.toJson()).toList(),
      'maxEngravingChars': maxEngravingChars,
      'updatedAt': updatedAt,
    };
  }

  StoreSettings copyWith({
    String? id,
    double? gstRate,
    String? gstNumber,
    bool? enableGst,
    double? freeShippingThreshold,
    double? shippingCost,
    bool? enableFreeShipping,
    bool? enableCod,
    double? codCharge,
    double? codMaxAmount,
    String? storeName,
    String? storeEmail,
    String? storePhone,
    String? storeAddress,
    String? currency,
    String? currencySymbol,
    String? orderIdPrefix,
    int? orderIdCounter,
    List<MetalOption>? metalOptions,
    List<PlatingColor>? platingColors,
    List<SizeOption>? sizeOptions,
    List<StoneType>? stoneTypes,
    int? maxEngravingChars,
    String? updatedAt,
  }) {
    return StoreSettings(
      id: id ?? this.id,
      gstRate: gstRate ?? this.gstRate,
      gstNumber: gstNumber ?? this.gstNumber,
      enableGst: enableGst ?? this.enableGst,
      freeShippingThreshold: freeShippingThreshold ?? this.freeShippingThreshold,
      shippingCost: shippingCost ?? this.shippingCost,
      enableFreeShipping: enableFreeShipping ?? this.enableFreeShipping,
      enableCod: enableCod ?? this.enableCod,
      codCharge: codCharge ?? this.codCharge,
      codMaxAmount: codMaxAmount ?? this.codMaxAmount,
      storeName: storeName ?? this.storeName,
      storeEmail: storeEmail ?? this.storeEmail,
      storePhone: storePhone ?? this.storePhone,
      storeAddress: storeAddress ?? this.storeAddress,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      orderIdPrefix: orderIdPrefix ?? this.orderIdPrefix,
      orderIdCounter: orderIdCounter ?? this.orderIdCounter,
      metalOptions: metalOptions ?? this.metalOptions,
      platingColors: platingColors ?? this.platingColors,
      sizeOptions: sizeOptions ?? this.sizeOptions,
      stoneTypes: stoneTypes ?? this.stoneTypes,
      maxEngravingChars: maxEngravingChars ?? this.maxEngravingChars,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate tax for a given subtotal
  double calculateTax(double subtotal) {
    if (!enableGst) return 0.0;
    return subtotal * (gstRate / 100);
  }

  /// Calculate shipping for a given subtotal
  double calculateShipping(double subtotal) {
    if (enableFreeShipping && subtotal >= freeShippingThreshold) {
      return 0.0;
    }
    return shippingCost;
  }

  /// Check if COD is available for order total
  bool isCodAvailable(double orderTotal) {
    if (!enableCod) return false;
    return orderTotal <= codMaxAmount;
  }

  /// Default settings
  static StoreSettings get defaults => StoreSettings();
}

/// Metal option with type and karat/purity variants
class MetalOption {
  final String id;
  final String type; // Gold, Silver, Platinum, Alloy, Brass
  final List<MetalSubtype> subtypes; // Purity/karat variants
  final String? internalCode; // Optional internal code
  final bool isActive;
  final int sortOrder;

  const MetalOption({
    this.id = '',
    required this.type,
    required this.subtypes,
    this.internalCode,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory MetalOption.fromJson(Map<String, dynamic> json) {
    // Handle legacy format (variants as strings)
    if (json['variants'] != null && json['subtypes'] == null) {
      final variants = List<String>.from(json['variants']);
      return MetalOption(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        subtypes: variants.map((v) => MetalSubtype(name: v)).toList(),
        internalCode: json['internalCode']?.toString(),
        isActive: json['isActive'] ?? true,
        sortOrder: json['sortOrder'] ?? 0,
      );
    }
    return MetalOption(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      subtypes: json['subtypes'] != null
          ? (json['subtypes'] as List).map((e) => MetalSubtype.fromJson(e)).toList()
          : [],
      internalCode: json['internalCode']?.toString(),
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'type': type,
      'subtypes': subtypes.map((e) => e.toJson()).toList(),
      // Also include variants for backward compatibility
      'variants': subtypes.map((e) => e.name).toList(),
      if (internalCode != null) 'internalCode': internalCode,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  /// Default metal options
  static List<MetalOption> get defaults => [
    MetalOption(
      type: 'Gold',
      subtypes: [
        MetalSubtype(name: '9K', code: 'G9K'),
        MetalSubtype(name: '14K', code: 'G14K'),
        MetalSubtype(name: '18K', code: 'G18K'),
        MetalSubtype(name: '22K', code: 'G22K'),
      ],
    ),
    MetalOption(
      type: 'Silver',
      subtypes: [
        MetalSubtype(name: '925 Sterling Silver', code: 'S925'),
      ],
    ),
    MetalOption(
      type: 'Platinum',
      subtypes: [
        MetalSubtype(name: '950 Platinum', code: 'PT950'),
      ],
    ),
  ];

  /// Get display string (e.g., "14K Gold")
  String getDisplayName(String variant) => '$variant $type';

  /// Get all variant names
  List<String> get variantNames => subtypes.map((s) => s.name).toList();
}

/// Metal subtype (purity/karat)
class MetalSubtype {
  final String name; // e.g., "9K", "14K", "925 Sterling Silver"
  final String? code; // Optional internal code
  final double? priceMultiplier; // Price adjustment factor

  const MetalSubtype({
    required this.name,
    this.code,
    this.priceMultiplier,
  });

  factory MetalSubtype.fromJson(Map<String, dynamic> json) {
    return MetalSubtype(
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      priceMultiplier: json['priceMultiplier']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (code != null) 'code': code,
      if (priceMultiplier != null) 'priceMultiplier': priceMultiplier,
    };
  }
}

/// Plating color option
class PlatingColor {
  final String id;
  final String name; // Yellow Gold, Rose Gold, White Gold, Rhodium, etc.
  final String? hexColor; // For UI display
  final String? code; // Internal code
  final bool isActive;
  final int sortOrder;

  const PlatingColor({
    this.id = '',
    required this.name,
    this.hexColor,
    this.code,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory PlatingColor.fromJson(dynamic json) {
    // Handle string format (legacy)
    if (json is String) {
      return PlatingColor(name: json);
    }
    final map = json as Map<String, dynamic>;
    return PlatingColor(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      hexColor: map['hexColor']?.toString(),
      code: map['code']?.toString(),
      isActive: map['isActive'] ?? true,
      sortOrder: map['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      if (hexColor != null) 'hexColor': hexColor,
      if (code != null) 'code': code,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  static List<PlatingColor> get defaults => const [
    PlatingColor(name: 'Yellow Gold', hexColor: '#FFD700'),
    PlatingColor(name: 'Rose Gold', hexColor: '#B76E79'),
    PlatingColor(name: 'White Gold', hexColor: '#E8E8E8'),
    PlatingColor(name: 'Rhodium', hexColor: '#C0C0C0'),
    PlatingColor(name: 'Antique', hexColor: '#8B7355'),
    PlatingColor(name: 'Black Gold', hexColor: '#1C1C1C'),
  ];
}

/// Size option for rings, chains, bracelets
class SizeOption {
  final String id;
  final String category; // Ring, Chain, Bracelet, Earring, Bangle
  final List<SizeValue> sizes;
  final bool isActive;

  const SizeOption({
    this.id = '',
    required this.category,
    required this.sizes,
    this.isActive = true,
  });

  factory SizeOption.fromJson(Map<String, dynamic> json) {
    return SizeOption(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      sizes: json['sizes'] != null
          ? (json['sizes'] as List).map((e) => SizeValue.fromJson(e)).toList()
          : [],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'category': category,
      'sizes': sizes.map((e) => e.toJson()).toList(),
      'isActive': isActive,
    };
  }

  static List<SizeOption> get defaults => [
    SizeOption(
      category: 'Ring',
      sizes: [
        SizeValue(name: 'US 4', value: '4', mmEquivalent: 14.9),
        SizeValue(name: 'US 5', value: '5', mmEquivalent: 15.7),
        SizeValue(name: 'US 6', value: '6', mmEquivalent: 16.5),
        SizeValue(name: 'US 7', value: '7', mmEquivalent: 17.3),
        SizeValue(name: 'US 8', value: '8', mmEquivalent: 18.1),
        SizeValue(name: 'US 9', value: '9', mmEquivalent: 18.9),
        SizeValue(name: 'US 10', value: '10', mmEquivalent: 19.8),
        SizeValue(name: 'US 11', value: '11', mmEquivalent: 20.6),
        SizeValue(name: 'US 12', value: '12', mmEquivalent: 21.4),
      ],
    ),
    SizeOption(
      category: 'Chain',
      sizes: [
        SizeValue(name: '16 inch', value: '16', mmEquivalent: 406),
        SizeValue(name: '18 inch', value: '18', mmEquivalent: 457),
        SizeValue(name: '20 inch', value: '20', mmEquivalent: 508),
        SizeValue(name: '22 inch', value: '22', mmEquivalent: 559),
        SizeValue(name: '24 inch', value: '24', mmEquivalent: 610),
      ],
    ),
    SizeOption(
      category: 'Bracelet',
      sizes: [
        SizeValue(name: '6 inch', value: '6', mmEquivalent: 152),
        SizeValue(name: '6.5 inch', value: '6.5', mmEquivalent: 165),
        SizeValue(name: '7 inch', value: '7', mmEquivalent: 178),
        SizeValue(name: '7.5 inch', value: '7.5', mmEquivalent: 190),
        SizeValue(name: '8 inch', value: '8', mmEquivalent: 203),
      ],
    ),
    SizeOption(
      category: 'Bangle',
      sizes: [
        SizeValue(name: '2.2', value: '2.2', mmEquivalent: 56),
        SizeValue(name: '2.4', value: '2.4', mmEquivalent: 61),
        SizeValue(name: '2.6', value: '2.6', mmEquivalent: 66),
        SizeValue(name: '2.8', value: '2.8', mmEquivalent: 71),
        SizeValue(name: '2.10', value: '2.10', mmEquivalent: 76),
      ],
    ),
  ];
}

/// Individual size value
class SizeValue {
  final String name; // Display name (e.g., "US 6", "18 inch")
  final String value; // Value for storage
  final double? mmEquivalent; // Millimeter equivalent
  final String? code; // Internal code

  const SizeValue({
    required this.name,
    required this.value,
    this.mmEquivalent,
    this.code,
  });

  factory SizeValue.fromJson(Map<String, dynamic> json) {
    return SizeValue(
      name: json['name']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      mmEquivalent: json['mmEquivalent']?.toDouble(),
      code: json['code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      if (mmEquivalent != null) 'mmEquivalent': mmEquivalent,
      if (code != null) 'code': code,
    };
  }
}

/// Stone type definition (master list of available stones)
class StoneType {
  final String id;
  final String name; // Diamond, Moissanite, Ruby, Emerald, CZ, AAA
  final String category; // Precious, Semi-Precious, Lab-Grown, Artificial
  final List<String> availableCuts; // Round, Oval, Pear, Princess, etc.
  final List<String> availableColors; // White, Champagne, Pink, Green, etc.
  final String? code; // Internal code
  final bool isActive;
  final int sortOrder;

  const StoneType({
    this.id = '',
    required this.name,
    required this.category,
    this.availableCuts = const [],
    this.availableColors = const [],
    this.code,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory StoneType.fromJson(Map<String, dynamic> json) {
    return StoneType(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      availableCuts: json['availableCuts'] != null
          ? List<String>.from(json['availableCuts'])
          : [],
      availableColors: json['availableColors'] != null
          ? List<String>.from(json['availableColors'])
          : [],
      code: json['code']?.toString(),
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'category': category,
      'availableCuts': availableCuts,
      'availableColors': availableColors,
      if (code != null) 'code': code,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  static List<StoneType> get defaults => [
    // Precious
    StoneType(
      name: 'Diamond',
      category: 'Precious',
      availableCuts: ['Round', 'Oval', 'Princess', 'Cushion', 'Emerald', 'Pear', 'Marquise', 'Heart', 'Radiant', 'Asscher'],
      availableColors: ['D (Colorless)', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'Fancy Yellow', 'Fancy Pink', 'Fancy Blue'],
    ),
    StoneType(
      name: 'Ruby',
      category: 'Precious',
      availableCuts: ['Round', 'Oval', 'Cushion', 'Pear', 'Heart'],
      availableColors: ['Pigeon Blood Red', 'Deep Red', 'Pinkish Red', 'Purplish Red'],
    ),
    StoneType(
      name: 'Emerald',
      category: 'Precious',
      availableCuts: ['Emerald', 'Oval', 'Round', 'Pear', 'Cushion'],
      availableColors: ['Deep Green', 'Vivid Green', 'Medium Green', 'Light Green'],
    ),
    StoneType(
      name: 'Sapphire',
      category: 'Precious',
      availableCuts: ['Round', 'Oval', 'Cushion', 'Pear', 'Princess'],
      availableColors: ['Blue', 'Yellow', 'Pink', 'White', 'Padparadscha'],
    ),
    // Lab-Grown
    StoneType(
      name: 'Moissanite',
      category: 'Lab-Grown',
      availableCuts: ['Round', 'Oval', 'Cushion', 'Pear', 'Princess', 'Emerald', 'Radiant'],
      availableColors: ['DEF (Colorless)', 'GHI (Near Colorless)', 'Champagne', 'Green', 'Blue'],
    ),
    StoneType(
      name: 'Lab Diamond',
      category: 'Lab-Grown',
      availableCuts: ['Round', 'Oval', 'Princess', 'Cushion', 'Emerald', 'Pear', 'Marquise'],
      availableColors: ['D', 'E', 'F', 'G', 'H', 'Fancy Yellow', 'Fancy Pink'],
    ),
    // Semi-Precious
    StoneType(
      name: 'Amethyst',
      category: 'Semi-Precious',
      availableCuts: ['Round', 'Oval', 'Cushion', 'Pear', 'Heart'],
      availableColors: ['Deep Purple', 'Medium Purple', 'Light Purple', 'Rose de France'],
    ),
    StoneType(
      name: 'Blue Topaz',
      category: 'Semi-Precious',
      availableCuts: ['Round', 'Oval', 'Cushion', 'Pear', 'Heart'],
      availableColors: ['Sky Blue', 'Swiss Blue', 'London Blue'],
    ),
    StoneType(
      name: 'Citrine',
      category: 'Semi-Precious',
      availableCuts: ['Round', 'Oval', 'Cushion', 'Pear'],
      availableColors: ['Golden Yellow', 'Orange', 'Madeira'],
    ),
    StoneType(
      name: 'Peridot',
      category: 'Semi-Precious',
      availableCuts: ['Round', 'Oval', 'Cushion', 'Pear'],
      availableColors: ['Lime Green', 'Olive Green', 'Yellow Green'],
    ),
    StoneType(
      name: 'Garnet',
      category: 'Semi-Precious',
      availableCuts: ['Round', 'Oval', 'Cushion', 'Pear'],
      availableColors: ['Deep Red', 'Orange', 'Green (Tsavorite)', 'Purple (Rhodolite)'],
    ),
    // Artificial
    StoneType(
      name: 'Cubic Zirconia (CZ)',
      category: 'Artificial',
      availableCuts: ['Round', 'Oval', 'Princess', 'Cushion', 'Emerald', 'Pear', 'Heart'],
      availableColors: ['Clear', 'Pink', 'Blue', 'Green', 'Yellow', 'Purple', 'Champagne'],
    ),
    StoneType(
      name: 'AAA Crystal',
      category: 'Artificial',
      availableCuts: ['Round', 'Oval', 'Princess'],
      availableColors: ['Clear', 'Aurora Borealis', 'Various'],
    ),
  ];

  /// Get all stone categories
  static List<String> get categories => ['Precious', 'Semi-Precious', 'Lab-Grown', 'Artificial'];

  /// Get all common cuts
  static List<String> get allCuts => [
    'Round', 'Oval', 'Pear', 'Princess', 'Cushion', 'Emerald',
    'Marquise', 'Heart', 'Radiant', 'Asscher', 'Baguette', 'Trillion'
  ];
}


/// Stone quality definition (e.g., AAA, AAAA, Heirloom)
class StoneQuality {
  final String name; // e.g., "Natural AAA", "Natural AAAA", "Heirloom"
  final double priceMultiplier; // e.g., 1.0, 1.3, 1.6
  final String description; // e.g., "Good quality", "Best quality"
  final String? code;
  final String? imageUrl; // Optional icon/image for the quality

  const StoneQuality({
    required this.name,
    this.priceMultiplier = 1.0,
    this.description = '',
    this.code,
    this.imageUrl,
  });

  factory StoneQuality.fromJson(Map<String, dynamic> json) {
    return StoneQuality(
      name: json['name']?.toString() ?? '',
      priceMultiplier: (json['priceMultiplier'] ?? 1.0).toDouble(),
      description: json['description']?.toString() ?? '',
      code: json['code']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'priceMultiplier': priceMultiplier,
      'description': description,
      if (code != null) 'code': code,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  static List<StoneQuality> get defaults => const [
    StoneQuality(
      name: 'Natural AAA',
      priceMultiplier: 1.0,
      description: 'Standard high-quality gemstones with good color and clarity.',
    ),
    StoneQuality(
      name: 'Natural AAAA',
      priceMultiplier: 1.4,
      description: 'Top 10% of gemstones, exhibiting superior color and brilliance.',
    ),
    StoneQuality(
      name: 'Heirloom',
      priceMultiplier: 2.0,
      description: 'The rarest 1% of gemstones, offering investment-grade quality.',
    ),
  ];
}

/// Stone configuration for a product (supports multiple stones with shapes and colors)
class StoneConfig {
  final String name; // e.g., "Center Stone", "Accent Stone A"
  final String shape; // e.g., "Oval", "Round" - default shape
  final List<String> availableColors; // e.g., ["Red", "Blue", "Clear"]
  final List<StoneQuality> availableQualities; // Categories of quality
  final String category; // Explicit category: Precious, Semi-Precious, Lab-Grown, etc.
  final int? count; // Number of stones (for accent stones)
  final Map<String, double>? colorPriceModifiers; // color -> price modifier

  // Shape selection fields
  final List<String> availableShapes; // ['Round', 'Oval', 'Princess', ...]
  final Map<String, double>? shapePriceModifiers; // shape -> price modifier

  // Diamond 4Cs grading fields
  final bool enableDiamondGrading; // Show 4Cs UI for this stone
  final List<String>? availableColorGrades; // ['D', 'E', 'F', 'G', 'H', 'I', 'J', 'K']
  final List<String>? availableClarityGrades; // ['VVS1', 'VVS2', 'VS1', 'VS2', 'SI1', 'SI2']
  final List<String>? availableCutGrades; // ['Excellent', 'Very Good', 'Good']
  final Map<String, double>? clarityPriceModifiers; // clarity -> multiplier
  final Map<String, double>? cutGradePriceModifiers; // cut -> multiplier
  final Map<String, double>? colorGradePriceModifiers; // color grade (D,E,F) -> multiplier

  // Carat weight fields
  final List<double>? availableCaratWeights; // [0.25, 0.5, 0.75, 1.0, 1.5, 2.0]
  final double? defaultCaratWeight; // Default carat weight
  final double? pricePerCarat; // Base price per carat
  final Map<double, double>? caratPriceMultipliers; // weight -> multiplier

  const StoneConfig({
    required this.name,
    required this.shape,
    required this.availableColors,
    this.availableQualities = const [],
    this.category = 'Precious',
    this.count,
    this.colorPriceModifiers,
    this.availableShapes = const [],
    this.shapePriceModifiers,
    this.enableDiamondGrading = false,
    this.availableColorGrades,
    this.availableClarityGrades,
    this.availableCutGrades,
    this.clarityPriceModifiers,
    this.cutGradePriceModifiers,
    this.colorGradePriceModifiers,
    this.availableCaratWeights,
    this.defaultCaratWeight,
    this.pricePerCarat,
    this.caratPriceMultipliers,
  });

  factory StoneConfig.fromJson(Map<String, dynamic> json) {
    return StoneConfig(
      name: json['name']?.toString() ?? '',
      shape: json['shape']?.toString() ?? '',
      availableColors: List<String>.from(json['availableColors'] ?? []),
      availableQualities: json['availableQualities'] != null
          ? (json['availableQualities'] as List).map((e) => StoneQuality.fromJson(e)).toList()
          : [],
      category: json['category']?.toString() ?? 'Precious',
      count: json['count'],
      colorPriceModifiers: json['colorPriceModifiers'] != null
          ? Map<String, double>.from(
              (json['colorPriceModifiers'] as Map).map(
                (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
              ),
            )
          : null,
      availableShapes: List<String>.from(json['availableShapes'] ?? []),
      shapePriceModifiers: json['shapePriceModifiers'] != null
          ? Map<String, double>.from(
              (json['shapePriceModifiers'] as Map).map(
                (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
              ),
            )
          : null,
      enableDiamondGrading: json['enableDiamondGrading'] ?? false,
      availableColorGrades: json['availableColorGrades'] != null
          ? List<String>.from(json['availableColorGrades'])
          : null,
      availableClarityGrades: json['availableClarityGrades'] != null
          ? List<String>.from(json['availableClarityGrades'])
          : null,
      availableCutGrades: json['availableCutGrades'] != null
          ? List<String>.from(json['availableCutGrades'])
          : null,
      clarityPriceModifiers: _parseDoubleMap(json['clarityPriceModifiers']),
      cutGradePriceModifiers: _parseDoubleMap(json['cutGradePriceModifiers']),
      colorGradePriceModifiers: _parseDoubleMap(json['colorGradePriceModifiers']),
      availableCaratWeights: json['availableCaratWeights'] != null
          ? List<double>.from((json['availableCaratWeights'] as List).map((e) => (e as num).toDouble()))
          : null,
      defaultCaratWeight: json['defaultCaratWeight']?.toDouble(),
      pricePerCarat: json['pricePerCarat']?.toDouble(),
      caratPriceMultipliers: json['caratPriceMultipliers'] != null
          ? Map<double, double>.from(
              (json['caratPriceMultipliers'] as Map).map(
                (key, value) => MapEntry(double.parse(key.toString()), (value as num).toDouble()),
              ),
            )
          : null,
    );
  }

  static Map<String, double>? _parseDoubleMap(dynamic json) {
    if (json == null) return null;
    return Map<String, double>.from(
      (json as Map).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'shape': shape,
      'availableColors': availableColors,
      'availableQualities': availableQualities.map((e) => e.toJson()).toList(),
      'category': category,
      if (count != null) 'count': count,
      if (colorPriceModifiers != null) 'colorPriceModifiers': colorPriceModifiers,
      if (availableShapes.isNotEmpty) 'availableShapes': availableShapes,
      if (shapePriceModifiers != null) 'shapePriceModifiers': shapePriceModifiers,
      'enableDiamondGrading': enableDiamondGrading,
      if (availableColorGrades != null) 'availableColorGrades': availableColorGrades,
      if (availableClarityGrades != null) 'availableClarityGrades': availableClarityGrades,
      if (availableCutGrades != null) 'availableCutGrades': availableCutGrades,
      if (clarityPriceModifiers != null) 'clarityPriceModifiers': clarityPriceModifiers,
      if (cutGradePriceModifiers != null) 'cutGradePriceModifiers': cutGradePriceModifiers,
      if (colorGradePriceModifiers != null) 'colorGradePriceModifiers': colorGradePriceModifiers,
      if (availableCaratWeights != null) 'availableCaratWeights': availableCaratWeights,
      if (defaultCaratWeight != null) 'defaultCaratWeight': defaultCaratWeight,
      if (pricePerCarat != null) 'pricePerCarat': pricePerCarat,
      if (caratPriceMultipliers != null) 'caratPriceMultipliers': caratPriceMultipliers?.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  /// Get price modifier for a specific color
  double getPriceModifier(String color) {
    return colorPriceModifiers?[color] ?? 0.0;
  }

  /// Get price modifier for a specific shape
  double getShapePriceModifier(String shape) {
    return shapePriceModifiers?[shape] ?? 0.0;
  }

  /// Get price multiplier for clarity grade
  double getClarityMultiplier(String clarity) {
    return clarityPriceModifiers?[clarity] ?? 1.0;
  }

  /// Get price multiplier for cut grade
  double getCutMultiplier(String cut) {
    return cutGradePriceModifiers?[cut] ?? 1.0;
  }

  /// Get price multiplier for color grade (D, E, F, etc.)
  double getColorGradeMultiplier(String colorGrade) {
    return colorGradePriceModifiers?[colorGrade] ?? 1.0;
  }

  /// Get price multiplier for carat weight
  double getCaratMultiplier(double carat) {
    return caratPriceMultipliers?[carat] ?? carat;
  }

  /// Get default/fallback quality if none selected
  StoneQuality get defaultQuality => availableQualities.isNotEmpty
      ? availableQualities.first
      : StoneQuality.defaults.first;

  /// Get effective shapes (fallback to common shapes if not set)
  List<String> get effectiveShapes => availableShapes.isNotEmpty
      ? availableShapes
      : defaultShapes;

  /// Default diamond/gemstone shapes
  static const List<String> defaultShapes = [
    'Round', 'Oval', 'Pear', 'Princess', 'Cushion', 'Emerald',
    'Marquise', 'Heart', 'Radiant', 'Asscher', 'Baguette', 'Trillion'
  ];

  /// Default clarity grades
  static const List<String> defaultClarityGrades = [
    'FL', 'IF', 'VVS1', 'VVS2', 'VS1', 'VS2', 'SI1', 'SI2'
  ];

  /// Default cut grades
  static const List<String> defaultCutGrades = [
    'Excellent', 'Very Good', 'Good', 'Fair'
  ];

  /// Default color grades for diamonds
  static const List<String> defaultColorGrades = [
    'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K'
  ];

  /// Default carat weights
  static const List<double> defaultCaratWeights = [
    0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 2.00, 2.50, 3.00
  ];
}

/// Selected customization options for cart/order
class ProductCustomization {
  final String? metalType; // e.g., "14K Gold"
  final String? platingColor; // e.g., "Rose Gold"
  final Map<String, String>? stoneColorSelections; // stone name -> selected color
  final Map<String, String>? stoneQualitySelections; // stone name -> selected quality name
  final String? ringSize;
  final String? engraving;
  final double? minThickness;
  final double? maxThickness;

  // New fields for enhanced customization
  final Map<String, String>? stoneShapeSelections; // stone name -> selected shape
  final Map<String, DiamondGrading>? stoneDiamondGrading; // stone name -> 4Cs grading
  final Map<String, double>? stoneCaratWeights; // stone name -> carat weight

  const ProductCustomization({
    this.metalType,
    this.platingColor,
    this.stoneColorSelections,
    this.stoneQualitySelections,
    this.ringSize,
    this.engraving,
    this.minThickness,
    this.maxThickness,
    this.stoneShapeSelections,
    this.stoneDiamondGrading,
    this.stoneCaratWeights,
  });

  factory ProductCustomization.fromJson(Map<String, dynamic> json) {
    return ProductCustomization(
      metalType: json['metalType']?.toString(),
      platingColor: json['platingColor']?.toString(),
      stoneColorSelections: json['stoneColorSelections'] != null
          ? Map<String, String>.from(json['stoneColorSelections'])
          : null,
      stoneQualitySelections: json['stoneQualitySelections'] != null
          ? Map<String, String>.from(json['stoneQualitySelections'])
          : null,
      ringSize: json['ringSize']?.toString(),
      engraving: json['engraving']?.toString(),
      minThickness: json['minThickness']?.toDouble(),
      maxThickness: json['maxThickness']?.toDouble(),
      stoneShapeSelections: json['stoneShapeSelections'] != null
          ? Map<String, String>.from(json['stoneShapeSelections'])
          : null,
      stoneDiamondGrading: json['stoneDiamondGrading'] != null
          ? (json['stoneDiamondGrading'] as Map).map(
              (key, value) => MapEntry(key.toString(), DiamondGrading.fromJson(value)),
            )
          : null,
      stoneCaratWeights: json['stoneCaratWeights'] != null
          ? Map<String, double>.from(
              (json['stoneCaratWeights'] as Map).map(
                (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (metalType != null) 'metalType': metalType,
      if (platingColor != null) 'platingColor': platingColor,
      if (stoneColorSelections != null) 'stoneColorSelections': stoneColorSelections,
      if (stoneQualitySelections != null) 'stoneQualitySelections': stoneQualitySelections,
      if (ringSize != null) 'ringSize': ringSize,
      if (engraving != null) 'engraving': engraving,
      if (minThickness != null) 'minThickness': minThickness,
      if (maxThickness != null) 'maxThickness': maxThickness,
      if (stoneShapeSelections != null) 'stoneShapeSelections': stoneShapeSelections,
      if (stoneDiamondGrading != null) 'stoneDiamondGrading': stoneDiamondGrading?.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      if (stoneCaratWeights != null) 'stoneCaratWeights': stoneCaratWeights,
    };
  }

  /// Get summary text for display
  List<String> getSummaryLines() {
    final lines = <String>[];
    if (metalType != null) lines.add('Metal: $metalType');
    if (platingColor != null) lines.add('Plating: $platingColor');
    if (stoneColorSelections != null && stoneColorSelections!.isNotEmpty) {
      stoneColorSelections!.forEach((stone, color) {
        final shape = stoneShapeSelections?[stone];
        final carat = stoneCaratWeights?[stone];
        final grading = stoneDiamondGrading?[stone];

        String summary = '$stone: $color';
        if (shape != null) summary += ' ($shape)';
        if (carat != null) summary += ' ${carat}ct';
        if (grading != null) summary += ' [${grading.shortSummary}]';
        lines.add(summary);
      });
    }
    if (ringSize != null) lines.add('Size: $ringSize');
    if (minThickness != null || maxThickness != null) {
      lines.add('Thickness: ${minThickness ?? '-'}mm - ${maxThickness ?? '-'}mm');
    }
    if (engraving != null && engraving!.isNotEmpty) {
      lines.add('Engraving: "$engraving"');
    }
    return lines;
  }

  /// Create a copy with updated values
  ProductCustomization copyWith({
    String? metalType,
    String? platingColor,
    Map<String, String>? stoneColorSelections,
    Map<String, String>? stoneQualitySelections,
    String? ringSize,
    String? engraving,
    double? minThickness,
    double? maxThickness,
    Map<String, String>? stoneShapeSelections,
    Map<String, DiamondGrading>? stoneDiamondGrading,
    Map<String, double>? stoneCaratWeights,
  }) {
    return ProductCustomization(
      metalType: metalType ?? this.metalType,
      platingColor: platingColor ?? this.platingColor,
      stoneColorSelections: stoneColorSelections ?? this.stoneColorSelections,
      stoneQualitySelections: stoneQualitySelections ?? this.stoneQualitySelections,
      ringSize: ringSize ?? this.ringSize,
      engraving: engraving ?? this.engraving,
      minThickness: minThickness ?? this.minThickness,
      maxThickness: maxThickness ?? this.maxThickness,
      stoneShapeSelections: stoneShapeSelections ?? this.stoneShapeSelections,
      stoneDiamondGrading: stoneDiamondGrading ?? this.stoneDiamondGrading,
      stoneCaratWeights: stoneCaratWeights ?? this.stoneCaratWeights,
    );
  }
}

/// Diamond 4Cs grading selection
class DiamondGrading {
  final String colorGrade; // D, E, F, G, H, I, J, K
  final String clarityGrade; // FL, IF, VVS1, VVS2, VS1, VS2, SI1, SI2
  final String cutGrade; // Excellent, Very Good, Good, Fair

  const DiamondGrading({
    required this.colorGrade,
    required this.clarityGrade,
    required this.cutGrade,
  });

  factory DiamondGrading.fromJson(Map<String, dynamic> json) {
    return DiamondGrading(
      colorGrade: json['colorGrade']?.toString() ?? 'G',
      clarityGrade: json['clarityGrade']?.toString() ?? 'VS1',
      cutGrade: json['cutGrade']?.toString() ?? 'Very Good',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colorGrade': colorGrade,
      'clarityGrade': clarityGrade,
      'cutGrade': cutGrade,
    };
  }

  /// Short summary for display
  String get shortSummary => '$colorGrade/$clarityGrade/$cutGrade';

  /// Full description
  String get fullDescription => 'Color: $colorGrade, Clarity: $clarityGrade, Cut: $cutGrade';

  /// Calculate combined price multiplier
  double calculateMultiplier({
    Map<String, double>? colorMultipliers,
    Map<String, double>? clarityMultipliers,
    Map<String, double>? cutMultipliers,
  }) {
    final colorMult = colorMultipliers?[colorGrade] ?? GradingPriceTable.colorMultipliers[colorGrade] ?? 1.0;
    final clarityMult = clarityMultipliers?[clarityGrade] ?? GradingPriceTable.clarityMultipliers[clarityGrade] ?? 1.0;
    final cutMult = cutMultipliers?[cutGrade] ?? GradingPriceTable.cutMultipliers[cutGrade] ?? 1.0;
    return colorMult * clarityMult * cutMult;
  }

  /// Default grading
  static const DiamondGrading defaultGrading = DiamondGrading(
    colorGrade: 'G',
    clarityGrade: 'VS1',
    cutGrade: 'Very Good',
  );
}

/// Default price multipliers for diamond grading
class GradingPriceTable {
  static const Map<String, double> colorMultipliers = {
    'D': 2.00, 'E': 1.80, 'F': 1.60, 'G': 1.40,
    'H': 1.25, 'I': 1.15, 'J': 1.05, 'K': 1.00,
  };

  static const Map<String, double> clarityMultipliers = {
    'FL': 2.50, 'IF': 2.20, 'VVS1': 1.80, 'VVS2': 1.60,
    'VS1': 1.40, 'VS2': 1.25, 'SI1': 1.10, 'SI2': 1.00,
  };

  static const Map<String, double> cutMultipliers = {
    'Excellent': 1.30, 'Very Good': 1.15, 'Good': 1.00, 'Fair': 0.85,
  };

  /// Get description for color grade
  static String getColorDescription(String grade) {
    switch (grade) {
      case 'D': return 'Absolutely colorless - Highest color grade';
      case 'E': return 'Colorless - Minute traces of color';
      case 'F': return 'Colorless - Slight color detected by expert';
      case 'G': return 'Near colorless - Color difficult to detect';
      case 'H': return 'Near colorless - Color noticeable when compared';
      case 'I': return 'Near colorless - Slightly detectable color';
      case 'J': return 'Near colorless - Noticeable color';
      case 'K': return 'Faint color - Noticeable color';
      default: return 'Standard color grade';
    }
  }

  /// Get description for clarity grade
  static String getClarityDescription(String grade) {
    switch (grade) {
      case 'FL': return 'Flawless - No inclusions or blemishes';
      case 'IF': return 'Internally Flawless - No inclusions';
      case 'VVS1': return 'Very Very Slightly Included - Difficult to see';
      case 'VVS2': return 'Very Very Slightly Included - Somewhat difficult to see';
      case 'VS1': return 'Very Slightly Included - Minor inclusions';
      case 'VS2': return 'Very Slightly Included - Minor inclusions visible';
      case 'SI1': return 'Slightly Included - Noticeable inclusions';
      case 'SI2': return 'Slightly Included - Easily noticeable inclusions';
      default: return 'Standard clarity grade';
    }
  }

  /// Get description for cut grade
  static String getCutDescription(String grade) {
    switch (grade) {
      case 'Excellent': return 'Maximum fire and brilliance';
      case 'Very Good': return 'Superior light reflection';
      case 'Good': return 'Good light reflection';
      case 'Fair': return 'Adequate light reflection';
      default: return 'Standard cut grade';
    }
  }
}
