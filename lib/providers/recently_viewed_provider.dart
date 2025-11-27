import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

/// Provider for managing recently viewed products with real-time updates
class RecentlyViewedProvider extends ChangeNotifier {
  List<Product> _recentlyViewed = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get recentlyViewed => _recentlyViewed;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasItems => _recentlyViewed.isNotEmpty;

  /// Load recently viewed products from API
  Future<void> loadRecentlyViewed({int limit = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getRecentlyViewed(limit: limit);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> productsList;

        // Handle different response formats
        if (data is List) {
          productsList = data;
        } else if (data is Map && data['products'] != null) {
          productsList = data['products'] as List<dynamic>;
        } else {
          productsList = [];
        }

        _recentlyViewed = productsList
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _error = 'Failed to load recently viewed: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Track a product view and update the list
  Future<void> trackAndRefresh(String productId) async {
    try {
      await ApiService.trackProductView(productId: productId);
      // Refresh the list after tracking
      await loadRecentlyViewed();
    } catch (e) {
      debugPrint('Failed to track product view: $e');
    }
  }

  /// Add a product to the front of the list locally (optimistic update)
  void addProductLocally(Product product) {
    // Remove if already exists
    _recentlyViewed.removeWhere((p) => p.id == product.id);
    // Add to front
    _recentlyViewed.insert(0, product);
    // Keep only last 20 items
    if (_recentlyViewed.length > 20) {
      _recentlyViewed = _recentlyViewed.take(20).toList();
    }
    notifyListeners();
  }

  /// Clear all recently viewed products
  void clear() {
    _recentlyViewed.clear();
    notifyListeners();
  }
}
