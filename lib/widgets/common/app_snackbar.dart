import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/core.dart';

/// Type of snackbar notification.
enum SnackbarType {
  success,
  error,
  warning,
  info,
}

/// Helper class for showing consistent snackbars throughout the app.
class AppSnackbar {
  AppSnackbar._();

  /// Show a success snackbar.
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      type: SnackbarType.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Show an error snackbar.
  static void showError(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      type: SnackbarType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Show a warning snackbar.
  static void showWarning(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      type: SnackbarType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Show an info snackbar.
  static void showInfo(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      type: SnackbarType.info,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Show a generic snackbar with customization.
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Hide the current snackbar.
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static void _show(
    BuildContext context, {
    required String message,
    required SnackbarType type,
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
  }) {
    final snackbarConfig = _getSnackbarConfig(type);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              snackbarConfig.icon,
              color: Colors.white,
              size: 20,
            ),
            AppDimensions.horizontalSpace12,
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: snackbarConfig.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadius8,
        ),
        margin: AppDimensions.paddingAll16,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static _SnackbarConfig _getSnackbarConfig(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarConfig(
          icon: Icons.check_circle,
          backgroundColor: Colors.green[600]!,
        );
      case SnackbarType.error:
        return _SnackbarConfig(
          icon: Icons.error,
          backgroundColor: Colors.red[600]!,
        );
      case SnackbarType.warning:
        return _SnackbarConfig(
          icon: Icons.warning,
          backgroundColor: Colors.orange[600]!,
        );
      case SnackbarType.info:
        return _SnackbarConfig(
          icon: Icons.info,
          backgroundColor: Colors.blue[600]!,
        );
    }
  }
}

class _SnackbarConfig {
  final IconData icon;
  final Color backgroundColor;

  _SnackbarConfig({
    required this.icon,
    required this.backgroundColor,
  });
}

/// Extension methods for showing snackbars easily.
extension SnackbarExtension on BuildContext {
  void showSuccessSnackbar(String message, {VoidCallback? onAction, String? actionLabel}) {
    AppSnackbar.showSuccess(this, message: message, onAction: onAction, actionLabel: actionLabel);
  }

  void showErrorSnackbar(String message, {VoidCallback? onAction, String? actionLabel}) {
    AppSnackbar.showError(this, message: message, onAction: onAction, actionLabel: actionLabel);
  }

  void showWarningSnackbar(String message, {VoidCallback? onAction, String? actionLabel}) {
    AppSnackbar.showWarning(this, message: message, onAction: onAction, actionLabel: actionLabel);
  }

  void showInfoSnackbar(String message, {VoidCallback? onAction, String? actionLabel}) {
    AppSnackbar.showInfo(this, message: message, onAction: onAction, actionLabel: actionLabel);
  }

  void hideSnackbar() {
    AppSnackbar.hide(this);
  }
}

/// Helper class for showing confirmation dialogs.
class AppDialog {
  AppDialog._();

  /// Show a confirmation dialog.
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadius12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: GoogleFonts.inter(
                color: confirmColor ?? (isDangerous ? Colors.red : null),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show an alert dialog.
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadius12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              buttonText,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a loading dialog.
  static void showLoading(
    BuildContext context, {
    String message = 'Please wait...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadius12,
          ),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              AppDimensions.horizontalSpace24,
              Text(
                message,
                style: GoogleFonts.inter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hide the loading dialog.
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show a bottom sheet.
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor ?? Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => child,
    );
  }
}
