import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/product.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _productsKey = 'products';
  static const String _currentUserKey = 'current_user';

  // User management methods
  static Future<List<Map<String, dynamic>>> getUsers() async {
    if (kIsWeb) {
      return _getUsersFromPrefs();
    } else {
      // For mobile/desktop, this would use SQLite
      // But we'll use SharedPreferences for consistency
      return _getUsersFromPrefs();
    }
  }

  static Future<List<Map<String, dynamic>>> _getUsersFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) {
      // Initialize with default admin user
      final defaultUsers = [
        {
          'id': 1,
          'name': 'Admin',
          'email': 'admin@thyne.com',
          'password': 'admin123',
          'phone': '1234567890',
          'createdAt': DateTime.now().toIso8601String(),
          'isAdmin': 1,
        }
      ];
      await _saveUsersToPrefs(defaultUsers);
      return defaultUsers;
    }
    
    final usersList = json.decode(usersJson) as List;
    return usersList.cast<Map<String, dynamic>>();
  }

  static Future<void> _saveUsersToPrefs(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, json.encode(users));
  }

  static Future<Map<String, dynamic>?> getUserByCredentials(String email, String password) async {
    final users = await getUsers();
    try {
      return users.firstWhere(
        (user) => user['email'] == email && user['password'] == password,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final users = await getUsers();
    try {
      return users.firstWhere((user) => user['email'] == email);
    } catch (e) {
      return null;
    }
  }

  static Future<int> createUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final users = await getUsers();
    
    // Check if email already exists
    final existingUser = await getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('Email already exists');
    }
    
    // Generate new ID
    final newId = users.isEmpty ? 1 : (users.map((u) => u['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    
    final newUser = {
      'id': newId,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'createdAt': DateTime.now().toIso8601String(),
      'isAdmin': 0,
      'profileImage': null,
    };
    
    users.add(newUser);
    await _saveUsersToPrefs(users);
    
    return newId;
  }

  static Future<Map<String, dynamic>?> getUserById(int id) async {
    final users = await getUsers();
    try {
      return users.firstWhere((user) => user['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Product management methods
  static Future<List<Map<String, dynamic>>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);
    if (productsJson == null) {
      return [];
    }
    
    final productsList = json.decode(productsJson) as List;
    return productsList.cast<Map<String, dynamic>>();
  }

  static Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final productsData = products.map((product) => {
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'category': product.category,
      'subcategory': product.subcategory,
      'images': product.images.join(','),
      'metalType': product.metalType,
      'stoneType': product.stoneType ?? '',
      'weight': product.weight,
      'tags': product.tags.join(','),
      'rating': product.rating,
      'ratingCount': product.reviewCount,
      'stock': product.stockQuantity,
      'videoUrl': product.videoUrl,
      'createdAt': product.createdAt.toIso8601String(),
    }).toList();
    
    await prefs.setString(_productsKey, json.encode(productsData));
  }

  static Future<void> clearProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_productsKey);
  }

  // Session management
  static Future<void> saveCurrentUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user));
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson == null) return null;
    
    return json.decode(userJson) as Map<String, dynamic>;
  }

  static Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Initialize storage (call this on app startup)
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // For web, just ensure SharedPreferences is ready
        await SharedPreferences.getInstance();
      } else {
        // For mobile/desktop, initialize database
        // This is handled by DatabaseHelper
      }
    } catch (e) {
      debugPrint('Storage initialization error: $e');
    }
  }
}
