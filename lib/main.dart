import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/guest_session_provider.dart';
import 'providers/wishlist_provider.dart';
import 'utils/theme.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/main_navigation.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/checkout/guest_checkout_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/customers/customers_management_screen.dart';
import 'screens/admin/products/product_management_screen.dart';
import 'screens/admin/categories/category_management_screen.dart';
import 'screens/admin/inventory/inventory_management_screen.dart';
import 'screens/admin/orders/order_management_screen.dart';
import 'screens/admin/analytics/analytics_dashboard.dart';
import 'screens/search/enhanced_search_screen.dart';
import 'screens/loyalty/loyalty_screen.dart';
import 'screens/admin/storefront/storefront_management_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';
import 'screens/orders/order_history_screen.dart';
import 'screens/orders/track_order_screen.dart';
import 'providers/loyalty_provider.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize storage service first
    await StorageService.initialize();
    
    // Initialize database for non-web platforms
    if (!kIsWeb) {
      await DatabaseHelper.initializeDatabaseFactory();
    }

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
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => GuestSessionProvider()),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Set up loyalty callback when providers are available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
            
            authProvider.setOnLoginSuccess((userId) {
              loyaltyProvider.loadLoyaltyProgram(userId);
            });
          });
          
          return MaterialApp(
            title: 'Thyne Jewels',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const AppWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const MainNavigation(),
              '/cart': (context) => const CartScreen(),
              '/checkout': (context) => const CheckoutScreen(),
              '/guest-checkout': (context) => const GuestCheckoutScreen(),
              '/admin': (context) => const AdminDashboard(),
              '/admin/products': (context) => const ProductManagementScreen(),
              '/admin/categories': (context) => const CategoryManagementScreen(),
              '/admin/inventory': (context) => const InventoryManagementScreen(),
              '/admin/orders': (context) => const OrderManagementScreen(),
              '/admin/analytics': (context) => const AnalyticsDashboard(),
              '/admin/customers': (context) => const CustomersManagementScreen(),
              '/search': (context) => const EnhancedSearchScreen(),
              '/loyalty': (context) => const LoyaltyScreen(),
              '/admin/storefront': (context) => const StorefrontManagementScreen(),
              '/wishlist': (context) => const WishlistScreen(),
              '/order-history': (context) => const OrderHistoryScreen(),
              '/track-order': (context) => const TrackOrderScreen(),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final guestSessionProvider = context.read<GuestSessionProvider>();
      final authProvider = context.read<AuthProvider>();

      // Initialize guest session if user is not authenticated
      if (!authProvider.isAuthenticated && !guestSessionProvider.isActive) {
        guestSessionProvider.startGuestSession();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, GuestSessionProvider>(
      builder: (context, authProvider, guestSessionProvider, child) {
        return const MainNavigation();
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
            builder: (context) => const MainNavigation(),
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGold.withOpacity(0.2),
              Colors.white,
              AppTheme.secondaryRoseGold.withOpacity(0.2),
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
                          color: AppTheme.primaryGold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGold.withOpacity(0.3),
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
                          color: AppTheme.textPrimary,
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
                          AppTheme.primaryGold,
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