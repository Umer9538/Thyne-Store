import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThyneTheme {
  // Module Colors (matching Figma design)
  static const Color commerceGreen = Color(0xFF094010); // Emerald
  static const Color communityRuby = Color(0xFF401010); // Ruby
  static const Color createBlue = Color(0xFF0a1a40); // Blue Sapphire

  // Base Colors
  static const Color background = Color(0xFFfafafa); // Light gray background (changed from cream)
  static const Color creamBackground = Color(0xFFfffff0); // Cream for special sections
  static const Color foreground = Color(0xFF1a1a1a); // Dark gray/black for text
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFe5e5e5); // More visible border

  // Semantic Colors
  static const Color primary = Color(0xFF1a1a1a); // Dark for primary elements
  static const Color secondary = Color(0xFFf5f5f5);
  static const Color muted = Color(0xFFf5f5f5);
  static const Color mutedForeground = Color(0xFF666666); // Darker muted text
  static const Color destructive = Color(0xFFef4444);
  static const Color primaryRed = Color(0xFFdc2626); // Red for errors/warnings
  static const Color primaryGold = Color(0xFFd4af37); // Gold accent color

  // Typography Scale (matching Figma)
  static const double textDisplay = 40.0; // 2.5rem
  static const double textHeadingLg = 28.0; // 1.75rem
  static const double textHeadingMd = 22.0; // 1.375rem
  static const double textHeadingSm = 18.0; // 1.125rem
  static const double textBody = 15.0; // 0.9375rem
  static const double textBodySm = 13.0; // 0.8125rem
  static const double textFootnote = 11.0; // 0.6875rem

  // Letter Spacing
  static const double trackingTight = -0.02;
  static const double trackingNormal = 0;
  static const double trackingWide = 0.02;
  static const double trackingWider = 0.05;

  // Get module color based on current section
  static Color getModuleColor(String module) {
    switch (module) {
      case 'commerce':
        return commerceGreen;
      case 'community':
        return communityRuby;
      case 'create':
        return createBlue;
      default:
        return primary;
    }
  }

  // Get glow color for module
  static Color getModuleGlowColor(String module, {double opacity = 0.3}) {
    return getModuleColor(module).withOpacity(opacity);
  }

  // Light Theme (only theme as per design)
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: cardBackground,
        background: background,
        error: destructive,
        onPrimary: Colors.white,
        onSecondary: foreground,
        onSurface: foreground,
        onBackground: foreground,
        onError: Colors.white,
      ),

      // Background Colors
      scaffoldBackgroundColor: background,
      cardColor: cardBackground,
      dialogBackgroundColor: cardBackground,

      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: textDisplay,
          fontWeight: FontWeight.w600,
          letterSpacing: trackingTight,
          color: foreground,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: textHeadingLg,
          fontWeight: FontWeight.w600,
          letterSpacing: trackingTight,
          color: foreground,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: textHeadingMd,
          fontWeight: FontWeight.w500,
          letterSpacing: trackingNormal,
          color: foreground,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: textHeadingLg,
          fontWeight: FontWeight.w600,
          letterSpacing: trackingTight,
          color: foreground,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: textHeadingMd,
          fontWeight: FontWeight.w500,
          letterSpacing: trackingNormal,
          color: foreground,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: textHeadingSm,
          fontWeight: FontWeight.w500,
          letterSpacing: trackingNormal,
          color: foreground,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: textHeadingMd,
          fontWeight: FontWeight.w500,
          letterSpacing: trackingNormal,
          color: foreground,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: textHeadingSm,
          fontWeight: FontWeight.w500,
          letterSpacing: trackingNormal,
          color: foreground,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: textBody,
          fontWeight: FontWeight.w500,
          letterSpacing: trackingNormal,
          color: foreground,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: textBody,
          fontWeight: FontWeight.w400,
          letterSpacing: trackingNormal,
          color: foreground,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: textBodySm,
          fontWeight: FontWeight.w400,
          letterSpacing: trackingNormal,
          color: foreground,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: textFootnote,
          fontWeight: FontWeight.w400,
          letterSpacing: trackingNormal,
          color: mutedForeground,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: textBodySm,
          fontWeight: FontWeight.w500,
          letterSpacing: trackingWide,
          color: foreground,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: textFootnote,
          fontWeight: FontWeight.w500,
          letterSpacing: trackingWide,
          color: foreground,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10.0,
          fontWeight: FontWeight.w500,
          letterSpacing: trackingWider,
          color: mutedForeground,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: background.withOpacity(0.8),
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: textHeadingSm,
          fontWeight: FontWeight.w600,
          letterSpacing: trackingNormal,
          color: foreground,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: mutedForeground,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: textBody,
            fontWeight: FontWeight.w500,
            letterSpacing: trackingNormal,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: textBody,
            fontWeight: FontWeight.w500,
            letterSpacing: trackingNormal,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: textBody,
            fontWeight: FontWeight.w500,
            letterSpacing: trackingNormal,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: destructive),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: textBody,
          fontWeight: FontWeight.w400,
          letterSpacing: trackingNormal,
          color: mutedForeground,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: textBody,
          fontWeight: FontWeight.w400,
          letterSpacing: trackingNormal,
          color: mutedForeground.withOpacity(0.7),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: secondary,
        selectedColor: primary,
        disabledColor: muted,
        labelStyle: GoogleFonts.inter(
          fontSize: textBodySm,
          fontWeight: FontWeight.w500,
          letterSpacing: trackingNormal,
          color: foreground,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Glass Morphism Container Decoration
  static BoxDecoration glassDecoration({
    Color? color,
    double borderRadius = 12,
    bool withBorder = true,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(0.8),
      borderRadius: BorderRadius.circular(borderRadius),
      border: withBorder ? Border.all(color: border, width: 1) : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Module Glow Decoration
  static BoxDecoration moduleGlowDecoration({
    required String module,
    double borderRadius = 20,
  }) {
    final color = getModuleColor(module);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
}