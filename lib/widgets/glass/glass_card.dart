import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/glass_config.dart';
import 'glass_container.dart';

/// iOS-style Glass Card with frosted effect
/// Perfect for content cards, product cards, info panels
class GlassCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final double blur;
  final double elevation;
  final BorderRadius? borderRadius;
  final Color? tintColor;
  final bool showBorder;
  final bool showGlow;

  const GlassCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.blur = GlassConfig.softBlur,
    this.elevation = 2,
    this.borderRadius,
    this.tintColor,
    this.showBorder = true,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glassColors = GlassConfig.getGlassColors(brightness);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(GlassConfig.mediumRadius);

    final card = GlassContainer(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      blur: blur,
      borderRadius: effectiveRadius,
      showBorder: showBorder,
      showGlow: showGlow,
      tintColor: tintColor,
      boxShadow: [
        BoxShadow(
          color: glassColors.shadow.withOpacity(elevation * 0.05),
          blurRadius: elevation * 5,
          offset: Offset(0, elevation * 2),
        ),
      ],
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: glassColors.overlay,
          highlightColor: glassColors.overlay.withOpacity(0.5),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Product Card variant with glass effect
class GlassProductCard extends StatelessWidget {
  final Widget? image;
  final String? title;
  final String? subtitle;
  final String? price;
  final VoidCallback? onTap;
  final Widget? badge;
  final bool isFavorite;
  final VoidCallback? onFavoritePressed;

  const GlassProductCard({
    super.key,
    this.image,
    this.title,
    this.subtitle,
    this.price,
    this.onTap,
    this.badge,
    this.isFavorite = false,
    this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glassColors = GlassConfig.getGlassColors(brightness);

    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          if (image != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(GlassConfig.mediumRadius),
                  ),
                  child: image!,
                ),
                // Badges
                if (badge != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: badge!,
                  ),
                // Favorite button
                if (onFavoritePressed != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(8),
                      blur: GlassConfig.mediumBlur,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: onFavoritePressed,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite ? Colors.red : glassColors.border,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (price != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    price!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD4AF37),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
