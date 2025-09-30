import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Product> _wishlist = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get wishlist => _wishlist;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get wishlistCount => _wishlist.length;

  bool isInWishlist(String productId) {
    return _wishlist.any((product) => product.id == productId);
  }

  Future<void> loadWishlist() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.getWishlist();
      
      if (response['success'] == true) {
        final productsData = response['data']['products'] as List;
        _wishlist.clear();
        
        for (final productJson in productsData) {
          final product = Product.fromJson(productJson);
          _wishlist.add(product);
        }
        
        notifyListeners();
      } else {
        throw Exception(response['error'] ?? 'Failed to load wishlist');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading wishlist: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addToWishlist(String productId) async {
    try {
      final response = await ApiService.addToWishlist(productId: productId);
      
      if (response['success'] == true) {
        // Reload wishlist to get updated data
        await loadWishlist();
        return true;
      } else {
        throw Exception(response['error'] ?? 'Failed to add to wishlist');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding to wishlist: $e');
      return false;
    }
  }

  Future<bool> removeFromWishlist(String productId) async {
    try {
      final response = await ApiService.removeFromWishlist(productId: productId);
      
      if (response['success'] == true) {
        // Remove from local list immediately for better UX
        _wishlist.removeWhere((product) => product.id == productId);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['error'] ?? 'Failed to remove from wishlist');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error removing from wishlist: $e');
      return false;
    }
  }

  Future<void> toggleWishlist(String productId) async {
    if (isInWishlist(productId)) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(productId);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

