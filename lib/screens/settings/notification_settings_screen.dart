import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _orderUpdates = true;
  bool _promotionalOffers = true;
  bool _reminders = true;
  bool _loyaltyRewards = true;
  bool _backInStock = true;
  bool _flashSales = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      // First try to load from backend
      final response = await ApiService.getNotificationPreferences();
      final preferences = response['data'] as Map<String, dynamic>? ?? {};

      setState(() {
        _orderUpdates = preferences['orderUpdates'] ?? true;
        _promotionalOffers = preferences['promotions'] ?? true;
        _reminders = preferences['reminders'] ?? true;
        _loyaltyRewards = preferences['loyaltyRewards'] ?? true;
        _backInStock = preferences['backInStock'] ?? true;
        _flashSales = preferences['flashSales'] ?? true;
        _loading = false;
      });
    } catch (e) {
      // Fallback to local preferences from NotificationService
      final preferences = await NotificationService().getNotificationPreferences();
      setState(() {
        _orderUpdates = preferences['orderUpdates'] ?? true;
        _promotionalOffers = preferences['promotions'] ?? true;
        _reminders = preferences['reminders'] ?? true;
        _loyaltyRewards = preferences['loyaltyRewards'] ?? true;
        _backInStock = preferences['backInStock'] ?? true;
        _flashSales = preferences['flashSales'] ?? true;
        _loading = false;
      });
    }
  }

  Future<void> _saveNotificationPreferences() async {
    try {
      // Update notification service preferences (this will sync with backend)
      await NotificationService().updateNotificationPreferences(
        orderUpdates: _orderUpdates,
        promotions: _promotionalOffers,
        reminders: _reminders,
        loyaltyRewards: _loyaltyRewards,
        backInStock: _backInStock,
        flashSales: _flashSales,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved'),
            backgroundColor: AppTheme.primaryGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saveNotificationPreferences,
              child: const Text(
                'Save',
                style: TextStyle(color: AppTheme.primaryGold),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stay updated with notifications that matter to you',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildNotificationSection(
                    'Order Updates',
                    'Get notified about your order status',
                    [
                      _buildNotificationTile(
                        'Order Updates',
                        'Order confirmations, shipping updates, and delivery notifications',
                        Icons.shopping_bag_outlined,
                        _orderUpdates,
                        (value) => setState(() => _orderUpdates = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildNotificationSection(
                    'Promotional',
                    'Special offers and deals',
                    [
                      _buildNotificationTile(
                        'Promotional Offers',
                        'Exclusive deals, seasonal sales, and special discounts',
                        Icons.local_offer_outlined,
                        _promotionalOffers,
                        (value) => setState(() => _promotionalOffers = value),
                      ),
                      _buildNotificationTile(
                        'Flash Sales',
                        'Limited-time offers and flash sale alerts',
                        Icons.flash_on_outlined,
                        _flashSales,
                        (value) => setState(() => _flashSales = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildNotificationSection(
                    'Reminders & Alerts',
                    'Helpful reminders and stock alerts',
                    [
                      _buildNotificationTile(
                        'Cart Reminders',
                        'Reminders about items left in your cart',
                        Icons.shopping_cart_outlined,
                        _reminders,
                        (value) => setState(() => _reminders = value),
                      ),
                      _buildNotificationTile(
                        'Back in Stock',
                        'Alerts when your wishlist items are available',
                        Icons.inventory_outlined,
                        _backInStock,
                        (value) => setState(() => _backInStock = value),
                      ),
                      _buildNotificationTile(
                        'Loyalty Rewards',
                        'Updates about your points and rewards',
                        Icons.loyalty_outlined,
                        _loyaltyRewards,
                        (value) => setState(() => _loyaltyRewards = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGold.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryGold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Notification Settings',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You can also manage notification permissions in your device settings. Some notifications may still appear based on your order activity.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationSection(String title, String subtitle, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: value ? AppTheme.primaryGold : AppTheme.textSecondary,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGold,
      ),
    );
  }
}