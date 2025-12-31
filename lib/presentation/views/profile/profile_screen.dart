import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../../utils/theme.dart';
import '../auth/login_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/privacy_policy_screen.dart';
import '../settings/terms_conditions_screen.dart';
import 'edit_profile_screen.dart';
import '../../widgets/glass/glass_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return GlassScaffold(
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
              GlassPrimaryButton(
                text: 'Login',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    final user = authProvider.user!;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            GlassContainer(
              padding: const EdgeInsets.all(20),
              blur: GlassConfig.mediumBlur,
              showGlow: true,
              tintColor: AppTheme.primaryGold,
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGold.withOpacity(0.1),
                  AppTheme.secondaryRoseGold.withOpacity(0.1),
                ],
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
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          user.phone,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  GlassIconButton(
                    icon: Icons.edit,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    size: 40,
                    tintColor: AppTheme.primaryGold,
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
                    Navigator.pushNamed(context, '/addresses');
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
              child: GlassButton(
                text: '',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => GlassDialog(
                      title: 'Logout',
                      message: 'Are you sure you want to logout?',
                      actions: [
                        GlassButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                          blur: GlassConfig.softBlur,
                        ),
                        GlassButton(
                          text: 'Logout',
                          onPressed: () {
                            authProvider.logout();
                            Navigator.pop(context);
                          },
                          tintColor: AppTheme.errorRed,
                          blur: GlassConfig.mediumBlur,
                        ),
                      ],
                    ),
                  );
                },
                padding: const EdgeInsets.symmetric(vertical: 12),
                blur: GlassConfig.softBlur,
                tintColor: AppTheme.errorRed,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: AppTheme.errorRed),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                  ],
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
        GlassCard(
          padding: EdgeInsets.zero,
          elevation: 2,
          blur: GlassConfig.softBlur,
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