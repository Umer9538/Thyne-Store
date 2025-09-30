import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/loyalty.dart';
import '../../utils/theme.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        final loyaltyProvider = context.read<LoyaltyProvider>();
        loyaltyProvider.loadLoyaltyProgram(authProvider.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loyalty Rewards')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.loyalty, size: 80, color: AppTheme.primaryGold),
              SizedBox(height: 16),
              Text(
                'Login to Access Rewards',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Join our loyalty program and start earning points!'),
            ],
          ),
        ),
      );
    }

    return Consumer<LoyaltyProvider>(
      builder: (context, loyaltyProvider, child) {
        if (loyaltyProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loyalty Rewards')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (loyaltyProvider.loyaltyProgram == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loyalty Rewards')),
            body: const Center(child: Text('Error loading loyalty program')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Loyalty Rewards'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Rewards'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(loyaltyProvider.loyaltyProgram!),
              _buildRewardsTab(loyaltyProvider),
              _buildHistoryTab(loyaltyProvider.loyaltyProgram!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(LoyaltyProgram program) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Summary Card
          Card(
            elevation: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGold.withOpacity(0.8),
                    AppTheme.secondaryRoseGold.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${program.currentPoints}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Available Points',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${program.totalPoints}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Total Earned',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '${program.loginStreak}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Day Streak',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tier Progress Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        program.tier.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${program.tier.displayName} Member',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (program.tier != LoyaltyTier.platinum) ...[
                    Text(
                      '${program.pointsToNextTier} points to next tier',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: program.tierProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                    ),
                  ] else ...[
                    const Text('Congratulations! You\'ve reached the highest tier!'),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Tier Benefits:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...program.tier.benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(benefit, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.shopping_bag, color: AppTheme.primaryGold),
                        const SizedBox(height: 8),
                        Text(
                          '${program.totalOrders}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('Orders', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.attach_money, color: AppTheme.primaryGold),
                        const SizedBox(height: 8),
                        Text(
                          '\$${program.totalSpent.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('Spent', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.card_giftcard, color: AppTheme.primaryGold),
                        const SizedBox(height: 8),
                        Text(
                          '${program.vouchers.length}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('Vouchers', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(LoyaltyProvider loyaltyProvider) {
    final program = loyaltyProvider.loyaltyProgram!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Redeem Points (${program.currentPoints} available)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          FutureBuilder<List<Voucher>>(
            future: loyaltyProvider.getAvailableVouchers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final availableVouchers = snapshot.data ?? [];
              
              return Column(
                children: availableVouchers.map((voucher) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voucher.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              voucher.description,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            if (voucher.minimumPurchase != null)
                              Text(
                                'Min. purchase: \$${voucher.minimumPurchase!.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: Colors.orange),
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
                              color: AppTheme.primaryGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${voucher.pointsCost} pts',
                              style: const TextStyle(
                                color: AppTheme.primaryGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: program.currentPoints >= voucher.pointsCost
                                ? () => _redeemVoucher(loyaltyProvider, voucher)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(80, 32),
                            ),
                            child: const Text('Redeem', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(LoyaltyProgram program) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: program.transactions.length,
      itemBuilder: (context, index) {
        final transaction = program.transactions[program.transactions.length - 1 - index];
        final isPositive = transaction.points > 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPositive ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                isPositive ? Icons.add : Icons.remove,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            title: Text(transaction.description),
            subtitle: Text(_formatDate(transaction.createdAt)),
            trailing: Text(
              '${isPositive ? '+' : ''}${transaction.points}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  void _redeemVoucher(LoyaltyProvider loyaltyProvider, Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Redeem "${voucher.title}" for ${voucher.pointsCost} points?'),
            const SizedBox(height: 8),
            Text(
              voucher.description,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await loyaltyProvider.redeemPoints(voucher);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Voucher "${voucher.code}" has been added to your account!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}