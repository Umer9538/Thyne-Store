import 'package:flutter/material.dart';
import 'package:thyne_jewls/utils/theme.dart';

class DynamicContentDashboard extends StatefulWidget {
  const DynamicContentDashboard({super.key});

  @override
  State<DynamicContentDashboard> createState() => _DynamicContentDashboardState();
}

class _DynamicContentDashboardState extends State<DynamicContentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Content Manager'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGold.withOpacity(0.1),
                    AppTheme.secondaryRoseGold.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.dashboard_customize,
                    color: AppTheme.primaryGold,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dynamic Dashboard Control',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage all dynamic content that appears on customer homepage',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content Type Cards
            Text(
              'Content Types',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            _buildContentTypeCard(
              title: 'Deal of Day',
              subtitle: 'Single product with time-limited discount',
              icon: Icons.flash_on,
              color: Colors.orange,
              count: '1 Active',
              route: '/admin/deals-of-day',
            ),

            const SizedBox(height: 12),

            _buildContentTypeCard(
              title: 'Flash Sales',
              subtitle: 'Multiple products on sale for limited time',
              icon: Icons.local_fire_department,
              color: Colors.red,
              count: '2 Active',
              route: '/admin/flash-sales',
            ),

            const SizedBox(height: 12),

            _buildContentTypeCard(
              title: '360° Showcases',
              subtitle: 'Interactive product views with rotation',
              icon: Icons.rotate_right,
              color: Colors.purple,
              count: '1 Active',
              route: '/admin/showcases-360',
            ),

            const SizedBox(height: 12),

            _buildContentTypeCard(
              title: 'Bundle Deals',
              subtitle: 'Product combinations with package discount',
              icon: Icons.inventory_2,
              color: Colors.blue,
              count: '2 Active',
              route: '/admin/bundle-deals',
            ),

            const SizedBox(height: 12),

            _buildContentTypeCard(
              title: 'Brands',
              subtitle: 'Featured brand logos and collections',
              icon: Icons.business,
              color: Colors.teal,
              count: '3 Active',
              route: '/admin/brands',
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    label: 'Create Deal',
                    icon: Icons.add_circle,
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/admin/deals-of-day/create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    label: 'New Bundle',
                    icon: Icons.add_shopping_cart,
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/admin/bundle-deals/create'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    label: 'Add Showcase',
                    icon: Icons.rotate_right,
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(context, '/admin/showcases-360/create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    label: 'New Flash Sale',
                    icon: Icons.bolt,
                    color: Colors.red,
                    onTap: () => Navigator.pushNamed(context, '/admin/flash-sales/create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String count,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
