import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/presentation/viewmodels/auth_provider.dart';
import 'lib/presentation/viewmodels/theme_provider.dart';
import 'lib/presentation/viewmodels/product_provider.dart';
import 'lib/presentation/viewmodels/cart_provider.dart';
import 'lib/presentation/viewmodels/order_provider.dart';
import 'lib/presentation/viewmodels/guest_session_provider.dart';
import 'lib/presentation/viewmodels/loyalty_provider.dart';
import 'lib/presentation/viewmodels/wishlist_provider.dart';
import 'lib/presentation/viewmodels/address_provider.dart';
import 'lib/presentation/viewmodels/community_provider.dart';
import 'lib/presentation/views/home/thyne_home_complete.dart';
import 'lib/data/services/storage_service.dart';

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
