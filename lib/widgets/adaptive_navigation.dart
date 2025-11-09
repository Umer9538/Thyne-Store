import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';

/// Adaptive navigation that switches between mobile bottom nav and web sidebar
class AdaptiveNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigationChanged;
  final Widget child;

  const AdaptiveNavigation({
    super.key,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      // Mobile: Bottom navigation
      return _MobileNavigation(
        currentIndex: currentIndex,
        onNavigationChanged: onNavigationChanged,
        child: child,
      );
    } else {
      // Web/Tablet: Side navigation
      return _WebNavigation(
        currentIndex: currentIndex,
        onNavigationChanged: onNavigationChanged,
        child: child,
      );
    }
  }
}

/// Mobile navigation with bottom nav bar
class _MobileNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigationChanged;
  final Widget child;

  const _MobileNavigation({
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onNavigationChanged,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: themeProvider.primaryColor,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 24),
                activeIcon: Icon(Icons.home, size: 26),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined, size: 24),
                activeIcon: Icon(Icons.grid_view, size: 26),
                label: 'Products',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined, size: 24),
                activeIcon: Icon(Icons.search, size: 26),
                label: 'Search',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_outline, size: 24),
                activeIcon: Icon(Icons.people, size: 26),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: badges.Badge(
                  badgeContent: Text(
                    cartProvider.itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  showBadge: cartProvider.itemCount > 0,
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: themeProvider.accentColor,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 24),
                ),
                activeIcon: badges.Badge(
                  badgeContent: Text(
                    cartProvider.itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  showBadge: cartProvider.itemCount > 0,
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: themeProvider.accentColor,
                  ),
                  child: const Icon(Icons.shopping_bag, size: 26),
                ),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 24),
                activeIcon: Icon(Icons.person, size: 26),
                label: 'Profile',
              ),
            ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Web navigation with side rail/drawer
class _WebNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onNavigationChanged;
  final Widget child;

  const _WebNavigation({
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.child,
  });

  @override
  State<_WebNavigation> createState() => _WebNavigationState();
}

class _WebNavigationState extends State<_WebNavigation> {
  bool _isExpanded = true; // Sidebar is expanded by default

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDesktop = Responsive.isDesktop(context);

    return Row(
      children: [
        // Side Navigation Rail
        AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: _isExpanded ? (isDesktop ? 250 : 80) : 60,
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Logo/Brand with Collapse Button
                  Padding(
                    padding: EdgeInsets.all(_isExpanded ? (isDesktop ? 16 : 12) : 12),
                    child: _isExpanded
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.diamond,
                                      color: themeProvider.primaryColor,
                                      size: isDesktop ? 28 : 24,
                                    ),
                                    if (isDesktop) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Thyne Jewels',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: themeProvider.primaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.menu_open,
                                  color: themeProvider.primaryColor,
                                  size: 20,
                                ),
                                onPressed: _toggleSidebar,
                                tooltip: 'Collapse sidebar',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: IconButton(
                              icon: Icon(
                                Icons.menu,
                                color: themeProvider.primaryColor,
                                size: 20,
                              ),
                              onPressed: _toggleSidebar,
                              tooltip: 'Expand sidebar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Navigation Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _buildNavItem(
                          context,
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home,
                          label: 'Home',
                          index: 0,
                          isDesktop: isDesktop,
                          isExpanded: _isExpanded,
                          isSelected: widget.currentIndex == 0,
                          onTap: () => widget.onNavigationChanged(0),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.grid_view_outlined,
                          selectedIcon: Icons.grid_view,
                          label: 'Products',
                          index: 1,
                          isDesktop: isDesktop,
                          isExpanded: _isExpanded,
                          isSelected: widget.currentIndex == 1,
                          onTap: () => widget.onNavigationChanged(1),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.search_outlined,
                          selectedIcon: Icons.search,
                          label: 'Search',
                          index: 2,
                          isDesktop: isDesktop,
                          isExpanded: _isExpanded,
                          isSelected: widget.currentIndex == 2,
                          onTap: () => widget.onNavigationChanged(2),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.people_outline,
                          selectedIcon: Icons.people,
                          label: 'Community',
                          index: 3,
                          isDesktop: isDesktop,
                          isExpanded: _isExpanded,
                          isSelected: widget.currentIndex == 3,
                          onTap: () => widget.onNavigationChanged(3),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.shopping_bag_outlined,
                          selectedIcon: Icons.shopping_bag,
                          label: 'Cart',
                          index: 4,
                          isDesktop: isDesktop,
                          isExpanded: _isExpanded,
                          isSelected: widget.currentIndex == 4,
                          badge: cartProvider.itemCount > 0
                              ? cartProvider.itemCount.toString()
                              : null,
                          onTap: () => widget.onNavigationChanged(4),
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.person_outline,
                          selectedIcon: Icons.person,
                          label: 'Profile',
                          index: 5,
                          isDesktop: isDesktop,
                          isExpanded: _isExpanded,
                          isSelected: widget.currentIndex == 5,
                          onTap: () => widget.onNavigationChanged(5),
                        ),
                      ],
                    ),
                  ),

                  // Bottom section
                  if (_isExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.all(isDesktop ? 16 : 12),
                      child: _buildThemeIndicator(context, isDesktop),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: widget.child,
          ),
        ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isDesktop,
    required bool isExpanded,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected
            ? themeProvider.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? (isDesktop ? 16 : 12) : 8,
              vertical: 14,
            ),
            child: Row(
              mainAxisAlignment: (isDesktop && isExpanded) ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isSelected ? selectedIcon : icon,
                      color: isSelected
                          ? themeProvider.primaryColor
                          : Colors.grey[600],
                      size: 24,
                    ),
                    if (badge != null)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: themeProvider.accentColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                if (isDesktop && isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? themeProvider.primaryColor
                            : Colors.grey[700],
                      ),
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

  Widget _buildThemeIndicator(BuildContext context, bool isDesktop) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeName = themeProvider.activeTheme?.name ?? 'Default';

    if (!isDesktop) {
      // Compact view for tablet
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: themeProvider.primaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.palette,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.primaryColor.withOpacity(0.1),
            themeProvider.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.palette,
            color: themeProvider.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Active Theme',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  themeName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
