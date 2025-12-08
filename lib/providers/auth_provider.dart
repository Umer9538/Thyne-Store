import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'loyalty_provider.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Callback for triggering loyalty program loading after login
  void Function(String userId)? _onLoginSuccess;
  // Callback for cleanup on logout
  void Function()? _onLogout;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  
  // Set callback for loyalty program loading
  void setOnLoginSuccess(void Function(String userId) callback) {
    _onLoginSuccess = callback;
  }

  // Set callback for logout cleanup
  void setOnLogout(void Function() callback) {
    _onLogout = callback;
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.login(email: email, password: password);
      if (response['success'] == true && response['data'] != null) {
        final userData = response['data']['user'];
        _user = User.fromJson(userData);
        
        // Store tokens
        await _storage.write(key: 'auth_token', value: response['data']['accessToken']);
        await _storage.write(key: 'refresh_token', value: response['data']['refreshToken']);
        await _storage.write(key: 'user_id', value: _user!.id);
        
        // Save user session
        await StorageService.saveCurrentUser(userData);
        
        // Trigger loyalty program loading for daily login bonus
        _onLoginSuccess?.call(_user!.id);
        
        notifyListeners();
      } else {
        _error = response['error'] ?? 'Invalid email or password';
        notifyListeners();
      }
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Login failed. Please try again.';
      }
      debugPrint('Login error: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      
      if (response['success'] == true && response['data'] != null) {
        final userData = response['data']['user'];
        _user = User.fromJson(userData);
        
        // Store tokens
        await _storage.write(key: 'auth_token', value: response['data']['accessToken']);
        await _storage.write(key: 'refresh_token', value: response['data']['refreshToken']);
        await _storage.write(key: 'user_id', value: _user!.id);
        
        // Save user session
        await StorageService.saveCurrentUser(userData);
        
        notifyListeners();
      } else {
        _error = response['error'] ?? 'Registration failed. Please try again.';
        notifyListeners();
      }
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Registration failed. Please try again.';
      }
      debugPrint('Registration error: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await StorageService.clearCurrentUser();
    // Trigger logout cleanup callback
    _onLogout?.call();
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.forgotPassword(email: email);
      
      if (response['success'] == true) {
        // Password reset email sent successfully
      } else {
        _error = response['error'] ?? 'Failed to send reset email. Please try again.';
      }
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Failed to send reset email. Please try again.';
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.updateProfile(
        name: name,
        phone: phone,
        profileImage: profileImage,
      );
      
      if (response['success'] == true) {
        final userData = response['data'];
        _user = User.fromJson(userData);
        notifyListeners();
      } else {
        _error = response['error'] ?? 'Failed to update profile';
        notifyListeners();
      }
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Failed to update profile';
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Convert guest session to registered user with guest info
  Future<void> registerFromGuest({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? guestSessionId,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Store guest session ID temporarily for the registration call
      if (guestSessionId != null) {
        await _storage.write(key: 'guest_session_id', value: guestSessionId);
      }

      final response = await ApiService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      
      if (response['success'] == true) {
        final userData = response['data']['user'];
        _user = User.fromJson(userData);
        
        // Store tokens
        await _storage.write(key: 'auth_token', value: response['data']['accessToken']);
        await _storage.write(key: 'refresh_token', value: response['data']['refreshToken']);
        
        // Clear guest session ID after successful registration
        await _storage.delete(key: 'guest_session_id');

        notifyListeners();
      } else {
        _error = response['error'] ?? 'Registration failed. Please try again.';
        notifyListeners();
      }
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Registration failed. Please try again.';
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Quick login from guest checkout
  Future<void> loginFromGuest(String email, String password) async {
    await login(email, password);
  }

  /// Check if email exists (for guest conversion)
  Future<bool> checkEmailExists(String email) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // Mock email check - in real app this would be an API call
      return email.toLowerCase() == 'existing@user.com';
    } catch (e) {
      return false;
    }
  }

  /// Send OTP to phone number
  Future<bool> sendPhoneOTP(String phoneNumber) async {
    _setLoading(true);
    _error = null;

    try {
      // In production, this would call the actual API
      // For now, we'll simulate the OTP sending
      await Future.delayed(const Duration(seconds: 1));

      // Store phone number temporarily
      await _storage.write(key: 'temp_phone', value: phoneNumber);

      // Hardcoded OTP for development/testing: 950138
      debugPrint('OTP sent to $phoneNumber');

      return true;
    } catch (e) {
      _error = 'Failed to send OTP. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify phone OTP and login/register user
  Future<bool> verifyPhoneOTP(
    String phoneNumber,
    String otp, {
    bool notifyOrders = true,
    bool subscribeNewsletter = false,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Hardcoded OTP for development/testing: 950138
      if (otp == '950138') {
        // Check if user exists with this phone number
        // If not, create new user
        final userData = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'phone': phoneNumber,
          'name': 'User',
          'email': null,
          'isAdmin': false,
          'role': 'customer',
          'notifyOrders': notifyOrders,
          'subscribeNewsletter': subscribeNewsletter,
        };

        _user = User.fromJson(userData);

        // Generate mock tokens
        await _storage.write(key: 'auth_token', value: 'mock_token_${phoneNumber}');
        await _storage.write(key: 'refresh_token', value: 'mock_refresh_${phoneNumber}');
        await _storage.write(key: 'user_id', value: _user!.id);

        // Save user session
        await StorageService.saveCurrentUser(userData);

        // Trigger loyalty program loading
        _onLoginSuccess?.call(_user!.id);

        notifyListeners();
        return true;
      }

      // In production, verify OTP with backend
      _error = 'Invalid OTP';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Verification failed. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if user is already authenticated (called on app startup)
  Future<void> checkAuthStatus() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'user_id');

      if (token != null && userId != null) {
        // Try to get user from current session first
        final sessionUser = await StorageService.getCurrentUser();
        
        if (sessionUser != null) {
          // Handle isAdmin which could be bool, int (1/0), or String
          bool isAdmin = false;
          final adminValue = sessionUser['isAdmin'];
          if (adminValue is bool) {
            isAdmin = adminValue;
          } else if (adminValue is int) {
            isAdmin = adminValue == 1;
          } else if (adminValue is String) {
            isAdmin = adminValue.toLowerCase() == 'true' || adminValue == '1';
          }

          _user = User(
            id: sessionUser['id'].toString(),
            name: sessionUser['name']?.toString() ?? '',
            email: sessionUser['email']?.toString() ?? '',
            phone: sessionUser['phone']?.toString() ?? '',
            profileImage: sessionUser['profileImage']?.toString(),
            createdAt: sessionUser['createdAt'] != null
                ? DateTime.parse(sessionUser['createdAt'].toString())
                : DateTime.now(),
            isAdmin: isAdmin,
            role: sessionUser['role']?.toString(),
          );
          notifyListeners();

          // Trigger loyalty program loading for returning user
          _onLoginSuccess?.call(_user!.id);

          return;
        }

        // If API fails, clear session
        await _clearSession();
      }
    } catch (e) {
      // Error reading user, clear session
      debugPrint('Auth check failed: $e');
      await _clearSession();
    }
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'refresh_token');
    await StorageService.clearCurrentUser();
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      if (response['success'] == true) {
        // Password changed successfully
      } else {
        _error = response['error'] ?? 'Failed to change password';
        notifyListeners();
      }
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = 'Failed to change password';
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}