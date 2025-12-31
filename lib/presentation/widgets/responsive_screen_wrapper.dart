import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

/// Wrapper that provides responsive layouts for all screens
/// Automatically handles mobile, tablet, and desktop layouts
class ResponsiveScreenWrapper extends StatelessWidget {
  final Widget child;
  final bool centerContent;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool useSafeArea;

  const ResponsiveScreenWrapper({
    super.key,
    required this.child,
    this.centerContent = true,
    this.maxWidth,
    this.padding,
    this.backgroundColor,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Add responsive padding
    content = Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, 16),
            vertical: Responsive.padding(context, 8),
          ),
      child: content,
    );

    // Center content on web with max width constraint
    if (centerContent && !Responsive.isMobile(context)) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? Responsive.maxContentWidth(context),
          ),
          child: content,
        ),
      );
    }

    // Wrap in SafeArea if needed
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    // Add background color if provided
    if (backgroundColor != null) {
      content = Container(
        color: backgroundColor,
        child: content,
      );
    }

    return content;
  }
}

/// Responsive scaffold that includes app bar and proper layout
class ResponsiveScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool centerTitle;
  final bool showAppBar;
  final bool centerContent;
  final double? maxWidth;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.centerTitle = true,
    this.showAppBar = true,
    this.centerContent = true,
    this.maxWidth,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: showAppBar
          ? AppBar(
              title: titleWidget ??
                  (title != null
                      ? Text(
                          title!,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(
                              context,
                              Responsive.isMobile(context) ? 18 : 20,
                            ),
                          ),
                        )
                      : null),
              actions: actions,
              leading: leading,
              centerTitle: centerTitle,
            )
          : null,
      body: ResponsiveScreenWrapper(
        centerContent: centerContent,
        maxWidth: maxWidth,
        backgroundColor: backgroundColor,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Form field wrapper with responsive sizing
class ResponsiveFormField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;

  const ResponsiveFormField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.spacing(context, 8),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        enabled: enabled,
        onTap: onTap,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, 15),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefix,
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              Responsive.spacing(context, 8),
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, 16),
            vertical: Responsive.padding(context, 12),
          ),
        ),
      ),
    );
  }
}

/// Responsive button with proper sizing
class ResponsiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isPrimary;
  final Color? color;
  final double? width;

  const ResponsiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isPrimary = true,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 24),
              vertical: Responsive.padding(context, 14),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.spacing(context, 8),
              ),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: color,
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 24),
              vertical: Responsive.padding(context, 14),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.spacing(context, 8),
              ),
            ),
          );

    Widget buttonContent = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPrimary ? Colors.white : color ?? Colors.blue,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                SizedBox(width: Responsive.spacing(context, 8)),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      child: isPrimary
          ? ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: buttonContent,
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: buttonContent,
            ),
    );
  }
}

/// Responsive grid layout
class ResponsiveGridLayout extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  const ResponsiveGridLayout({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridCount(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: Responsive.spacing(context, spacing),
        mainAxisSpacing: Responsive.spacing(context, runSpacing),
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive column layout (vertical stacking on mobile, horizontal on web)
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      // Stack vertically on mobile
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .map((child) => Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.spacing(context, spacing),
                  ),
                  child: child,
                ))
            .toList(),
      );
    } else {
      // Display horizontally on tablet/desktop
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children
            .map((child) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: Responsive.spacing(context, spacing),
                    ),
                    child: child,
                  ),
                ))
            .toList(),
      );
    }
  }
}

/// Card with responsive sizing and padding
class ResponsiveCardWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;

  const ResponsiveCardWidget({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      margin: margin ??
          EdgeInsets.all(
            Responsive.spacing(context, 8),
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Responsive.spacing(context, 12),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          Responsive.spacing(context, 12),
        ),
        child: Padding(
          padding: padding ??
              EdgeInsets.all(
                Responsive.padding(context, 16),
              ),
          child: child,
        ),
      ),
    );
  }
}
