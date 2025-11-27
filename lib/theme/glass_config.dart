import 'package:flutter/material.dart';
import 'dart:ui';

/// iOS-style Glass/Frosted UI Configuration
/// Matches iOS 16-26 design system with translucent materials
class GlassConfig {
  // Blur intensity (sigma values)
  static const double softBlur = 20.0;
  static const double mediumBlur = 30.0;
  static const double strongBlur = 40.0;

  // Opacity levels
  static const double lightOpacity = 0.7;
  static const double mediumOpacity = 0.85;
  static const double strongOpacity = 0.95;

  // Border configurations
  static const double borderWidth = 0.5;
  static const double glowBlur = 8.0;

  // Animation durations
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration slowDuration = Duration(milliseconds: 500);

  // Corner radius
  static const double smallRadius = 12.0;
  static const double mediumRadius = 16.0;
  static const double largeRadius = 24.0;
  static const double extraLargeRadius = 32.0;

  /// Get glass colors based on brightness
  static LightGlass getLightGlass() => LightGlass();
  static DarkGlass getDarkGlass() => DarkGlass();

  static dynamic getGlassColors(Brightness brightness) {
    return brightness == Brightness.light ? getLightGlass() : getDarkGlass();
  }

  /// Create noise texture overlay (iOS-style grain)
  static Widget buildNoiseOverlay({
    double opacity = 0.03,
    BlendMode blendMode = BlendMode.overlay,
  }) {
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: NoisePainter(),
        ),
      ),
    );
  }

  /// Create glass background with blur
  static Widget buildGlassBackground({
    required Widget child,
    double blur = softBlur,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? shadows,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(mediumRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.clamp,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius ?? BorderRadius.circular(mediumRadius),
            border: border,
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Light Mode Glass Colors
class LightGlass {
  // Primary glass backgrounds
  Color get background => Colors.white.withOpacity(0.7);
  Color get surfaceLight => Colors.white.withOpacity(0.5);
  Color get surfaceMedium => Colors.white.withOpacity(0.65);
  Color get surfaceStrong => Colors.white.withOpacity(0.8);

  // Borders and glows
  Color get border => Colors.white.withOpacity(0.3);
  Color get glow => Colors.white.withOpacity(0.1);

  // Overlays
  Color get overlay => Colors.black.withOpacity(0.05);
  Color get shadow => Colors.black.withOpacity(0.1);

  // Tinted glass (for brand colors)
  Color get goldTint => const Color(0xFFD4AF37).withOpacity(0.15);
  Color get roseTint => const Color(0xFFE8C4C4).withOpacity(0.15);
  Color get purpleTint => const Color(0xFF9B7EBD).withOpacity(0.15);
}

/// Dark Mode Glass Colors
class DarkGlass {
  // Primary glass backgrounds
  Color get background => Colors.black.withOpacity(0.6);
  Color get surfaceLight => const Color(0xFF1C1C1E).withOpacity(0.7);
  Color get surfaceMedium => const Color(0xFF1C1C1E).withOpacity(0.8);
  Color get surfaceStrong => const Color(0xFF1C1C1E).withOpacity(0.9);

  // Borders and glows
  Color get border => Colors.white.withOpacity(0.15);
  Color get glow => Colors.white.withOpacity(0.05);

  // Overlays
  Color get overlay => Colors.white.withOpacity(0.05);
  Color get shadow => Colors.black.withOpacity(0.3);

  // Tinted glass (for brand colors)
  Color get goldTint => const Color(0xFFD4AF37).withOpacity(0.2);
  Color get roseTint => const Color(0xFFE8C4C4).withOpacity(0.2);
  Color get purpleTint => const Color(0xFF9B7EBD).withOpacity(0.2);
}

/// Custom painter for noise texture overlay
class NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Create a simple noise pattern
    for (var i = 0; i < 500; i++) {
      final x = (i * 37.0) % size.width;
      final y = (i * 73.0) % size.height;
      final opacity = ((i * 13) % 100) / 200.0;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(NoisePainter oldDelegate) => false;
}
