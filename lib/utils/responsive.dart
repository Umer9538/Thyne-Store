import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650;

  // Get responsive value based on screen size
  static T valueByDevice<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  // Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Responsive font size
  static double fontSize(BuildContext context, double size) {
    if (isMobile(context)) {
      return size;
    } else if (isTablet(context)) {
      return size * 1.1;
    } else {
      return size * 1.2;
    }
  }

  // Responsive padding
  static double padding(BuildContext context, double size) {
    if (isMobile(context)) {
      return size;
    } else if (isTablet(context)) {
      return size * 1.2;
    } else {
      return size * 1.5;
    }
  }

  // Grid count based on screen size
  static int gridCount(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Max width for content (useful for web)
  static double maxContentWidth(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: double.infinity,
      tablet: 768,
      desktop: 1200,
    );
  }

  // Responsive spacing
  static double spacing(BuildContext context, double baseSpacing) {
    return valueByDevice(
      context: context,
      mobile: baseSpacing,
      tablet: baseSpacing * 1.25,
      desktop: baseSpacing * 1.5,
    );
  }

  // Check orientation
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  // Responsive image/card height based on screen size
  // Returns a height that scales with the device but has min/max bounds
  static double imageHeight(BuildContext context, {
    double mobileHeight = 250,
    double tabletHeight = 300,
    double desktopHeight = 350,
  }) {
    final screenH = screenHeight(context);

    // Use percentage of screen height with device-specific bounds
    if (isMobile(context)) {
      // On mobile, use ~35% of screen height, bounded between 200-350
      return (screenH * 0.35).clamp(200.0, mobileHeight + 50);
    } else if (isTablet(context)) {
      return tabletHeight;
    } else {
      return desktopHeight;
    }
  }

  // Responsive card height for community posts, showcases etc.
  static double cardHeight(BuildContext context) {
    final screenH = screenHeight(context);
    // Use ~30% of screen height, with min 200 and max 400
    return (screenH * 0.30).clamp(200.0, 400.0);
  }

  // Get safe bottom padding (for devices with bottom notch/home indicator)
  static double safeBottomPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // Get safe top padding (for devices with notch/status bar)
  static double safeTopPadding(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
}

// Responsive breakpoints
class ScreenBreakpoints {
  static const double mobile = 650;
  static const double tablet = 1100;
  static const double desktop = 1920;
}

// Extension for easier access
extension ResponsiveExtension on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isWeb => Responsive.isWeb(this);

  double get screenWidth => Responsive.screenWidth(this);
  double get screenHeight => Responsive.screenHeight(this);

  double responsiveFontSize(double size) => Responsive.fontSize(this, size);
  double responsivePadding(double size) => Responsive.padding(this, size);
  double responsiveSpacing(double size) => Responsive.spacing(this, size);

  // Responsive heights for images and cards
  double get responsiveCardHeight => Responsive.cardHeight(this);
  double responsiveImageHeight({double mobile = 250, double tablet = 300, double desktop = 350}) =>
      Responsive.imageHeight(this, mobileHeight: mobile, tabletHeight: tablet, desktopHeight: desktop);

  // Safe area paddings
  double get safeBottomPadding => Responsive.safeBottomPadding(this);
  double get safeTopPadding => Responsive.safeTopPadding(this);
}
