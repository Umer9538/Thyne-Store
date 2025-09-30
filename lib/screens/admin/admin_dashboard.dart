import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  String? _error;

  int _totalProducts = 0;
  int _totalOrders = 0;
  int _lowStock = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dashboardResp = await ApiService.getAdminDashboardStats();
      if (dashboardResp['success'] == true) {
        final data = (dashboardResp['data'] ?? {}) as Map<String, dynamic>;
        _totalProducts = (data['totalProducts'] ?? 0) as int;
        _totalOrders = (data['totalOrders'] ?? 0) as int;
        final rev = data['totalRevenue'];
        if (rev is num) {
          _totalRevenue = rev.toDouble();
        }
      }

      // Low stock from product stats endpoint
      try {
        final productStats = await ApiService.getAdminProductStats();
        if (productStats['success'] == true) {
          final pdata = (productStats['data'] ?? {}) as Map<String, dynamic>;
          _lowStock = (pdata['lowStock'] ?? 0) as int;
          // If totalProducts wasn't present in dashboard stats, fallback
          if (_totalProducts == 0) {
            _totalProducts = (pdata['totalProducts'] ?? 0) as int;
          }
        }
      } catch (_) {
        // Optional; ignore if unavailable
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load stats';
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Welcome Section
            Container(
              width: double.infinity,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Admin Panel',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your jewelry store efficiently',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Loading / Error / Stats
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ))
            else if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unable to load overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_error!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loadStats,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              _buildStatsSection(),
            const SizedBox(height: 24),

            // Management Options
            Text(
              'Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildManagementGrid(),
          ],
        ),
      ),
    ));
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Products',
                _totalProducts.toString(),
                Icons.inventory,
                AppTheme.primaryGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Orders',
                _totalOrders.toString(),
                Icons.shopping_bag,
                AppTheme.secondaryRoseGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Low Stock',
                _lowStock.toString(),
                Icons.warning,
                AppTheme.errorRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Revenue',
                '₹${_formatCurrency(_totalRevenue)}',
                Icons.trending_up,
                AppTheme.successGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementGrid() {
    final managementOptions = [
      {
        'title': 'Products',
        'subtitle': 'Add, edit & manage products',
        'icon': Icons.inventory_2,
        'color': AppTheme.primaryGold,
        'route': '/admin/products',
      },
      {
        'title': 'Categories',
        'subtitle': 'Manage product categories',
        'icon': Icons.category,
        'color': AppTheme.secondaryRoseGold,
        'route': '/admin/categories',
      },
      {
        'title': 'Orders',
        'subtitle': 'View & manage orders',
        'icon': Icons.shopping_cart,
        'color': AppTheme.accentPurple,
        'route': '/admin/orders',
      },
      {
        'title': 'Inventory',
        'subtitle': 'Stock management',
        'icon': Icons.warehouse,
        'color': AppTheme.successGreen,
        'route': '/admin/inventory',
      },
      {
        'title': 'Analytics',
        'subtitle': 'Sales & performance',
        'icon': Icons.analytics,
        'color': Colors.blue,
        'route': '/admin/analytics',
      },
      {
        'title': 'Customers',
        'subtitle': 'User management',
        'icon': Icons.people,
        'color': Colors.orange,
        'route': '/admin/customers',
      },
      {
        'title': 'Storefront',
        'subtitle': 'Dynamic store config',
        'icon': Icons.storefront,
        'color': Colors.purple,
        'route': '/admin/storefront',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: managementOptions.length,
      itemBuilder: (context, index) {
        final option = managementOptions[index];
        return _buildManagementCard(
          option['title'] as String,
          option['subtitle'] as String,
          option['icon'] as IconData,
          option['color'] as Color,
          option['route'] as String,
        );
      },
    );
  }

  Widget _buildManagementCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    // Simple grouping, no intl dependency
    final rounded = amount.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}