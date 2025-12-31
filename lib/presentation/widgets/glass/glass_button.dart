import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../theme/glass_config.dart';
import 'glass_container.dart';

/// iOS-style Glass Button with frosted effect and haptic feedback
class GlassButton extends StatefulWidget {
  final Widget? child;
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final Color? color;
  final Color? tintColor;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final bool isLoading;
  final bool enabled;

  const GlassButton({
    super.key,
    this.child,
    this.text,
    this.icon,
    required this.onPressed,
    this.width,
    this.height,
    this.padding,
    this.blur = GlassConfig.softBlur,
    this.color,
    this.tintColor,
    this.borderRadius,
    this.showBorder = true,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: GlassConfig.fastDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glassColors = GlassConfig.getGlassColors(brightness);
    final isDisabled = !widget.enabled || widget.isLoading;

    Widget content;
    if (widget.child != null) {
      content = widget.child!;
    } else {
      final List<Widget> children = [];
      if (widget.icon != null) {
        children.add(Icon(widget.icon, size: 20));
      }
      if (widget.text != null) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(width: 8));
        }
        children.add(
          Text(
            widget.text!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }

    if (widget.isLoading) {
      content = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedOpacity(
            opacity: isDisabled ? 0.5 : 1.0,
            duration: GlassConfig.fastDuration,
            child: GlassContainer(
              width: widget.width,
              height: widget.height ?? 50,
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              blur: widget.blur,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(GlassConfig.mediumRadius),
              showBorder: widget.showBorder,
              color: widget.color,
              tintColor: widget.tintColor,
              showGlow: _isPressed,
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary button variant (with gold tint)
class GlassPrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final double? width;

  const GlassPrimaryButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      enabled: enabled,
      width: width,
      tintColor: const Color(0xFFD4AF37),
      blur: GlassConfig.mediumBlur,
    );
  }
}

/// Secondary button variant (subtle glass)
class GlassSecondaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final double? width;

  const GlassSecondaryButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      enabled: enabled,
      width: width,
      blur: GlassConfig.softBlur,
    );
  }
}

/// Icon button variant
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? tintColor;
  final bool enabled;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.tintColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onPressed: onPressed,
      enabled: enabled,
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      tintColor: tintColor,
      borderRadius: BorderRadius.circular(size / 2),
      child: Icon(icon, size: size * 0.5),
    );
  }
}
