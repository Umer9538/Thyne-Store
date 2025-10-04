import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      product: Product.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
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