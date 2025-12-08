import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/store_settings.dart';
import '../services/api_service.dart';

export '../models/store_settings.dart' show ProductCustomization;
export '../models/cart.dart' show BundleInfo;

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _couponCode;
  double _discount = 0.0;

  // Store settings for dynamic tax and shipping
  StoreSettings _storeSettings = StoreSettings.defaults;
  bool _settingsLoaded = false;

  List<CartItem> get items => _items;
  String? get couponCode => _couponCode;
  double get discount => _discount;
  StoreSettings get storeSettings => _storeSettings;
  bool get settingsLoaded => _settingsLoaded;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get tax {
    if (!_storeSettings.enableGst) return 0.0;
    return subtotal * (_storeSettings.gstRate / 100);
  }

  double get shipping {
    if (_storeSettings.enableFreeShipping && subtotal >= _storeSettings.freeShippingThreshold) {
      return 0.0;
    }
    return _storeSettings.shippingCost;
  }

  double get total {
    return subtotal - discount + tax + shipping;
  }

  // Convenience getters for UI
  double get gstRate => _storeSettings.gstRate;
  double get freeShippingThreshold => _storeSettings.freeShippingThreshold;
  bool get hasFreeShipping => shipping == 0;
  String get currencySymbol => _storeSettings.currencySymbol;

  /// Load store settings from API
  Future<void> loadStoreSettings() async {
    if (_settingsLoaded) return;

    try {
      final response = await ApiService.getStoreSettings();
      if (response['success'] == true && response['data'] != null) {
        _storeSettings = StoreSettings.fromJson(response['data']);
        _settingsLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load store settings: $e');
      // Keep using defaults if loading fails
    }
  }

  /// Update store settings (for when settings change)
  void updateStoreSettings(StoreSettings settings) {
    _storeSettings = settings;
    _settingsLoaded = true;
    notifyListeners();
  }

  void addToCart(
    Product product, {
    int quantity = 1,
    double? salePrice,
    double? originalPrice,
    int? discountPercent,
    ProductCustomization? customization,
    BundleInfo? bundleInfo,
  }) {
    // Create a temporary item to get the unique key
    final tempItem = CartItem(
      id: '',
      product: product,
      customization: customization,
      bundleInfo: bundleInfo,
    );

    // For bundle items, use bundleId + productId as unique key
    final uniqueKey = bundleInfo != null
        ? '${bundleInfo.bundleId}_${product.id}'
        : tempItem.uniqueKey;

    // Find existing item with same product + customization/bundle combination
    final existingIndex = _items.indexWhere((item) {
      if (bundleInfo != null) {
        return item.bundleInfo?.bundleId == bundleInfo.bundleId &&
               item.product.id == product.id;
      }
      return item.uniqueKey == uniqueKey && item.bundleInfo == null;
    });

    if (existingIndex >= 0) {
      final existingItem = _items[existingIndex];
      // If adding with sale price, or existing item has sale price, preserve the better deal
      // Replace item to update sale price info (since fields are final)
      final newSalePrice = salePrice ?? existingItem.salePrice;
      final newOriginalPrice = originalPrice ?? existingItem.originalPrice;
      final newDiscountPercent = discountPercent ?? existingItem.discountPercent;

      _items[existingIndex] = CartItem(
        id: existingItem.id,
        product: product,
        quantity: existingItem.quantity + quantity,
        salePrice: newSalePrice,
        originalPrice: newOriginalPrice,
        discountPercent: newDiscountPercent,
        customization: customization ?? existingItem.customization,
        bundleInfo: bundleInfo ?? existingItem.bundleInfo,
      );
    } else {
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        quantity: quantity,
        salePrice: salePrice,
        originalPrice: originalPrice,
        discountPercent: discountPercent,
        customization: customization,
        bundleInfo: bundleInfo,
      ));
    }

    notifyListeners();
  }

  /// Remove a bundle from cart by bundleId
  void removeBundleFromCart(String bundleId) {
    _items.removeWhere((item) => item.bundleInfo?.bundleId == bundleId);
    notifyListeners();
  }

  /// Get items grouped by bundleId (for display)
  Map<String?, List<CartItem>> get itemsGroupedByBundle {
    final grouped = <String?, List<CartItem>>{};
    for (final item in _items) {
      final key = item.bundleInfo?.bundleId;
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
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