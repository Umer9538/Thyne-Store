import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AddressProvider with ChangeNotifier {
  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _error;

  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  void setAddresses(List<Address> addresses) {
    _addresses = addresses;
    notifyListeners();
  }

  Future<void> loadAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getProfile();
      if (response['success'] == true && response['data'] != null) {
        final user = User.fromJson(response['data']);
        _addresses = user.addresses;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress({
    required String street,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    bool isDefault = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.addAddress(
        street: street,
        city: city,
        state: state,
        zipCode: zipCode,
        country: country,
        isDefault: isDefault,
      );

      if (response['success'] == true) {
        await loadAddresses(); // Reload addresses to get updated list
        return true;
      } else {
        _error = response['error'] ?? 'Failed to add address';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAddress({
    required String addressId,
    required String street,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    bool isDefault = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateAddress(
        addressId: addressId,
        street: street,
        city: city,
        state: state,
        zipCode: zipCode,
        country: country,
        isDefault: isDefault,
      );

      if (response['success'] == true) {
        await loadAddresses(); // Reload addresses to get updated list
        return true;
      } else {
        _error = response['error'] ?? 'Failed to update address';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.deleteAddress(addressId: addressId);

      if (response['success'] == true) {
        _addresses.removeWhere((address) => address.id == addressId);
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to delete address';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setDefaultAddress(String addressId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.setDefaultAddress(addressId: addressId);

      if (response['success'] == true) {
        await loadAddresses(); // Reload addresses to get updated list
        return true;
      } else {
        _error = response['error'] ?? 'Failed to set default address';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
