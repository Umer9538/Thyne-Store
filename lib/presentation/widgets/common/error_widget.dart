import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/core.dart';
import 'app_buttons.dart';

/// A widget to display errors with optional retry action.
class AppErrorWidget extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? retryText;
  final VoidCallback? onRetry;
  final double iconSize;
  final Color? iconColor;

  const AppErrorWidget({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.icon = Icons.error_outline,
    this.retryText,
    this.onRetry,
    this.iconSize = 64.0,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = iconColor ?? theme.colorScheme.error;

    return Center(
      child: Padding(
        padding: AppDimensions.paddingAll24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: errorColor,
            ),
            AppDimensions.verticalSpace16,
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppDimensions.verticalSpace8,
              Text(
                message!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              AppDimensions.verticalSpace24,
              AppPrimaryButton(
                text: retryText ?? AppStrings.retry,
                onPressed: onRetry,
                isFullWidth: false,
                width: 150,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pre-built network error widget.
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      icon: Icons.wifi_off,
      title: 'No Internet Connection',
      message: AppStrings.networkError,
      onRetry: onRetry,
    );
  }
}

/// Pre-built server error widget.
class ServerErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ServerErrorWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      icon: Icons.cloud_off,
      title: 'Server Error',
      message: message ?? AppStrings.serviceUnavailable,
      onRetry: onRetry,
    );
  }
}

/// Pre-built timeout error widget.
class TimeoutErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const TimeoutErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      icon: Icons.timer_off,
      title: 'Request Timeout',
      message: 'The request took too long. Please try again.',
      onRetry: onRetry,
    );
  }
}

/// Pre-built generic error widget.
class GenericErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const GenericErrorWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      title: 'Oops!',
      message: message ?? AppStrings.genericError,
      onRetry: onRetry,
    );
  }
}

/// Inline error message widget (for forms, etc.).
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppDimensions.paddingAll12,
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: AppDimensions.borderRadius8,
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.error,
          ),
          AppDimensions.horizontalSpace8,
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Warning message widget.
class WarningWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData icon;
  final VoidCallback? onDismiss;

  const WarningWidget({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.warning_amber,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppDimensions.paddingAll16,
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: AppDimensions.borderRadius8,
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.orange[700],
          ),
          AppDimensions.horizontalSpace12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[800],
                    ),
                  ),
                  AppDimensions.verticalSpace4,
                ],
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              color: Colors.orange[700],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Info message widget.
class InfoWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData icon;
  final VoidCallback? onDismiss;

  const InfoWidget({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_outline,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppDimensions.paddingAll16,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: AppDimensions.borderRadius8,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          AppDimensions.horizontalSpace12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  AppDimensions.verticalSpace4,
                ],
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              color: theme.colorScheme.primary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
