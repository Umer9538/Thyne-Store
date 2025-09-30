class LoyaltyProgram {
  final String userId;
  final int totalPoints;
  final int currentPoints;
  final LoyaltyTier tier;
  final int loginStreak;
  final DateTime? lastLoginDate;
  final double totalSpent;
  final int totalOrders;
  final List<PointTransaction> transactions;
  final List<Voucher> vouchers;
  final DateTime joinedAt;

  LoyaltyProgram({
    required this.userId,
    required this.totalPoints,
    required this.currentPoints,
    required this.tier,
    required this.loginStreak,
    this.lastLoginDate,
    required this.totalSpent,
    required this.totalOrders,
    this.transactions = const [],
    this.vouchers = const [],
    required this.joinedAt,
  });

  // Calculate points to next tier
  int get pointsToNextTier {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 500 - totalPoints;
      case LoyaltyTier.silver:
        return 2000 - totalPoints;
      case LoyaltyTier.gold:
        return 5000 - totalPoints;
      case LoyaltyTier.platinum:
        return 0; // Already at max tier
    }
  }

  // Calculate tier progress percentage
  double get tierProgress {
    switch (tier) {
      case LoyaltyTier.bronze:
        return totalPoints / 500;
      case LoyaltyTier.silver:
        return (totalPoints - 500) / 1500;
      case LoyaltyTier.gold:
        return (totalPoints - 2000) / 3000;
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
      totalPoints: json['totalPoints'],
      currentPoints: json['currentPoints'],
      tier: LoyaltyTier.values.firstWhere(
        (t) => t.toString() == 'LoyaltyTier.${json['tier']}',
      ),
      loginStreak: json['loginStreak'],
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'])
          : null,
      totalSpent: json['totalSpent'].toDouble(),
      totalOrders: json['totalOrders'],
      transactions: (json['transactions'] as List?)
          ?.map((t) => PointTransaction.fromJson(t))
          .toList() ?? [],
      vouchers: (json['vouchers'] as List?)
          ?.map((v) => Voucher.fromJson(v))
          .toList() ?? [],
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'currentPoints': currentPoints,
      'tier': tier.toString().split('.').last,
      'loginStreak': loginStreak,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'vouchers': vouchers.map((v) => v.toJson()).toList(),
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

  double get pointsMultiplier {
    switch (this) {
      case LoyaltyTier.bronze:
        return 1.0;
      case LoyaltyTier.silver:
        return 1.2;
      case LoyaltyTier.gold:
        return 1.5;
      case LoyaltyTier.platinum:
        return 2.0;
    }
  }

  List<String> get benefits {
    switch (this) {
      case LoyaltyTier.bronze:
        return [
          'Earn 1 point per \$1 spent',
          'Birthday bonus points',
          'Early access to sales',
        ];
      case LoyaltyTier.silver:
        return [
          'Earn 1.2 points per \$1 spent',
          'Free shipping on orders over \$50',
          'Exclusive member discounts',
          'Birthday bonus points',
        ];
      case LoyaltyTier.gold:
        return [
          'Earn 1.5 points per \$1 spent',
          'Free shipping on all orders',
          'Priority customer service',
          'Exclusive gold member sales',
          'Birthday bonus points',
        ];
      case LoyaltyTier.platinum:
        return [
          'Earn 2 points per \$1 spent',
          'Free express shipping',
          'VIP customer service',
          'Exclusive platinum previews',
          'Personal shopping assistant',
          'Birthday bonus points',
        ];
    }
  }
}

class PointTransaction {
  final String id;
  final TransactionType type;
  final int points;
  final String description;
  final DateTime createdAt;
  final String? orderId;

  PointTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    required this.createdAt,
    this.orderId,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'],
      type: TransactionType.values.firstWhere(
        (t) => t.toString() == 'TransactionType.${json['type']}',
      ),
      points: json['points'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      orderId: json['orderId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'points': points,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'orderId': orderId,
    };
  }
}

enum TransactionType {
  earned,
  redeemed,
  bonus,
  expired,
}

class Voucher {
  final String id;
  final String code;
  final String title;
  final String description;
  final VoucherType type;
  final double value;
  final int pointsCost;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isUsed;
  final DateTime? usedAt;
  final double? minimumPurchase;

  Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.pointsCost,
    this.validFrom,
    this.validUntil,
    this.isUsed = false,
    this.usedAt,
    this.minimumPurchase,
  });

  bool get isValid {
    final now = DateTime.now();
    if (isUsed) return false;
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      description: json['description'],
      type: VoucherType.values.firstWhere(
        (t) => t.toString() == 'VoucherType.${json['type']}',
      ),
      value: json['value'].toDouble(),
      pointsCost: json['pointsCost'],
      validFrom: json['validFrom'] != null
          ? DateTime.parse(json['validFrom'])
          : null,
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : null,
      isUsed: json['isUsed'] ?? false,
      usedAt: json['usedAt'] != null
          ? DateTime.parse(json['usedAt'])
          : null,
      minimumPurchase: json['minimumPurchase']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'value': value,
      'pointsCost': pointsCost,
      'validFrom': validFrom?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'isUsed': isUsed,
      'usedAt': usedAt?.toIso8601String(),
      'minimumPurchase': minimumPurchase,
    };
  }
}

enum VoucherType {
  percentage,
  fixed,
  freeShipping,
  gift,
}