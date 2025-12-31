class EventPromotion {
  final String id;
  final String eventId;
  final String eventName;
  final String title;
  final String description;
  final String discountType; // 'percentage', 'fixed', 'bogo'
  final double discountValue;
  final double? minPurchase;
  final double? maxDiscount;
  final String applicableTo; // 'all', 'category', 'product'
  final List<String> categories;
  final List<String> productIds;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool showAsPopup;
  final String? popupImageUrl;
  final String popupFrequency; // 'once', 'daily', 'session'
  final DateTime createdAt;
  final DateTime updatedAt;

  EventPromotion({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minPurchase,
    this.maxDiscount,
    required this.applicableTo,
    this.categories = const [],
    this.productIds = const [],
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.showAsPopup = false,
    this.popupImageUrl,
    this.popupFrequency = 'once',
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventPromotion.fromJson(Map<String, dynamic> json) {
    return EventPromotion(
      id: json['id'] ?? json['_id'] ?? '',
      eventId: json['eventId'] ?? '',
      eventName: json['eventName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minPurchase: json['minPurchase']?.toDouble(),
      maxDiscount: json['maxDiscount']?.toDouble(),
      applicableTo: json['applicableTo'] ?? 'all',
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : [],
      productIds: json['productIds'] != null
          ? List<String>.from(json['productIds'])
          : [],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now().add(const Duration(days: 7)),
      isActive: json['isActive'] ?? false,
      showAsPopup: json['showAsPopup'] ?? false,
      popupImageUrl: json['popupImageUrl'],
      popupFrequency: json['popupFrequency'] ?? 'once',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'title': title,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'minPurchase': minPurchase,
      'maxDiscount': maxDiscount,
      'applicableTo': applicableTo,
      'categories': categories,
      'productIds': productIds,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'showAsPopup': showAsPopup,
      'popupImageUrl': popupImageUrl,
      'popupFrequency': popupFrequency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isLive {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }

  double calculateDiscount(double price) {
    if (!isLive) return 0;

    double discount = 0;
    switch (discountType) {
      case 'percentage':
        discount = price * (discountValue / 100);
        break;
      case 'fixed':
        discount = discountValue;
        break;
      case 'bogo':
        discount = price * 0.5;
        break;
    }

    // Apply max discount cap if set
    if (maxDiscount != null && discount > maxDiscount!) {
      discount = maxDiscount!;
    }

    return discount;
  }

  String get discountText {
    switch (discountType) {
      case 'percentage':
        return '${discountValue.toInt()}% OFF';
      case 'fixed':
        return '₹${discountValue.toInt()} OFF';
      case 'bogo':
        return 'BOGO';
      default:
        return 'SALE';
    }
  }
}

