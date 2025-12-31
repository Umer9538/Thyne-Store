import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../theme/glass_config.dart';

/// iOS-style Glass Bottom Navigation Bar with frosted blur effect
class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavBarItem> items;
  final double blur;
  final double height;
  final Color? selectedColor;
  final Color? unselectedColor;
  final bool showLabels;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.blur = GlassConfig.strongBlur,
    this.height = 80,
    this.selectedColor,
    this.unselectedColor,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glassColors = GlassConfig.getGlassColors(brightness);
    final effectiveSelectedColor = selectedColor ?? const Color(0xFFD4AF37);
    final effectiveUnselectedColor = unselectedColor ?? glassColors.border;

    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: glassColors.border,
            width: GlassConfig.borderWidth,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            color: glassColors.surfaceStrong,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    items.length,
                    (index) => _GlassNavBarItemWidget(
                      item: items[index],
                      isSelected: index == currentIndex,
                      onTap: () => onTap(index),
                      selectedColor: effectiveSelectedColor,
                      unselectedColor: effectiveUnselectedColor,
                      showLabel: showLabels,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation bar item model
class GlassNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget? badge;

  const GlassNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
  });
}

/// Individual navigation item widget
class _GlassNavBarItemWidget extends StatefulWidget {
  final GlassNavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final bool showLabel;

  const _GlassNavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    required this.showLabel,
  });

  @override
  State<_GlassNavBarItemWidget> createState() => _GlassNavBarItemWidgetState();
}

class _GlassNavBarItemWidgetState extends State<_GlassNavBarItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: GlassConfig.fastDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? widget.selectedColor : widget.unselectedColor;
    final icon = widget.isSelected && widget.item.activeIcon != null
        ? widget.item.activeIcon!
        : widget.item.icon;

    return Expanded(
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: GlassConfig.normalDuration,
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? widget.selectedColor.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: color,
                      ),
                    ),
                    if (widget.item.badge != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: widget.item.badge!,
                      ),
                  ],
                ),
                if (widget.showLabel) ...[
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: GlassConfig.normalDuration,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                    ),
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge widget for notification counts
class GlassNavBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;

  const GlassNavBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
