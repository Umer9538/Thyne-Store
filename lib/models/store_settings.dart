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
    this.updatedAt,
  });

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
