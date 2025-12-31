import 'product.dart';
import 'store_settings.dart';

/// Bundle info for cart items that are part of a bundle
class BundleInfo {
  final String bundleId;
  final String bundleName;
  final double bundlePrice;
  final double originalPrice;
  final int discountPercent;

  const BundleInfo({
    required this.bundleId,
    required this.bundleName,
    required this.bundlePrice,
    required this.originalPrice,
    required this.discountPercent,
  });

  factory BundleInfo.fromJson(Map<String, dynamic> json) {
    return BundleInfo(
      bundleId: json['bundleId'] ?? '',
      bundleName: json['bundleName'] ?? '',
      bundlePrice: (json['bundlePrice'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0,
      discountPercent: json['discountPercent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bundleId': bundleId,
      'bundleName': bundleName,
      'bundlePrice': bundlePrice,
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
    };
  }
}

class CartItem {
  final String id;
  final Product product;
  int quantity;
  final double? salePrice; // Optional sale price for deals/flash sales
  final double? originalPrice; // Optional original price for display
  final int? discountPercent; // Optional discount percentage for display
  final ProductCustomization? customization; // Product customization options
  final BundleInfo? bundleInfo; // Bundle info if this item is part of a bundle

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.salePrice,
    this.originalPrice,
    this.discountPercent,
    this.customization,
    this.bundleInfo,
  });

  // Check if this item is part of a bundle
  bool get isPartOfBundle => bundleInfo != null;

  // Use sale price if available, otherwise calculate customized price
  double get effectivePrice {
    if (salePrice != null) return salePrice!;
    return product.calculateCustomizedPrice(customization);
  }

  double get totalPrice => effectivePrice * quantity;

  // Check if this item has a special sale price
  bool get hasSalePrice => salePrice != null && salePrice! < (originalPrice ?? product.price);

  // Check if this item has customizations
  bool get hasCustomization => customization != null && (
    customization!.metalType != null ||
    customization!.platingColor != null ||
    customization!.ringSize != null ||
    (customization!.stoneColorSelections?.isNotEmpty ?? false) ||
    (customization!.engraving?.isNotEmpty ?? false)
  );

  // Generate unique key for cart item (product + customization combination)
  String get uniqueKey {
    if (!hasCustomization) return product.id;
    final customKey = [
      customization?.metalType ?? '',
      customization?.platingColor ?? '',
      customization?.ringSize ?? '',
      customization?.engraving ?? '',
      ...?(customization?.stoneColorSelections?.entries.map((e) => '${e.key}:${e.value}')),
    ].join('|');
    return '${product.id}_$customKey';
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      product: Product.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 1,
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discountPercent: json['discountPercent'] as int?,
      customization: json['customization'] != null
          ? ProductCustomization.fromJson(json['customization'])
          : null,
      bundleInfo: json['bundleInfo'] != null
          ? BundleInfo.fromJson(json['bundleInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      if (salePrice != null) 'salePrice': salePrice,
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (customization != null) 'customization': customization!.toJson(),
      if (bundleInfo != null) 'bundleInfo': bundleInfo!.toJson(),
    };
  }

  /// Copy with updated fields
  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? salePrice,
    double? originalPrice,
    int? discountPercent,
    ProductCustomization? customization,
    BundleInfo? bundleInfo,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice ?? this.salePrice,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      customization: customization ?? this.customization,
      bundleInfo: bundleInfo ?? this.bundleInfo,
    );
  }
}

class Cart {
  final List<CartItem> items;
  final String? couponCode;
  final double discount;

  Cart({
    this.items = const [],
    this.couponCode,
    this.discount = 0.0,
  });

  double get subtotal {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get tax {
    return subtotal * 0.18;
  }

  double get shipping {
    return subtotal > 1000 ? 0 : 99;
  }

  double get total {
    return subtotal - discount + tax + shipping;
  }

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}