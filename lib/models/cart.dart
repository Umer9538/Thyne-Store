import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;
  final double? salePrice; // Optional sale price for deals/flash sales
  final double? originalPrice; // Optional original price for display
  final int? discountPercent; // Optional discount percentage for display

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.salePrice,
    this.originalPrice,
    this.discountPercent,
  });

  // Use sale price if available, otherwise use product price
  double get effectivePrice => salePrice ?? product.price;

  double get totalPrice => effectivePrice * quantity;

  // Check if this item has a special sale price
  bool get hasSalePrice => salePrice != null && salePrice! < (originalPrice ?? product.price);

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      product: Product.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 1,
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discountPercent: json['discountPercent'] as int?,
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
    };
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