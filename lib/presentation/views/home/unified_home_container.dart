import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../viewmodels/cart_provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/guest_session_provider.dart';
import '../../viewmodels/wishlist_provider.dart';
import '../../../utils/theme.dart';
import '../search/search_screen.dart';
import 'dynamic_home_screen.dart';
import '../product/product_list_screen.dart';

enum ContentType {
  home,
  categoryProducts,
  allProducts,
  search,
}

class UnifiedHomeContainer extends StatefulWidget {
  const UnifiedHomeContainer({super.key});

  @override
  State<UnifiedHomeContainer> createState() => UnifiedHomeContainerState();
}

class UnifiedHomeContainerState extends State<UnifiedHomeContainer> {
  ContentType _currentContent = ContentType.home;
  String? _selectedCategory;

  // Navigation to different content
  void _showCategoryProducts(String category) {
    setState(() {
      _currentContent = ContentType.categoryProducts;
      _selectedCategory = category;
    });
  }

  void _showAllProducts() {
    setState(() {
      _currentContent = ContentType.allProducts;
      _selectedCategory = null;
    });
  }

  void _showHome() {
    setState(() {
      _currentContent = ContentType.home;
      _selectedCategory = null;
    });
  }

  void _showSearch() {
    setState(() {
      _currentContent = ContentType.search;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final guestSessionProvider = Provider.of<GuestSessionProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        // Fixed AppBar that never changes
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.diamond_outlined,
              color: AppTheme.primaryGold,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Thyne Jewels',
                style: Theme.of(context).textTheme.headlineLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        leading: _currentContent != ContentType.home
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _showHome,
              )
            : _buildUserIndicator(authProvider, guestSessionProvider),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: badges.Badge(
              badgeContent: Text(
                wishlistProvider.wishlistCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              showBadge: wishlistProvider.wishlistCount > 0,
              child: const Icon(Icons.favorite_outline),
            ),
            onPressed: () => Navigator.pushNamed(context, '/wishlist'),
          ),
          IconButton(
            icon: badges.Badge(
              badgeContent: Text(
                cartProvider.itemCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              showBadge: cartProvider.itemCount > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildCurrentContent(),
      ),
    );
  }

  Widget _buildCurrentContent() {
    switch (_currentContent) {
      case ContentType.home:
        return DynamicHomeScreen(
          key: const ValueKey('home'),
          onCategoryTap: _showCategoryProducts,
          onViewAllProducts: _showAllProducts,
        );

      case ContentType.categoryProducts:
        return ProductListScreen(
          key: ValueKey('category_$_selectedCategory'),
          category: _selectedCategory,
          isEmbedded: true,
        );

      case ContentType.allProducts:
        return const ProductListScreen(
          key: ValueKey('all_products'),
          isEmbedded: true,
        );

      case ContentType.search:
        return SearchScreen(
          key: const ValueKey('search'),
          isEmbedded: true,
          onBack: _showHome,
        );
    }
  }

  Widget _buildUserIndicator(
    AuthProvider authProvider,
    GuestSessionProvider guestSessionProvider,
  ) {
    if (authProvider.isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: AppTheme.primaryGold,
          child: Text(
            authProvider.user!.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (guestSessionProvider.isActive) {
      return IconButton(
        icon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline,
              size: 20,
              color: AppTheme.primaryGold,
            ),
            Text(
              'Guest',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    color: AppTheme.primaryGold,
                  ),
            ),
          ],
        ),
        onPressed: () => Navigator.pushNamed(context, '/login'),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.person_outline),
        onPressed: () => Navigator.pushNamed(context, '/login'),
      );
    }
  }
}
