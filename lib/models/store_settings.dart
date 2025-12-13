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
  final String shape; // e.g., "Oval", "Round"
  final List<String> availableColors; // e.g., ["Red", "Blue", "Clear"]
  final List<StoneQuality> availableQualities; // Categories of quality
  final String category; // Explicit category: Precious, Semi-Precious, Lab-Grown, etc.
  final int? count; // Number of stones (for accent stones)
  final Map<String, double>? colorPriceModifiers; // color -> price modifier

  const StoneConfig({
    required this.name,
    required this.shape,
    required this.availableColors,
    this.availableQualities = const [],
    this.category = 'Precious',
    this.count,
    this.colorPriceModifiers,
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
    };
  }

  /// Get price modifier for a specific color
  double getPriceModifier(String color) {
    return colorPriceModifiers?[color] ?? 0.0;
  }
  
  /// Get default/fallback quality if none selected
  StoneQuality get defaultQuality => availableQualities.isNotEmpty 
      ? availableQualities.first 
      : StoneQuality.defaults.first;
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

  const ProductCustomization({
    this.metalType,
    this.platingColor,
    this.stoneColorSelections,
    this.stoneQualitySelections,
    this.ringSize,
    this.engraving,
    this.minThickness,
    this.maxThickness,
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
    };
  }

  /// Get summary text for display
  List<String> getSummaryLines() {
    final lines = <String>[];
    if (metalType != null) lines.add('Metal: $metalType');
    if (platingColor != null) lines.add('Plating: $platingColor');
    if (stoneColorSelections != null && stoneColorSelections!.isNotEmpty) {
      stoneColorSelections!.forEach((stone, color) {
        lines.add('$stone: $color');
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
}
