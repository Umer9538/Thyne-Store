import 'package:flutter/foundation.dart';
import '../models/loyalty.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class LoyaltyProvider extends ChangeNotifier {
  LoyaltyProgram? _loyaltyProgram;
  bool _isLoading = false;
  NotificationService? _notificationService;

  LoyaltyProvider() {
    // Only initialize NotificationService on non-web platforms
    if (!kIsWeb) {
      _notificationService = NotificationService();
    }
  }

  LoyaltyProgram? get loyaltyProgram => _loyaltyProgram;
  bool get isLoading => _isLoading;

  // Points calculation rates
  static const double basePointsPerDollar = 1.0;
  static const int dailyLoginBonus = 10;
  static const int streakBonus = 50; // Every 7 days
  static const int referralBonus = 100;
  static const int reviewBonus = 25;

  Future<void> loadLoyaltyProgram(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getLoyaltyProgram();
      if (response['success'] == true && response['data'] != null) {
        _loyaltyProgram = LoyaltyProgram.fromJson(response['data']);
        
        // Trigger daily login check
        await ApiService.checkDailyLogin();
        
        // Refresh data after daily login check
        final updatedResponse = await ApiService.getLoyaltyProgram();
        if (updatedResponse['success'] == true && updatedResponse['data'] != null) {
          _loyaltyProgram = LoyaltyProgram.fromJson(updatedResponse['data']);
        }
      } else {
        debugPrint('Failed to load loyalty program from API');
      }
    } catch (e) {
      debugPrint('Error loading loyalty program: $e');
    }

    _isLoading = false;
    notifyListeners();
  }


  Future<void> _checkDailyLogin() async {
    if (_loyaltyProgram == null) return;

    final now = DateTime.now();
    final lastLogin = _loyaltyProgram!.lastLoginDate;

    if (lastLogin == null || !_isSameDay(now, lastLogin)) {
      int bonusPoints = dailyLoginBonus;
      int newStreak = 1;

      if (lastLogin != null) {
        final difference = now.difference(lastLogin).inDays;
        if (difference == 1) {
          // Consecutive day
          newStreak = _loyaltyProgram!.loginStreak + 1;

          // Check for streak bonus (every 7 days)
          if (newStreak % 7 == 0) {
            bonusPoints += streakBonus;
            _notificationService?.sendStreakBonusNotification(newStreak, streakBonus);
          }
        }
      }

      await _addPoints(
        bonusPoints,
        'Daily login bonus${newStreak > 1 ? ' (${newStreak} day streak)' : ''}',
        TransactionType.bonus,
      );

      _loyaltyProgram = LoyaltyProgram(
        userId: _loyaltyProgram!.userId,
        totalPoints: _loyaltyProgram!.totalPoints,
        currentPoints: _loyaltyProgram!.currentPoints,
        tier: _loyaltyProgram!.tier,
        loginStreak: newStreak,
        lastLoginDate: now,
        totalSpent: _loyaltyProgram!.totalSpent,
        totalOrders: _loyaltyProgram!.totalOrders,
        transactions: _loyaltyProgram!.transactions,
        vouchers: _loyaltyProgram!.vouchers,
        joinedAt: _loyaltyProgram!.joinedAt,
      );

      // Update via API
      notifyListeners();
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Future<void> earnPointsFromPurchase(double amount, String orderId) async {
    if (_loyaltyProgram == null) return;

    final multiplier = _loyaltyProgram!.tier.pointsMultiplier;
    final points = (amount * basePointsPerDollar * multiplier).round();

    await _addPoints(
      points,
      'Purchase reward for order #$orderId',
      TransactionType.earned,
      orderId: orderId,
    );

    // Update total spent
    _loyaltyProgram = LoyaltyProgram(
      userId: _loyaltyProgram!.userId,
      totalPoints: _loyaltyProgram!.totalPoints,
      currentPoints: _loyaltyProgram!.currentPoints,
      tier: _loyaltyProgram!.tier,
      loginStreak: _loyaltyProgram!.loginStreak,
      lastLoginDate: _loyaltyProgram!.lastLoginDate,
      totalSpent: _loyaltyProgram!.totalSpent + amount,
      totalOrders: _loyaltyProgram!.totalOrders + 1,
      transactions: _loyaltyProgram!.transactions,
      vouchers: _loyaltyProgram!.vouchers,
      joinedAt: _loyaltyProgram!.joinedAt,
    );

    await _checkTierUpgrade();
    // Update via API
    notifyListeners();
  }

  Future<void> earnPointsFromReview(String productId) async {
    await _addPoints(
      reviewBonus,
      'Review bonus for product',
      TransactionType.bonus,
    );
  }

  Future<void> earnPointsFromReferral(String referredUserId) async {
    await _addPoints(
      referralBonus,
      'Referral bonus for inviting a friend',
      TransactionType.bonus,
    );
  }

  Future<void> _addPoints(
    int points,
    String description,
    TransactionType type, {
    String? orderId,
  }) async {
    if (_loyaltyProgram == null) return;

    final transaction = PointTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      points: points,
      description: description,
      createdAt: DateTime.now(),
      orderId: orderId,
    );

    final updatedTransactions = [..._loyaltyProgram!.transactions, transaction];

    _loyaltyProgram = LoyaltyProgram(
      userId: _loyaltyProgram!.userId,
      totalPoints: _loyaltyProgram!.totalPoints + points,
      currentPoints: _loyaltyProgram!.currentPoints + points,
      tier: _loyaltyProgram!.tier,
      loginStreak: _loyaltyProgram!.loginStreak,
      lastLoginDate: _loyaltyProgram!.lastLoginDate,
      totalSpent: _loyaltyProgram!.totalSpent,
      totalOrders: _loyaltyProgram!.totalOrders,
      transactions: updatedTransactions,
      vouchers: _loyaltyProgram!.vouchers,
      joinedAt: _loyaltyProgram!.joinedAt,
    );

    notifyListeners();
  }

  Future<void> redeemPoints(Voucher voucher) async {
    if (_loyaltyProgram == null) return;
    if (_loyaltyProgram!.currentPoints < voucher.pointsCost) {
      throw Exception('Insufficient points');
    }

    // Deduct points
    _loyaltyProgram = LoyaltyProgram(
      userId: _loyaltyProgram!.userId,
      totalPoints: _loyaltyProgram!.totalPoints,
      currentPoints: _loyaltyProgram!.currentPoints - voucher.pointsCost,
      tier: _loyaltyProgram!.tier,
      loginStreak: _loyaltyProgram!.loginStreak,
      lastLoginDate: _loyaltyProgram!.lastLoginDate,
      totalSpent: _loyaltyProgram!.totalSpent,
      totalOrders: _loyaltyProgram!.totalOrders,
      transactions: [
        ..._loyaltyProgram!.transactions,
        PointTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: TransactionType.redeemed,
          points: -voucher.pointsCost,
          description: 'Redeemed: ${voucher.title}',
          createdAt: DateTime.now(),
        ),
      ],
      vouchers: [..._loyaltyProgram!.vouchers, voucher],
      joinedAt: _loyaltyProgram!.joinedAt,
    );

    // Update via API
    notifyListeners();
  }

  Future<void> _checkTierUpgrade() async {
    if (_loyaltyProgram == null) return;

    final currentTier = _loyaltyProgram!.tier;
    LoyaltyTier newTier = currentTier;

    if (_loyaltyProgram!.totalPoints >= 5000) {
      newTier = LoyaltyTier.platinum;
    } else if (_loyaltyProgram!.totalPoints >= 2000) {
      newTier = LoyaltyTier.gold;
    } else if (_loyaltyProgram!.totalPoints >= 500) {
      newTier = LoyaltyTier.silver;
    }

    if (newTier != currentTier) {
      _loyaltyProgram = LoyaltyProgram(
        userId: _loyaltyProgram!.userId,
        totalPoints: _loyaltyProgram!.totalPoints,
        currentPoints: _loyaltyProgram!.currentPoints,
        tier: newTier,
        loginStreak: _loyaltyProgram!.loginStreak,
        lastLoginDate: _loyaltyProgram!.lastLoginDate,
        totalSpent: _loyaltyProgram!.totalSpent,
        totalOrders: _loyaltyProgram!.totalOrders,
        transactions: _loyaltyProgram!.transactions,
        vouchers: _loyaltyProgram!.vouchers,
        joinedAt: _loyaltyProgram!.joinedAt,
      );

      // Send tier upgrade notification
      _notificationService?.sendLoyaltyPointsNotification(
        0,
        newTier.displayName,
      );
    }
  }


  Future<List<Voucher>> getAvailableVouchers() async {
    try {
      final response = await ApiService.getAvailableVouchers();
      if (response['success'] == true && response['data'] != null) {
        final vouchersData = response['data'] as List;
        return vouchersData.map((data) => Voucher.fromJson(data)).toList();
      }
    } catch (e) {
      debugPrint('Error getting available vouchers from API: $e');
    }
    
    // Fallback to mock vouchers
    return [
      Voucher(
        id: '1',
        code: 'LOYALTY10',
        title: '10% Off Your Next Order',
        description: 'Get 10% off on your next purchase',
        type: VoucherType.percentage,
        value: 10,
        pointsCost: 100,
        validUntil: DateTime.now().add(const Duration(days: 30)),
      ),
      Voucher(
        id: '2',
        code: 'LOYALTY20',
        title: '\$20 Off',
        description: 'Get \$20 off on orders above \$100',
        type: VoucherType.fixed,
        value: 20,
        pointsCost: 200,
        validUntil: DateTime.now().add(const Duration(days: 30)),
        minimumPurchase: 100,
      ),
      Voucher(
        id: '3',
        code: 'FREESHIP',
        title: 'Free Shipping',
        description: 'Free shipping on your next order',
        type: VoucherType.freeShipping,
        value: 0,
        pointsCost: 50,
        validUntil: DateTime.now().add(const Duration(days: 30)),
      ),
      Voucher(
        id: '4',
        code: 'LOYALTY50',
        title: '\$50 Off',
        description: 'Get \$50 off on orders above \$200',
        type: VoucherType.fixed,
        value: 50,
        pointsCost: 500,
        validUntil: DateTime.now().add(const Duration(days: 30)),
        minimumPurchase: 200,
      ),
    ];
  }
}