import 'package:flutter/material.dart';
import '../screens/home/unified_home_container.dart';
import '../screens/product/product_list_screen.dart';
import '../screens/search/enhanced_search_screen.dart';
import '../screens/community/community_feed_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'adaptive_navigation.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    UnifiedHomeContainer(),
    ProductListScreen(),
    EnhancedSearchScreen(),
    CommunityFeedScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  void _onNavigationChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      currentIndex: _currentIndex,
      onNavigationChanged: _onNavigationChanged,
      child: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}