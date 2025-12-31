class LoyaltyProgram {
  final String userId;
  final int totalCredits;
  final int availableCredits;
  final LoyaltyTier tier;
  final int loginStreak;
  final DateTime? lastLoginDate;
  final double totalSpent;
  final int totalOrders;
  final DateTime joinedAt;

  LoyaltyProgram({
    required this.userId,
    required this.totalCredits,
    required this.availableCredits,
    required this.tier,
    required this.loginStreak,
    this.lastLoginDate,
    required this.totalSpent,
    required this.totalOrders,
    required this.joinedAt,
  });

  // Calculate spending to next tier
  double get spendingToNextTier {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 1000 - totalSpent;
      case LoyaltyTier.silver:
        return 5000 - totalSpent;
      case LoyaltyTier.gold:
        return 10000 - totalSpent;
      case LoyaltyTier.platinum:
        return 0; // Already at max tier
    }
  }

  // Calculate tier progress percentage
  double get tierProgress {
    switch (tier) {
      case LoyaltyTier.bronze:
        return (totalSpent / 1000).clamp(0.0, 1.0);
      case LoyaltyTier.silver:
        return ((totalSpent - 1000) / 4000).clamp(0.0, 1.0);
      case LoyaltyTier.gold:
        return ((totalSpent - 5000) / 5000).clamp(0.0, 1.0);
      case LoyaltyTier.platinum:
        return 1.0;
    }
  }

  // Check if eligible for streak bonus
  bool get isStreakActive {
    if (lastLoginDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastLoginDate!).inDays;
    return difference <= 1;
  }

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) {
    return LoyaltyProgram(
      userId: json['userId'],
      totalCredits: json['totalCredits'] ?? 0,
      availableCredits: json['availableCredits'] ?? 0,
      tier: LoyaltyTier.values.firstWhere(
        (t) => t.toString() == 'LoyaltyTier.${json['tier']}',
        orElse: () => LoyaltyTier.bronze,
      ),
      loginStreak: json['loginStreak'] ?? 0,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'])
          : null,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalCredits': totalCredits,
      'availableCredits': availableCredits,
      'tier': tier.toString().split('.').last,
      'loginStreak': loginStreak,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

enum LoyaltyTier {
  bronze,
  silver,
  gold,
  platinum,
}

extension LoyaltyTierExtension on LoyaltyTier {
  String get displayName {
    switch (this) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Silver';
      case LoyaltyTier.gold:
        return 'Gold';
      case LoyaltyTier.platinum:
        return 'Platinum';
    }
  }

  String get icon {
    switch (this) {
      case LoyaltyTier.bronze:
        return '🥉';
      case LoyaltyTier.silver:
        return '🥈';
      case LoyaltyTier.gold:
        return '🥇';
      case LoyaltyTier.platinum:
        return '💎';
    }
  }

  double get creditsMultiplier {
    switch (this) {
      case LoyaltyTier.bronze:
        return 1.0;
      case LoyaltyTier.silver:
        return 1.5;
      case LoyaltyTier.gold:
        return 2.0;
      case LoyaltyTier.platinum:
        return 2.5;
    }
  }

  double get spendingRequired {
    switch (this) {
      case LoyaltyTier.bronze:
        return 0;
      case LoyaltyTier.silver:
        return 1000;
      case LoyaltyTier.gold:
        return 5000;
      case LoyaltyTier.platinum:
        return 10000;
    }
  }

  List<String> get benefits {
    switch (this) {
      case LoyaltyTier.bronze:
        return [
          'Earn 1 credit per \$1 spent',
          'Login streak bonuses',
          'Early access to sales',
        ];
      case LoyaltyTier.silver:
        return [
          'Earn 1.5 credits per \$1 spent',
          'Free shipping on orders over \$50',
          'Exclusive member discounts',
          'Enhanced login bonuses',
        ];
      case LoyaltyTier.gold:
        return [
          'Earn 2 credits per \$1 spent',
          'Free shipping on all orders',
          'Priority customer service',
          'Exclusive gold member sales',
          'Double login bonuses',
        ];
      case LoyaltyTier.platinum:
        return [
          'Earn 2.5 credits per \$1 spent',
          'Free express shipping',
          'VIP customer service',
          'Exclusive platinum previews',
          'Personal shopping assistant',
          'Triple login bonuses',
        ];
    }
  }
}

class CreditTransaction {
  final String id;
  final String userId;
  final TransactionType type;
  final int credits;
  final String description;
  final DateTime createdAt;
  final String? orderId;
  final String? voucherId;

  CreditTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.credits,
    required this.description,
    required this.createdAt,
    this.orderId,
    this.voucherId,
  });

  bool get isPositive => credits > 0;

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (t) => t.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.earned,
      ),
      credits: json['credits'] ?? 0,
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      orderId: json['orderId'],
      voucherId: json['voucherId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'credits': credits,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      if (orderId != null) 'orderId': orderId,
      if (voucherId != null) 'voucherId': voucherId,
    };
  }
}

enum TransactionType {
  earned,
  redeemed,
  loginBonus,
  streakBonus,
  welcomeBonus,
  expired,
  refund,
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.earned:
        return 'Earned';
      case TransactionType.redeemed:
        return 'Redeemed';
      case TransactionType.loginBonus:
        return 'Login Bonus';
      case TransactionType.streakBonus:
        return 'Streak Bonus';
      case TransactionType.welcomeBonus:
        return 'Welcome Bonus';
      case TransactionType.expired:
        return 'Expired';
      case TransactionType.refund:
        return 'Refund';
    }
  }
}

class RedemptionOption {
  final String id;
  final String name;
  final String description;
  final int creditsRequired;
  final double discountValue;
  final RedemptionType type;

  RedemptionOption({
    required this.id,
    required this.name,
    required this.description,
    required this.creditsRequired,
    required this.discountValue,
    required this.type,
  });

  factory RedemptionOption.fromJson(Map<String, dynamic> json) {
    return RedemptionOption(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      creditsRequired: json['creditsRequired'] ?? 0,
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      type: RedemptionType.values.firstWhere(
        (t) => t.toString() == 'RedemptionType.${json['type']}',
        orElse: () => RedemptionType.discount,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creditsRequired': creditsRequired,
      'discountValue': discountValue,
      'type': type.toString().split('.').last,
    };
  }
}

enum RedemptionType {
  discount,
  voucher,
  freeShipping,
}

extension RedemptionTypeExtension on RedemptionType {
  String get displayName {
    switch (this) {
      case RedemptionType.discount:
        return 'Discount';
      case RedemptionType.voucher:
        return 'Voucher';
      case RedemptionType.freeShipping:
        return 'Free Shipping';
    }
  }
}

class TierInfo {
  final String name;
  final String icon;
  final double spendingRequired;
  final double creditsMultiplier;
  final List<String> benefits;

  TierInfo({
    required this.name,
    required this.icon,
    required this.spendingRequired,
    required this.creditsMultiplier,
    required this.benefits,
  });

  factory TierInfo.fromJson(Map<String, dynamic> json) {
    return TierInfo(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      spendingRequired: (json['spendingRequired'] ?? 0).toDouble(),
      creditsMultiplier: (json['creditsMultiplier'] ?? 1.0).toDouble(),
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((b) => b.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'spendingRequired': spendingRequired,
      'creditsMultiplier': creditsMultiplier,
      'benefits': benefits,
    };
  }
}