import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/glass_config.dart';
import 'glass_container.dart';
import 'glass_button.dart';

/// iOS-style Glass Dialog with frosted blur effect
class GlassDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? message;
  final Widget? content;
  final List<Widget>? actions;
  final double blur;
  final double width;
  final EdgeInsetsGeometry? contentPadding;

  const GlassDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.message,
    this.content,
    this.actions,
    this.blur = GlassConfig.strongBlur,
    this.width = 320,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassContainer(
        width: width,
        padding: EdgeInsets.zero,
        blur: blur,
        borderRadius: BorderRadius.circular(GlassConfig.largeRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title section
            if (title != null || titleWidget != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: titleWidget ??
                    Text(
                      title!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
              ),
            // Content section
            if (message != null || content != null)
              Padding(
                padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: content ??
                    Text(
                      message!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
              ),
            // Actions
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show glass dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    String? message,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => GlassDialog(
        title: title,
        titleWidget: titleWidget,
        message: message,
        content: content,
        actions: actions,
      ),
    );
  }
}

/// Alert dialog variant (iOS-style)
class GlassAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const GlassAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: title,
      message: message,
      actions: [
        if (cancelText != null)
          GlassSecondaryButton(
            text: cancelText!,
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
          ),
        const SizedBox(width: 8),
        if (confirmText != null)
          GlassPrimaryButton(
            text: confirmText!,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
          ),
      ],
    );
  }

  /// Show alert dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => GlassAlertDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

/// Bottom sheet variant with glass effect
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double blur;
  final double? height;
  final bool showHandle;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.blur = GlassConfig.strongBlur,
    this.height,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glassColors = GlassConfig.getGlassColors(brightness);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GlassConfig.largeRadius),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GlassConfig.largeRadius),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: glassColors.surfaceStrong,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(GlassConfig.largeRadius),
              ),
              border: Border(
                top: BorderSide(
                  color: glassColors.border,
                  width: GlassConfig.borderWidth,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHandle)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: glassColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show glass bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? height,
    bool showHandle = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (context) => GlassBottomSheet(
        height: height,
        showHandle: showHandle,
        child: child,
      ),
    );
  }
}
