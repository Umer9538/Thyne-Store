import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _currentUserKey = 'current_user';

  // Session management - only keep secure token storage
  static Future<void> saveCurrentUser(Map<String, dynamic> user) async {
    await _storage.write(key: _currentUserKey, value: json.encode(user));
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final userJson = await _storage.read(key: _currentUserKey);
    if (userJson == null) return null;
    
    return json.decode(userJson) as Map<String, dynamic>;
  }

  static Future<void> clearCurrentUser() async {
    await _storage.delete(key: _currentUserKey);
  }

  // Initialize storage (call this on app startup)
  static Future<void> initialize() async {
    try {
      // Just ensure secure storage is ready - no local database initialization needed
      debugPrint('Storage service initialized - using MongoDB only');
    } catch (e) {
      debugPrint('Storage initialization error: $e');
    }
  }
}