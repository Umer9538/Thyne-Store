import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/cart_provider.dart';
import '../../viewmodels/wishlist_provider.dart';
import '../../../utils/theme.dart';
import 'redesigned_home_screen.dart';
import '../search/enhanced_search_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';

/// Store Section - Contains internal navigation for Home, Search, Cart, Profile
class StoreSection extends StatefulWidget {
  const StoreSection({super.key});

  @override
  State<StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends State<StoreSection> {
  int _currentPage = 0;

  final List<Widget> _pages = const [
    RedesignedHomeScreen(),
    EnhancedSearchScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _currentPage,
            children: _pages,
          ),

          // Floating Action Button + Search Bar overlay (only on home page)
          if (_currentPage == 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // FAB Button
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white, size: 28),
                        onPressed: () {
                          // TODO: Open AI chat
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('AI Assistant coming soon!')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Search Bar
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onPageChanged(1), // Navigate to search
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 20),
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'ask me anything',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.mic, color: Colors.grey),
                                onPressed: () {
                                  // TODO: Voice search
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // Internal top navigation bar (icons for quick access)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
