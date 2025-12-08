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
  final List<String> platingColors;
  final List<String> stoneShapes;
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
    List<String>? platingColors,
    List<String>? stoneShapes,
    this.maxEngravingChars = 15,
    this.updatedAt,
  }) : metalOptions = metalOptions ?? MetalOption.defaults,
       platingColors = platingColors ?? const ['White Gold', 'Yellow Gold', 'Rose Gold', 'Rustic Silver'],
       stoneShapes = stoneShapes ?? const ['Round', 'Oval', 'Princess', 'Cushion', 'Emerald', 'Pear', 'Marquise', 'Heart'];

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
          ? List<String>.from(json['platingColors'])
          : null,
      stoneShapes: json['stoneShapes'] != null
          ? List<String>.from(json['stoneShapes'])
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
      'platingColors': platingColors,
      'stoneShapes': stoneShapes,
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
    List<String>? platingColors,
    List<String>? stoneShapes,
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
      stoneShapes: stoneShapes ?? this.stoneShapes,
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
  final String type; // Gold, Silver, Platinum
  final List<String> variants; // 9K, 14K, 22K for Gold; 925 for Silver

  const MetalOption({
    required this.type,
    required this.variants,
  });

  factory MetalOption.fromJson(Map<String, dynamic> json) {
    return MetalOption(
      type: json['type']?.toString() ?? '',
      variants: List<String>.from(json['variants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'variants': variants,
    };
  }

  /// Default metal options
  static List<MetalOption> get defaults => const [
    MetalOption(type: 'Gold', variants: ['9K', '14K', '18K', '22K']),
    MetalOption(type: 'Silver', variants: ['925 Sterling']),
    MetalOption(type: 'Platinum', variants: ['950 Platinum']),
  ];

  /// Get display string (e.g., "14K Gold")
  String getDisplayName(String variant) => '$variant $type';
}

/// Stone configuration for a product (supports multiple stones with shapes and colors)
class StoneConfig {
  final String name; // e.g., "Center Stone", "Accent Stone A"
  final String shape; // e.g., "Oval", "Round"
  final List<String> availableColors; // e.g., ["Red", "Blue", "Clear"]
  final int? count; // Number of stones (for accent stones)
  final Map<String, double>? colorPriceModifiers; // color -> price modifier

  const StoneConfig({
    required this.name,
    required this.shape,
    required this.availableColors,
    this.count,
    this.colorPriceModifiers,
  });

  factory StoneConfig.fromJson(Map<String, dynamic> json) {
    return StoneConfig(
      name: json['name']?.toString() ?? '',
      shape: json['shape']?.toString() ?? '',
      availableColors: List<String>.from(json['availableColors'] ?? []),
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
      if (count != null) 'count': count,
      if (colorPriceModifiers != null) 'colorPriceModifiers': colorPriceModifiers,
    };
  }

  /// Get price modifier for a specific color
  double getPriceModifier(String color) {
    return colorPriceModifiers?[color] ?? 0.0;
  }
}

/// Selected customization options for cart/order
class ProductCustomization {
  final String? metalType; // e.g., "14K Gold"
  final String? platingColor; // e.g., "Rose Gold"
  final Map<String, String>? stoneColorSelections; // stone name -> selected color
  final String? ringSize;
  final String? engraving;
  final double? minThickness;
  final double? maxThickness;

  const ProductCustomization({
    this.metalType,
    this.platingColor,
    this.stoneColorSelections,
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
