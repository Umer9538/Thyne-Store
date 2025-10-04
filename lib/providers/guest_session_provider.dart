import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/guest_user.dart';
import '../models/user.dart';

class GuestSessionProvider extends ChangeNotifier {
  GuestUser? _guestUser;
  bool _isGuestMode = false;

  GuestUser? get guestUser => _guestUser;
  bool get isGuestMode => _isGuestMode;
  bool get isActive => _guestUser != null;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _guestSessionKey = 'guest_session';
  static const String _guestModeKey = 'guest_mode';

  GuestSessionProvider() {
    _loadGuestSession();
  }

  /// Initialize guest session
  Future<void> startGuestSession() async {
    _guestUser = GuestUser.create();
    _isGuestMode = true;
    await _saveGuestSession();
    notifyListeners();
  }

  /// Update guest user information during checkout
  Future<void> updateGuestInfo({
    String? email,
    String? phone,
    String? name,
  }) async {
    if (_guestUser == null) return;

    _guestUser = _guestUser!.copyWith(
      email: email,
      phone: phone,
      name: name,
      lastActivity: DateTime.now(),
    );
    await _saveGuestSession();
    notifyListeners();
  }

  /// Update last activity timestamp
  Future<void> updateActivity() async {
    if (_guestUser == null) return;

    _guestUser = _guestUser!.copyWith(
      lastActivity: DateTime.now(),
    );
    await _saveGuestSession();
    notifyListeners();
  }

  /// Convert guest session to registered user
  Future<void> convertToUser(User user) async {
    // Clear guest session when user registers/logs in
    await clearGuestSession();
  }

  /// Clear guest session
  Future<void> clearGuestSession() async {
    _guestUser = null;
    _isGuestMode = false;

    await _storage.delete(key: _guestSessionKey);
    await _storage.delete(key: _guestModeKey);

    notifyListeners();
  }

  /// Check if guest session is expired (older than 30 days)
  bool isSessionExpired() {
    if (_guestUser == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_guestUser!.lastActivity);
    return difference.inDays > 30;
  }

  /// Get display name for guest user
  String getDisplayName() {
    if (_guestUser == null) return 'Guest User';

    if (_guestUser!.hasName) {
      return _guestUser!.name!;
    } else if (_guestUser!.email != null) {
      return _guestUser!.email!.split('@')[0];
    } else if (_guestUser!.phone != null) {
      return 'Guest (${_guestUser!.phone!.substring(0, 4)}...)';
    }

    return 'Guest User';
  }

  /// Save guest session to secure storage
  Future<void> _saveGuestSession() async {
    if (_guestUser == null) return;

    await _storage.write(key: _guestSessionKey, value: jsonEncode(_guestUser!.toJson()));
    await _storage.write(key: _guestModeKey, value: _isGuestMode.toString());
  }

  /// Load guest session from secure storage
  Future<void> _loadGuestSession() async {
    try {
      final guestData = await _storage.read(key: _guestSessionKey);
      final guestModeStr = await _storage.read(key: _guestModeKey);
      final guestMode = guestModeStr == 'true';

      if (guestData != null) {
        final guestJson = jsonDecode(guestData);
        final loadedGuest = GuestUser.fromJson(guestJson);

        // Check if session is expired
        if (!_isSessionExpired(loadedGuest)) {
          _guestUser = loadedGuest;
          _isGuestMode = guestMode;
          notifyListeners();
        } else {
          // Clear expired session
          await _storage.delete(key: _guestSessionKey);
          await _storage.delete(key: _guestModeKey);
        }
      }
    } catch (e) {
      debugPrint('Error loading guest session: $e');
    }
  }

  /// Helper method to check if a guest session is expired
  bool _isSessionExpired(GuestUser guest) {
    final now = DateTime.now();
    final difference = now.difference(guest.lastActivity);
    return difference.inDays > 30;
  }

  /// Enable guest mode (browse without session)
  void enableGuestMode() {
    _isGuestMode = true;
    notifyListeners();
  }

  /// Check if user should be prompted to login
  bool shouldPromptLogin() {
    return _isGuestMode && (_guestUser == null || !_guestUser!.hasContactInfo);
  }

  /// Get session info for debugging
  Map<String, dynamic> getSessionInfo() {
    return {
      'isGuestMode': _isGuestMode,
      'hasGuestUser': _guestUser != null,
      'sessionId': _guestUser?.sessionId,
      'hasContactInfo': _guestUser?.hasContactInfo ?? false,
      'displayName': getDisplayName(),
      'lastActivity': _guestUser?.lastActivity.toIso8601String(),
    };
  }
}