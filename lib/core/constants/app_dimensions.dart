import 'package:flutter/material.dart';

/// Centralized dimensions and spacing constants for consistent UI.
///
/// Usage:
/// ```dart
/// Padding(padding: AppDimensions.paddingAll)
/// Container(decoration: BoxDecoration(borderRadius: AppDimensions.borderRadius12))
/// ```
class AppDimensions {
  AppDimensions._(); // Private constructor to prevent instantiation

  // ============== Spacing Values ==============
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;

  // ============== EdgeInsets (Padding/Margin) ==============
  static const EdgeInsets paddingAll4 = EdgeInsets.all(4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24);
  static const EdgeInsets paddingAll32 = EdgeInsets.all(32);

  static const EdgeInsets paddingHorizontal8 = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets paddingHorizontal12 = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets paddingHorizontal16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingHorizontal24 = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets paddingHorizontal32 = EdgeInsets.symmetric(horizontal: 32);

  static const EdgeInsets paddingVertical8 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets paddingVertical12 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets paddingVertical16 = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets paddingVertical24 = EdgeInsets.symmetric(vertical: 24);

  /// Standard screen padding (horizontal: 24, vertical: 16)
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  /// Form field content padding
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  /// Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(horizontal: 32, vertical: 16);

  // ============== Border Radius ==============
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusCircular = 100.0;

  static const BorderRadius borderRadius4 = BorderRadius.all(Radius.circular(4));
  static const BorderRadius borderRadius8 = BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadius12 = BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadius16 = BorderRadius.all(Radius.circular(16));
  static const BorderRadius borderRadius24 = BorderRadius.all(Radius.circular(24));
  static const BorderRadius borderRadiusCircular = BorderRadius.all(Radius.circular(100));

  /// Top corners only border radius
  static const BorderRadius borderRadiusTop16 = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
  );

  /// Bottom corners only border radius
  static const BorderRadius borderRadiusBottom16 = BorderRadius.only(
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );

  // ============== Icon Sizes ==============
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeDefault = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 40.0;
  static const double iconSizeXXLarge = 48.0;

  // ============== Font Sizes ==============
  static const double fontSizeXSmall = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeDefault = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeHeading = 28.0;
  static const double fontSizeDisplay = 32.0;

  // ============== Component Heights ==============
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 56.0;

  static const double inputHeight = 48.0;
  static const double inputHeightSmall = 40.0;
  static const double inputHeightLarge = 56.0;

  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  static const double tabBarHeight = 48.0;

  // ============== Avatar Sizes ==============
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeDefault = 60.0;
  static const double avatarSizeLarge = 80.0;
  static const double avatarSizeXLarge = 100.0;
  static const double avatarSizeXXLarge = 120.0;

  // ============== Card Dimensions ==============
  static const double cardElevation = 2.0;
  static const double cardElevationHover = 4.0;
  static const double cardElevationHigh = 8.0;

  // ============== Image Dimensions ==============
  static const double thumbnailSize = 60.0;
  static const double productImageSmall = 100.0;
  static const double productImageMedium = 150.0;
  static const double productImageLarge = 200.0;
  static const double productImageXLarge = 300.0;

  // ============== Max Widths ==============
  static const double maxWidthMobile = 400.0;
  static const double maxWidthTablet = 600.0;
  static const double maxWidthDesktop = 1200.0;
  static const double maxContentWidth = 800.0;

  // ============== Divider ==============
  static const double dividerThickness = 1.0;
  static const double dividerThicknessBold = 2.0;

  // ============== Stroke Width ==============
  static const double strokeWidthThin = 1.0;
  static const double strokeWidthMedium = 2.0;
  static const double strokeWidthThick = 3.0;

  // ============== Animation Durations ==============
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);

  // ============== Opacity Values ==============
  static const double opacityDisabled = 0.5;
  static const double opacityLight = 0.1;
  static const double opacityMedium = 0.5;
  static const double opacityHeavy = 0.8;

  // ============== SizedBox Widgets ==============
  static const SizedBox verticalSpace4 = SizedBox(height: 4);
  static const SizedBox verticalSpace8 = SizedBox(height: 8);
  static const SizedBox verticalSpace12 = SizedBox(height: 12);
  static const SizedBox verticalSpace16 = SizedBox(height: 16);
  static const SizedBox verticalSpace20 = SizedBox(height: 20);
  static const SizedBox verticalSpace24 = SizedBox(height: 24);
  static const SizedBox verticalSpace32 = SizedBox(height: 32);
  static const SizedBox verticalSpace40 = SizedBox(height: 40);

  static const SizedBox horizontalSpace4 = SizedBox(width: 4);
  static const SizedBox horizontalSpace8 = SizedBox(width: 8);
  static const SizedBox horizontalSpace12 = SizedBox(width: 12);
  static const SizedBox horizontalSpace16 = SizedBox(width: 16);
  static const SizedBox horizontalSpace20 = SizedBox(width: 20);
  static const SizedBox horizontalSpace24 = SizedBox(width: 24);
  static const SizedBox horizontalSpace32 = SizedBox(width: 32);
}
