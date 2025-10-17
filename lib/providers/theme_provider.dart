import 'package:flutter/material.dart';
import '../models/theme_config.dart';
import '../services/api_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeConfig? _activeTheme;
  bool _isLoading = false;

  ThemeConfig? get activeTheme => _activeTheme;
  bool get isLoading => _isLoading;

  // Get theme colors (5 colors)
  Color get primaryColor => _activeTheme?.primaryColorValue ?? const Color(0xFFFFD700);
  Color get secondaryColor => _activeTheme?.secondaryColorValue ?? const Color(0xFFFFA500);
  Color get accentColor => _activeTheme?.accentColorValue ?? const Color(0xFFFF8C00);
  Color get backgroundColor => _activeTheme?.backgroundColorValue ?? const Color(0xFFFFFFFF);
  Color get surfaceColor => _activeTheme?.surfaceColorValue ?? const Color(0xFFF5F5F5);

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

  // Create MaterialApp theme based on active theme with all 5 colors
  ThemeData createThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        background: backgroundColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: BorderSide(color: secondaryColor, width: 1.5),
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
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // Refresh theme (call this after admin changes theme)
  Future<void> refreshTheme() async {
    await loadActiveTheme();
  }
}

