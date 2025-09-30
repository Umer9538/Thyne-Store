import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _couponCode;
  double _discount = 0.0;

  List<CartItem> get items => _items;
  String? get couponCode => _couponCode;
  double get discount => _discount;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get tax {
    return subtotal * 0.18; // 18% GST
  }

  double get shipping {
    return subtotal > 1000 ? 0 : 99; // Free shipping above ₹1000
  }

  double get total {
    return subtotal - discount + tax + shipping;
  }

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        quantity: quantity,
      ));
    }

    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        notifyListeners();
      } else {
        removeFromCart(productId);
      }
    }
  }

  void applyCoupon(String code) {
    // Simulate coupon validation
    if (code.toUpperCase() == 'FIRST10') {
      _couponCode = code;
      _discount = subtotal * 0.1; // 10% discount
    } else if (code.toUpperCase() == 'JEWEL20') {
      _couponCode = code;
      _discount = subtotal * 0.2; // 20% discount
    } else {
      _couponCode = null;
      _discount = 0;
    }
    notifyListeners();
  }

  void removeCoupon() {
    _couponCode = null;
    _discount = 0;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _couponCode = null;
    _discount = 0;
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getProductQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(
        id: '',
        product: Product(
          id: '',
          name: '',
          description: '',
          price: 0,
          images: [],
          category: '',
          subcategory: '',
          metalType: '',
          stockQuantity: 0,
          createdAt: DateTime.now(),
        ),
        quantity: 0,
      ),
    );
    return item.quantity;
  }
}