import 'package:flutter/material.dart';
import '../models/theme_config.dart';
import '../services/api_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeConfig? _activeTheme;
  bool _isLoading = false;

  ThemeConfig? get activeTheme => _activeTheme;
  bool get isLoading => _isLoading;

  // Get theme colors
  Color get primaryColor => _activeTheme?.primaryColorValue ?? const Color(0xFF1B5E20);
  Color get secondaryColor => _activeTheme?.secondaryColorValue ?? const Color(0xFF2E7D32);
  Color get accentColor => _activeTheme?.accentColorValue ?? const Color(0xFF4CAF50);

  ThemeProvider() {
    loadActiveTheme();
  }

  Future<void> loadActiveTheme() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getActiveTheme();
      if (response['success'] == true && response['data'] != null) {
        _activeTheme = ThemeConfig.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading active theme: $e');
      // Use default theme if loading fails
      _activeTheme = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create MaterialApp theme based on active theme
  ThemeData createThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
        ),
      ),
    );
  }

  // Refresh theme (call this after admin changes theme)
  Future<void> refreshTheme() async {
    await loadActiveTheme();
  }
}

