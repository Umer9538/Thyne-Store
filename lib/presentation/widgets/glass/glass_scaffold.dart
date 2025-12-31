import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../theme/glass_config.dart';
import 'glass_appbar.dart';
import 'glass_bottom_navbar.dart';

/// iOS-style Glass Scaffold with frosted background
/// Provides a consistent glass UI structure for screens
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final String? backgroundImage;
  final Gradient? backgroundGradient;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final double backgroundBlur;
  final bool resizeToAvoidBottomInset;

  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.backgroundImage,
    this.backgroundGradient,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.backgroundBlur = 0,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glassColors = GlassConfig.getGlassColors(brightness);

    // Default background gradient
    final effectiveGradient = backgroundGradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: brightness == Brightness.light
              ? [
                  const Color(0xFFF5F5F5),
                  const Color(0xFFE8E8E8),
                  const Color(0xFFF0F0F0),
                ]
              : [
                  const Color(0xFF000000),
                  const Color(0xFF1A1A1A),
                  const Color(0xFF0D0D0D),
                ],
        );

    Widget background = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: effectiveGradient,
      ),
    );

    // Add background image if provided
    if (backgroundImage != null) {
      background = Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            backgroundImage!,
            fit: BoxFit.cover,
          ),
          if (backgroundBlur > 0)
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: backgroundBlur,
                sigmaY: backgroundBlur,
              ),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          background,
          // Body content
          body,
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

/// Preset glass scaffold with subtle gradient background
class GlassScaffoldLight extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  const GlassScaffoldLight({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFAFAFA),
          Color(0xFFF0F0F0),
          Color(0xFFE8E8E8),
        ],
      ),
    );
  }
}

/// Preset glass scaffold with gold tint
class GlassScaffoldGold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  const GlassScaffoldGold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFAFAFA),
          const Color(0xFFD4AF37).withOpacity(0.05),
          const Color(0xFFFAFAFA),
        ],
      ),
    );
  }
}
