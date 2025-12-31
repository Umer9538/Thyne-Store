import 'package:flutter/foundation.dart';
import '../../data/models/store_settings.dart';
import '../../data/services/api_service.dart';

/// Provider for managing store settings (GST, shipping, etc.)
class StoreSettingsProvider extends ChangeNotifier {
  StoreSettings _settings = StoreSettings.defaults;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  StoreSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Convenience getters
  double get gstRate => _settings.gstRate;
  double get shippingCost => _settings.shippingCost;
  double get freeShippingThreshold => _settings.freeShippingThreshold;
  bool get enableGst => _settings.enableGst;
  bool get enableFreeShipping => _settings.enableFreeShipping;
  bool get enableCod => _settings.enableCod;
  String get currencySymbol => _settings.currencySymbol;

  /// Load store settings from API
  Future<void> loadSettings() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getStoreSettings();

      if (response['success'] == true && response['data'] != null) {
        _settings = StoreSettings.fromJson(response['data']);
        _isInitialized = true;
      } else {
        _error = response['message'] ?? 'Failed to load settings';
      }
    } catch (e) {
      _error = 'Failed to load store settings: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update store settings (admin only)
  Future<bool> updateSettings(StoreSettings newSettings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateStoreSettings(newSettings.toJson());

      if (response['success'] == true) {
        _settings = newSettings;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update settings';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to update store settings: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate tax for a given subtotal
  double calculateTax(double subtotal) {
    return _settings.calculateTax(subtotal);
  }

  /// Calculate shipping for a given subtotal
  double calculateShipping(double subtotal) {
    return _settings.calculateShipping(subtotal);
  }

  /// Check if COD is available for order total
  bool isCodAvailable(double orderTotal) {
    return _settings.isCodAvailable(orderTotal);
  }

  /// Get formatted price with currency symbol
  String formatPrice(double price) {
    return '${_settings.currencySymbol}${price.toStringAsFixed(0)}';
  }

  /// Initialize settings if not already loaded
  Future<void> ensureInitialized() async {
    if (!_isInitialized && !_isLoading) {
      await loadSettings();
    }
  }
}
