import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/providers/auth_provider.dart';
import 'lib/providers/theme_provider.dart';
import 'lib/providers/product_provider.dart';
import 'lib/providers/cart_provider.dart';
import 'lib/providers/order_provider.dart';
import 'lib/providers/guest_session_provider.dart';
import 'lib/providers/loyalty_provider.dart';
import 'lib/providers/wishlist_provider.dart';
import 'lib/providers/address_provider.dart';
import 'lib/providers/community_provider.dart';
import 'lib/screens/home/thyne_home_complete.dart';
import 'lib/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService.initialize();

  // Initialize auth status
  final authProvider = AuthProvider();
  await authProvider.checkAuthStatus();

  runApp(TestApp(authProvider: authProvider));
}

class TestApp extends StatelessWidget {
  final AuthProvider authProvider;

  const TestApp({super.key, required this.authProvider});

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
      ],
      child: MaterialApp(
        title: 'Thyne Jewels - Test',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.brown,
          fontFamily: 'Inter',
        ),
        home: const ThyneHomeComplete(), // Direct to home screen
      ),
    );
  }
}