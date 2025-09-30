import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/privacy_policy_screen.dart';
import '../settings/terms_conditions_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 100,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'Please Login',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Login to access your profile and orders',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    final user = authProvider.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGold.withOpacity(0.1),
                    AppTheme.secondaryRoseGold.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryGold,
                    child: user.profileImage != null
                        ? ClipOval(
                            child: Image.network(
                              user.profileImage!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        Text(
                          user.phone,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Edit profile
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Menu Options
            _buildMenuSection(
              'Orders',
              [
                _buildMenuItem(
                  context,
                  'My Orders',
                  Icons.shopping_bag_outlined,
                  () {
                    Navigator.pushNamed(context, '/orders');
                  },
                ),
                _buildMenuItem(
                  context,
                  'Order History',
                  Icons.history,
                  () {
                    Navigator.pushNamed(context, '/order-history');
                  },
                ),
                _buildMenuItem(
                  context,
                  'Track Order',
                  Icons.local_shipping_outlined,
                  () {
                    Navigator.pushNamed(context, '/track-order');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildMenuSection(
              'Preferences',
              [
                _buildMenuItem(
                  context,
                  'Wishlist',
                  Icons.favorite_outline,
                  () {
                    Navigator.pushNamed(context, '/wishlist');
                  },
                ),
                _buildMenuItem(
                  context,
                  'Loyalty Rewards',
                  Icons.loyalty,
                  () {
                    Navigator.pushNamed(context, '/loyalty');
                  },
                ),
                _buildMenuItem(
                  context,
                  'Addresses',
                  Icons.location_on_outlined,
                  () {
                    // Navigate to addresses
                  },
                ),
                _buildMenuItem(
                  context,
                  'Payment Methods',
                  Icons.payment,
                  () {
                    // Navigate to payment methods
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildMenuSection(
              'Support',
              [
                _buildMenuItem(
                  context,
                  'Help & Support',
                  Icons.help_outline,
                  () {
                    // Navigate to help
                  },
                ),
                _buildMenuItem(
                  context,
                  'Contact Us',
                  Icons.phone_outlined,
                  () {
                    // Navigate to contact
                  },
                ),
                _buildMenuItem(
                  context,
                  'About Us',
                  Icons.info_outline,
                  () {
                    // Navigate to about
                  },
                ),
                _buildMenuItem(
                  context,
                  'Admin Panel',
                  Icons.admin_panel_settings,
                  () {
                    Navigator.pushNamed(context, '/admin');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildMenuSection(
              'Settings',
              [
                _buildMenuItem(
                  context,
                  'Notifications',
                  Icons.notifications_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  'Privacy Policy',
                  Icons.privacy_tip_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  'Terms & Conditions',
                  Icons.description_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            authProvider.logout();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: AppTheme.errorRed),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: AppTheme.errorRed),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}