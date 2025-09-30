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

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  
  // Set callback for loyalty program loading
  void setOnLoginSuccess(void Function(String userId) callback) {
    _onLoginSuccess = callback;
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      // First try backend API
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
          return;
        }
      } catch (apiError) {
        debugPrint('API login error, trying local storage: $apiError');
      }

      // Fallback to local storage
      final userData = await StorageService.getUserByCredentials(email, password);

      if (userData != null) {
        _user = User(
          id: userData['id'].toString(),
          name: userData['name'],
          email: userData['email'],
          phone: userData['phone'],
          profileImage: userData['profileImage'],
          createdAt: DateTime.parse(userData['createdAt']),
          isAdmin: userData['isAdmin'] == 1,
        );

        // Store a mock token for session management
        await _storage.write(key: 'auth_token', value: 'local_token_${userData['id']}');
        await _storage.write(key: 'user_id', value: userData['id'].toString());
        
        // Save user session
        await StorageService.saveCurrentUser(userData);

        // Trigger loyalty program loading for daily login bonus
        _onLoginSuccess?.call(_user!.id);

        notifyListeners();
      } else {
        _error = 'Invalid email or password';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Login failed. Please try again.';
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
      // First try backend API
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
          return;
        }
      } catch (apiError) {
        debugPrint('API registration error, trying local storage: $apiError');
      }

      // Fallback to local storage
      try {
        final userId = await StorageService.createUser(
          name: name,
          email: email,
          phone: phone,
          password: password,
        );

        _user = User(
          id: userId.toString(),
          name: name,
          email: email,
          phone: phone,
          createdAt: DateTime.now(),
          isAdmin: false,
        );

        // Store a mock token for session management
        await _storage.write(key: 'auth_token', value: 'local_token_$userId');
        await _storage.write(key: 'user_id', value: userId.toString());
        
        // Save user session
        final userData = {
          'id': userId,
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt': DateTime.now().toIso8601String(),
          'isAdmin': 0,
        };
        await StorageService.saveCurrentUser(userData);

        notifyListeners();
      } catch (storageError) {
        _error = storageError.toString().contains('Email already exists') 
            ? 'Email already registered'
            : 'Registration failed. Please try again.';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Registration failed. Please try again.';
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
          _user = User(
            id: sessionUser['id'].toString(),
            name: sessionUser['name'] as String,
            email: sessionUser['email'] as String,
            phone: sessionUser['phone'] as String,
            profileImage: sessionUser['profileImage'] as String?,
            createdAt: DateTime.parse(sessionUser['createdAt'] as String),
            isAdmin: sessionUser['isAdmin'] == 1,
          );
          notifyListeners();
          return;
        }

        // Fallback to storage lookup
        try {
          final userData = await StorageService.getUserById(int.parse(userId));
          if (userData != null) {
            _user = User(
              id: userData['id'].toString(),
              name: userData['name'] as String,
              email: userData['email'] as String,
              phone: userData['phone'] as String,
              profileImage: userData['profileImage'] as String?,
              createdAt: DateTime.parse(userData['createdAt'] as String),
              isAdmin: userData['isAdmin'] == 1,
            );
            
            // Save to session for next time
            await StorageService.saveCurrentUser(userData);
            notifyListeners();
          } else {
            // User not found, clear session
            await _clearSession();
          }
        } catch (e) {
          debugPrint('Error getting user from storage: $e');
          await _clearSession();
        }
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