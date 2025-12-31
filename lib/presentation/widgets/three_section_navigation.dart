import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/theme_provider.dart';
import '../views/store/store_section.dart';
import '../views/community/community_section.dart';
import '../views/ai/ai_section.dart';

/// New 3-section bottom navigation: Store, Community, AI
class ThreeSectionNavigation extends StatefulWidget {
  const ThreeSectionNavigation({super.key});

  @override
  State<ThreeSectionNavigation> createState() => _ThreeSectionNavigationState();
}

class _ThreeSectionNavigationState extends State<ThreeSectionNavigation> {
  int _currentIndex = 0;

  final List<Widget> _sections = const [
    StoreSection(), // Store section with internal navigation
    CommunitySection(), // Community section with feed, spotlight, profile tabs
    AiSection(), // AI section (to be implemented)
  ];

  void _onNavigationChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _sections,
      ),
      bottomNavigationBar: Container(
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
            currentIndex: _currentIndex,
            onTap: _onNavigationChanged,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: themeProvider.primaryColor,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined, size: 28),
                activeIcon: Icon(Icons.shopping_bag, size: 30),
                label: 'Store',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline, size: 28),
                activeIcon: Icon(Icons.people, size: 30),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined, size: 28),
                activeIcon: Icon(Icons.auto_awesome, size: 30),
                label: 'AI',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
