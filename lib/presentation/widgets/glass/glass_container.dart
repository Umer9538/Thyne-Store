import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../theme/glass_config.dart';

/// iOS-style Glass Container with frosted blur effect
/// Replicates the translucent material design from iOS 16-26
class GlassContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool showBorder;
  final bool showNoise;
  final bool showGlow;
  final Color? color;
  final Color? tintColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry? alignment;

  const GlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.blur = GlassConfig.softBlur,
    this.opacity = GlassConfig.lightOpacity,
    this.borderRadius,
    this.border,
    this.showBorder = true,
    this.showNoise = true,
    this.showGlow = false,
    this.color,
    this.tintColor,
    this.gradient,
    this.boxShadow,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glassColors = GlassConfig.getGlassColors(brightness);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(GlassConfig.mediumRadius);

    // Default glass color based on theme
    final baseColor = color ?? glassColors.surfaceMedium;

    // Build border with glow effect
    final effectiveBorder = showBorder
        ? border ??
            Border.all(
              color: glassColors.border,
              width: GlassConfig.borderWidth,
            )
        : null;

    // Build box shadow
    final effectiveShadow = boxShadow ??
        [
          BoxShadow(
            color: glassColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (showGlow)
            BoxShadow(
              color: (tintColor ?? Colors.white).withOpacity(0.1),
              blurRadius: GlassConfig.glowBlur,
              spreadRadius: 2,
            ),
        ];

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            alignment: alignment,
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor,
              gradient: gradient ??
                  (tintColor != null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            baseColor,
                            tintColor!.withOpacity(opacity * 0.3),
                          ],
                        )
                      : null),
              borderRadius: effectiveBorderRadius,
              border: effectiveBorder,
              boxShadow: effectiveShadow,
            ),
            child: Stack(
              children: [
                // Noise texture overlay
                if (showNoise) GlassConfig.buildNoiseOverlay(),
                // Content
                if (child != null) child!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Preset glass container variants for common use cases
class GlassContainerVariants {
  /// Light translucent container
  static GlassContainer light({
    Widget? child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return GlassContainer(
      blur: GlassConfig.softBlur,
      opacity: 0.5,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Medium opacity container
  static GlassContainer medium({
    Widget? child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return GlassContainer(
      blur: GlassConfig.mediumBlur,
      opacity: 0.7,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Strong/prominent container
  static GlassContainer strong({
    Widget? child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return GlassContainer(
      blur: GlassConfig.strongBlur,
      opacity: 0.9,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Gold tinted container
  static GlassContainer goldTint({
    Widget? child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return GlassContainer(
      blur: GlassConfig.mediumBlur,
      opacity: 0.7,
      tintColor: const Color(0xFFD4AF37),
      showGlow: true,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Rose gold tinted container
  static GlassContainer roseTint({
    Widget? child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return GlassContainer(
      blur: GlassConfig.mediumBlur,
      opacity: 0.7,
      tintColor: const Color(0xFFE8C4C4),
      showGlow: true,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }
}
