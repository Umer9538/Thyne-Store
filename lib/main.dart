import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constants
import 'constants/routes.dart';

// Providers
import 'presentation/viewmodels/auth_provider.dart';
import 'presentation/viewmodels/product_provider.dart';
import 'presentation/viewmodels/cart_provider.dart';
import 'presentation/viewmodels/order_provider.dart';
import 'presentation/viewmodels/guest_session_provider.dart';
import 'presentation/viewmodels/wishlist_provider.dart';
import 'presentation/viewmodels/address_provider.dart';
import 'presentation/viewmodels/theme_provider.dart';
import 'presentation/viewmodels/recently_viewed_provider.dart';
import 'presentation/viewmodels/loyalty_provider.dart';
import 'presentation/viewmodels/community_provider.dart';
import 'presentation/viewmodels/ai_provider.dart';
import 'presentation/viewmodels/store_settings_provider.dart';

// Theme
import 'theme/thyne_theme.dart';
import 'utils/theme.dart';

// Services
import 'data/services/notification_service.dart';
import 'data/services/storage_service.dart';

// Screens - Auth
import 'presentation/views/auth/login_screen.dart';
import 'presentation/views/auth/admin_login_screen.dart';
import 'presentation/views/onboarding/onboarding_screen.dart';

// Screens - Home & Navigation
import 'presentation/widgets/main_navigation.dart';
import 'presentation/widgets/three_section_navigation.dart';
import 'presentation/views/home/thyne_home_figma.dart';
import 'presentation/views/home/thyne_home_complete.dart';

// Screens - Shopping
import 'presentation/views/cart/cart_screen.dart';
import 'presentation/views/checkout/checkout_screen.dart';
import 'presentation/views/checkout/guest_checkout_screen.dart';
import 'presentation/views/search/enhanced_search_screen.dart';
import 'presentation/views/wishlist/wishlist_screen.dart';
import 'presentation/views/loyalty/loyalty_screen.dart';

// Screens - Orders
import 'presentation/views/orders/order_history_screen.dart';
import 'presentation/views/orders/track_order_screen.dart';
import 'presentation/views/orders/my_orders_screen.dart';

// Screens - Profile
import 'presentation/views/profile/addresses_screen.dart';
import 'presentation/views/profile/profile_screen.dart';

// Screens - Community
import 'presentation/views/community/community_feed_screen.dart';
import 'presentation/views/community/create_post_screen.dart';

// Screens - Admin
import 'presentation/views/admin/admin_dashboard.dart';
import 'presentation/views/admin/users/user_management_screen.dart';
import 'presentation/views/admin/products/product_management_screen.dart';
import 'presentation/views/admin/categories/category_management_screen.dart';
import 'presentation/views/admin/inventory/inventory_management_screen.dart';
import 'presentation/views/admin/orders/order_management_screen.dart';
import 'presentation/views/admin/orders/custom_orders_screen.dart';
import 'presentation/views/admin/analytics/analytics_dashboard.dart';
import 'presentation/views/admin/storefront/storefront_management_screen.dart';
import 'presentation/views/admin/storefront/storefront_data_management_screen.dart';
import 'presentation/views/admin/events/event_calendar_screen.dart';
import 'presentation/views/admin/homepage/homepage_manager_screen.dart';
import 'presentation/views/admin/homepage/layout_manager_screen.dart';
import 'presentation/views/admin/theme/theme_switcher_screen.dart';
import 'presentation/views/admin/community/admin_community_dashboard.dart';
import 'presentation/views/admin/settings/store_settings_screen.dart';

// Screens - Admin Dynamic Content
import 'presentation/views/admin/dynamic_content/dynamic_content_dashboard.dart';
import 'presentation/views/admin/dynamic_content/deals_of_day_screen.dart';
import 'presentation/views/admin/dynamic_content/bundle_deals_screen.dart';
import 'presentation/views/admin/dynamic_content/flash_sales_screen.dart';
import 'presentation/views/admin/dynamic_content/showcases_360_screen.dart';
import 'presentation/views/admin/dynamic_content/brands_screen.dart';
import 'presentation/views/admin/dynamic_content/create_deal_form.dart';
import 'presentation/views/admin/dynamic_content/create_flash_sale_form.dart';
import 'presentation/views/admin/dynamic_content/create_showcase_form.dart';
import 'presentation/views/admin/dynamic_content/create_bundle_form.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure image cache for better performance
  DefaultCacheManager().emptyCache(); // Clear old cache on startup

  // Set image cache limits
  PaintingBinding.instance.imageCache.maximumSize = 100; // Max 100 images in memory
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // Max 50MB

  try {
    // Initialize storage service first
    await StorageService.initialize();

    // Initialize Firebase and notifications (only for mobile platforms)
    if (!kIsWeb) {
      // For mobile platforms, use default initialization
      await Firebase.initializeApp();

      // Initialize notification service
      await NotificationService().initialize();
    } else {
      debugPrint('Skipping Firebase and NotificationService initialization on web');
    }
  } catch (e) {
    debugPrint('Initialization failed: $e');
    // Continue with app startup
  }

  // Set up responsive design for web
  if (kIsWeb) {
    // Prevent browser zoom
    // This helps maintain consistent responsive layout
  }

  // Initialize auth status
  final authProvider = AuthProvider();
  await authProvider.checkAuthStatus();

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  
  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => GuestSessionProvider()),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => RecentlyViewedProvider()),
        ChangeNotifierProvider(create: (_) => StoreSettingsProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Set up provider callbacks when providers are available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
            final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
            final aiProvider = Provider.of<AIProvider>(context, listen: false);

            // Set up login callback
            authProvider.setOnLoginSuccess((userId) {
              loyaltyProvider.loadLoyaltyProgram(userId);
              wishlistProvider.loadWishlist();
              aiProvider.setUser(userId); // Load AI data from backend
            });

            // Set up logout callback
            authProvider.setOnLogout(() {
              aiProvider.setUser(null); // Clear AI data on logout
            });

            // Load data if user is already authenticated
            if (authProvider.isAuthenticated && authProvider.user != null) {
              wishlistProvider.loadWishlist();
              aiProvider.setUser(authProvider.user!.id);
            }

            // Load store settings for cart calculations
            final cartProvider = Provider.of<CartProvider>(context, listen: false);
            cartProvider.loadStoreSettings();
          });
          
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return MaterialApp(
                title: 'Thyne Jewels',
                debugShowCheckedModeBanner: false,
                theme: ThyneTheme.lightTheme(),
                // Enable responsive behavior
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      // Ensure text scaling doesn't break layout
                      textScaler: TextScaler.linear(
                        MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3),
                      ),
                    ),
                    child: child!,
                  );
                },
                home: const AppWrapper(),
                routes: {
              // Auth routes
              Routes.onboarding: (context) => const OnboardingScreen(),
              Routes.login: (context) => const LoginScreen(),
              Routes.adminLogin: (context) => const AdminLoginScreen(),
              // Main home - production screen
              Routes.home: (context) => const ThyneHomeComplete(),
              // Legacy routes - kept for testing/comparison only
              Routes.homeFigma: (context) => const ThyneHomeFigma(),
              Routes.homeOld: (context) => const ThreeSectionNavigation(),
              Routes.homeLegacy: (context) => const MainNavigation(),
              // Shopping routes
              Routes.cart: (context) => const CartScreen(),
              Routes.checkout: (context) => const CheckoutScreen(),
              Routes.guestCheckout: (context) => const GuestCheckoutScreen(),
              Routes.search: (context) => const EnhancedSearchScreen(),
              Routes.wishlist: (context) => const WishlistScreen(),
              Routes.loyalty: (context) => const LoyaltyScreen(),
              // Order routes
              Routes.orders: (context) => const MyOrdersScreen(),
              Routes.orderHistory: (context) => const OrderHistoryScreen(),
              Routes.trackOrder: (context) => const TrackOrderScreen(),
              // Profile routes
              Routes.profile: (context) => const ProfileScreen(),
              Routes.addresses: (context) => const AddressesScreen(),
              // Community routes
              Routes.community: (context) => const CommunityFeedScreen(),
              Routes.communityCreate: (context) => const CreatePostScreen(),
              // Admin routes
              Routes.admin: (context) => const AdminDashboard(),
              Routes.adminProducts: (context) => const ProductManagementScreen(),
              Routes.adminCategories: (context) => const CategoryManagementScreen(),
              Routes.adminInventory: (context) => const InventoryManagementScreen(),
              Routes.adminOrders: (context) => const OrderManagementScreen(),
              Routes.adminCustomOrders: (context) => const CustomOrdersScreen(),
              Routes.adminAnalytics: (context) => const AnalyticsDashboard(),
              Routes.adminCustomers: (context) => const UserManagementScreen(),
              Routes.adminStorefront: (context) => const StorefrontManagementScreen(),
              Routes.adminStorefrontData: (context) => const StorefrontDataManagementScreen(),
              Routes.adminEvents: (context) => const EventCalendarScreen(),
              Routes.adminBanners: (context) => const HomepageManagerScreen(),
              Routes.adminHomepageLayout: (context) => const LayoutManagerScreen(),
              Routes.adminThemes: (context) => const ThemeSwitcherScreen(),
              Routes.adminCommunity: (context) => const AdminCommunityDashboard(),
              Routes.adminStoreSettings: (context) => const StoreSettingsScreen(),
              // Admin Dynamic Content routes
              Routes.adminDynamicContent: (context) => const DynamicContentDashboard(),
              Routes.adminDealsOfDay: (context) => const DealsOfDayScreen(),
              Routes.adminDealsOfDayCreate: (context) => const CreateDealForm(),
              Routes.adminBundleDeals: (context) => const BundleDealsScreen(),
              Routes.adminBundleDealsCreate: (context) => const CreateBundleForm(),
              Routes.adminFlashSales: (context) => const FlashSalesScreen(),
              Routes.adminFlashSalesCreate: (context) => const CreateFlashSaleForm(),
              Routes.adminShowcases360: (context) => const Showcases360Screen(),
              Routes.adminShowcases360Create: (context) => const CreateShowcaseForm(),
              Routes.adminBrands: (context) => const BrandsScreen(),
            },
              );
            },
          );
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      // Add timeout to prevent hanging
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (mounted) {
        setState(() {
          _onboardingComplete = onboardingComplete;
          _isLoading = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        try {
          final guestSessionProvider = context.read<GuestSessionProvider>();
          final authProvider = context.read<AuthProvider>();
          final wishlistProvider = context.read<WishlistProvider>();

          // Initialize guest session if user is not authenticated
          if (!authProvider.isAuthenticated && !guestSessionProvider.isActive) {
            guestSessionProvider.startGuestSession();
          }

          // Load wishlist if user is authenticated
          if (authProvider.isAuthenticated) {
            wishlistProvider.loadWishlist();
          }
        } catch (e) {
          debugPrint('Error initializing providers: $e');
        }
      });
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      // On error, assume onboarding not complete and stop loading
      if (mounted) {
        setState(() {
          _onboardingComplete = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF094010)), // Dark green theme color
          ),
        ),
      );
    }

    if (!_onboardingComplete) {
      return const OnboardingScreen();
    }

    return Consumer2<AuthProvider, GuestSessionProvider>(
      builder: (context, authProvider, guestSessionProvider, child) {
        return const ThyneHomeComplete(); // Use complete design with all sections
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Navigate to main app after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ThyneHomeComplete(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme dark green color
    const darkGreen = Color(0xFF094010);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              darkGreen.withOpacity(0.1),
              Colors.white,
              darkGreen.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: darkGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: darkGreen.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Thyne Jewels',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Demi-Fine Jewelry',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 60),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}