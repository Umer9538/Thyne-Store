import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../theme/glass_config.dart';

/// iOS-style Glass AppBar with frosted blur effect
/// Replicates iOS navigation bar with translucent background
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double? elevation;
  final Color? backgroundColor;
  final double blur;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final bool showBorder;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation,
    this.backgroundColor,
    this.blur = GlassConfig.softBlur,
    this.centerTitle = true,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
    this.showBorder = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glassColors = GlassConfig.getGlassColors(brightness);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.clamp,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? glassColors.surfaceMedium,
            border: showBorder
                ? Border(
                    bottom: BorderSide(
                      color: glassColors.border,
                      width: GlassConfig.borderWidth,
                    ),
                  )
                : null,
          ),
          child: AppBar(
            title: title,
            leading: leading,
            actions: actions,
            automaticallyImplyLeading: automaticallyImplyLeading,
            centerTitle: centerTitle,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
            systemOverlayStyle: brightness == Brightness.light
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
            bottom: bottom,
            toolbarHeight: toolbarHeight,
          ),
        ),
      ),
    );
  }
}

/// Large title variant (iOS-style large navigation bar)
class GlassLargeAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double blur;
  final bool pinned;
  final bool floating;
  final Widget? flexibleSpace;

  const GlassLargeAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.blur = GlassConfig.softBlur,
    this.pinned = true,
    this.floating = false,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glassColors = GlassConfig.getGlassColors(brightness);

    return SliverAppBar(
      expandedHeight: 120,
      floating: floating,
      pinned: pinned,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: glassColors.surfaceMedium,
              border: Border(
                bottom: BorderSide(
                  color: glassColors.border,
                  width: GlassConfig.borderWidth,
                ),
              ),
            ),
            child: flexibleSpace ??
                FlexibleSpaceBar(
                  title: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  expandedTitleScale: 1.3,
                ),
          ),
        ),
      ),
    );
  }
}
