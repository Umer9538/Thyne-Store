import 'user.dart';

/// Custom order for AI-generated jewelry designs
class CustomOrder {
  final String id;
  final String? userId;
  final String? guestSessionId;
  final CustomerInfo customerInfo;
  final DesignInfo designInfo;
  final PriceInfo? priceInfo;
  final CustomOrderStatus status;
  final DateTime createdAt;
  final DateTime? contactedAt;
  final DateTime? confirmedAt;
  final DateTime? processedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? adminNotes;
  final String? customerNotes;
  final String? trackingNumber;
  final String? cancellationReason;

  CustomOrder({
    required this.id,
    this.userId,
    this.guestSessionId,
    required this.customerInfo,
    required this.designInfo,
    this.priceInfo,
    required this.status,
    required this.createdAt,
    this.contactedAt,
    this.confirmedAt,
    this.processedAt,
    this.shippedAt,
    this.deliveredAt,
    this.adminNotes,
    this.customerNotes,
    this.trackingNumber,
    this.cancellationReason,
  });

  factory CustomOrder.fromJson(Map<String, dynamic> json) {
    return CustomOrder(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      guestSessionId: json['guestSessionId']?.toString(),
      customerInfo: CustomerInfo.fromJson(json['customerInfo'] ?? {}),
      designInfo: DesignInfo.fromJson(json['designInfo'] ?? {}),
      priceInfo: json['priceInfo'] != null
          ? PriceInfo.fromJson(json['priceInfo'])
          : null,
      status: CustomOrderStatus.fromString(json['status']?.toString()),
      createdAt: _parseDateTime(json['createdAt']),
      contactedAt: json['contactedAt'] != null
          ? _parseDateTime(json['contactedAt'])
          : null,
      confirmedAt: json['confirmedAt'] != null
          ? _parseDateTime(json['confirmedAt'])
          : null,
      processedAt: json['processedAt'] != null
          ? _parseDateTime(json['processedAt'])
          : null,
      shippedAt: json['shippedAt'] != null
          ? _parseDateTime(json['shippedAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? _parseDateTime(json['deliveredAt'])
          : null,
      adminNotes: json['adminNotes']?.toString(),
      customerNotes: json['customerNotes']?.toString(),
      trackingNumber: json['trackingNumber']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      if (guestSessionId != null) 'guestSessionId': guestSessionId,
      'customerInfo': customerInfo.toJson(),
      'designInfo': designInfo.toJson(),
      if (priceInfo != null) 'priceInfo': priceInfo!.toJson(),
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      if (contactedAt != null) 'contactedAt': contactedAt!.toIso8601String(),
      if (confirmedAt != null) 'confirmedAt': confirmedAt!.toIso8601String(),
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
      if (shippedAt != null) 'shippedAt': shippedAt!.toIso8601String(),
      if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (customerNotes != null) 'customerNotes': customerNotes,
      if (trackingNumber != null) 'trackingNumber': trackingNumber,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
    };
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is Map && dateValue['\$date'] != null) {
      return DateTime.parse(dateValue['\$date']);
    }
    if (dateValue is String) {
      return DateTime.parse(dateValue);
    }
    return DateTime.now();
  }

  CustomOrder copyWith({
    String? id,
    String? userId,
    String? guestSessionId,
    CustomerInfo? customerInfo,
    DesignInfo? designInfo,
    PriceInfo? priceInfo,
    CustomOrderStatus? status,
    DateTime? createdAt,
    DateTime? contactedAt,
    DateTime? confirmedAt,
    DateTime? processedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? adminNotes,
    String? customerNotes,
    String? trackingNumber,
    String? cancellationReason,
  }) {
    return CustomOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      guestSessionId: guestSessionId ?? this.guestSessionId,
      customerInfo: customerInfo ?? this.customerInfo,
      designInfo: designInfo ?? this.designInfo,
      priceInfo: priceInfo ?? this.priceInfo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      contactedAt: contactedAt ?? this.contactedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      processedAt: processedAt ?? this.processedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      adminNotes: adminNotes ?? this.adminNotes,
      customerNotes: customerNotes ?? this.customerNotes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

/// Customer information for custom order
class CustomerInfo {
  final String name;
  final String phone;
  final String? email;
  final Address? shippingAddress;

  CustomerInfo({
    required this.name,
    required this.phone,
    this.email,
    this.shippingAddress,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      shippingAddress: json['shippingAddress'] != null
          ? Address.fromJson(json['shippingAddress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (shippingAddress != null) 'shippingAddress': shippingAddress!.toJson(),
    };
  }
}

/// Design information for custom order
class DesignInfo {
  final String prompt;
  final String? imageUrl;
  final String? imageDescription;
  final String? jewelryType;
  final String? metalType;
  final String? conversationId;
  final Map<String, dynamic>? metadata;

  DesignInfo({
    required this.prompt,
    this.imageUrl,
    this.imageDescription,
    this.jewelryType,
    this.metalType,
    this.conversationId,
    this.metadata,
  });

  factory DesignInfo.fromJson(Map<String, dynamic> json) {
    return DesignInfo(
      prompt: json['prompt']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      imageDescription: json['imageDescription']?.toString(),
      jewelryType: json['jewelryType']?.toString(),
      metalType: json['metalType']?.toString(),
      conversationId: json['conversationId']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageDescription != null) 'imageDescription': imageDescription,
      if (jewelryType != null) 'jewelryType': jewelryType,
      if (metalType != null) 'metalType': metalType,
      if (conversationId != null) 'conversationId': conversationId,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Price information for custom order
class PriceInfo {
  final double? estimatedMin;
  final double? estimatedMax;
  final double? confirmedPrice;
  final String? priceBreakdown;
  final String currency;

  PriceInfo({
    this.estimatedMin,
    this.estimatedMax,
    this.confirmedPrice,
    this.priceBreakdown,
    this.currency = 'INR',
  });

  factory PriceInfo.fromJson(Map<String, dynamic> json) {
    return PriceInfo(
      estimatedMin: (json['estimatedMin'] as num?)?.toDouble(),
      estimatedMax: (json['estimatedMax'] as num?)?.toDouble(),
      confirmedPrice: (json['confirmedPrice'] as num?)?.toDouble(),
      priceBreakdown: json['priceBreakdown']?.toString(),
      currency: json['currency']?.toString() ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (estimatedMin != null) 'estimatedMin': estimatedMin,
      if (estimatedMax != null) 'estimatedMax': estimatedMax,
      if (confirmedPrice != null) 'confirmedPrice': confirmedPrice,
      if (priceBreakdown != null) 'priceBreakdown': priceBreakdown,
      'currency': currency,
    };
  }

  String get estimatedRange {
    if (estimatedMin != null && estimatedMax != null) {
      return '₹${_formatPrice(estimatedMin!)} - ₹${_formatPrice(estimatedMax!)}';
    }
    return 'Price TBD';
  }

  String get confirmedPriceFormatted {
    if (confirmedPrice != null) {
      return '₹${_formatPrice(confirmedPrice!)}';
    }
    return estimatedRange;
  }

  String _formatPrice(double price) {
    if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(1)}L';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    }
    return price.toStringAsFixed(0);
  }
}

/// Status enum for custom orders
enum CustomOrderStatus {
  pendingContact('pending_contact'),
  contacted('contacted'),
  confirmed('confirmed'),
  processing('processing'),
  shipped('shipped'),
  delivered('delivered'),
  cancelled('cancelled');

  final String value;
  const CustomOrderStatus(this.value);

  static CustomOrderStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending_contact':
        return CustomOrderStatus.pendingContact;
      case 'contacted':
        return CustomOrderStatus.contacted;
      case 'confirmed':
        return CustomOrderStatus.confirmed;
      case 'processing':
        return CustomOrderStatus.processing;
      case 'shipped':
        return CustomOrderStatus.shipped;
      case 'delivered':
        return CustomOrderStatus.delivered;
      case 'cancelled':
        return CustomOrderStatus.cancelled;
      default:
        return CustomOrderStatus.pendingContact;
    }
  }

  String get displayName {
    switch (this) {
      case CustomOrderStatus.pendingContact:
        return 'Pending Contact';
      case CustomOrderStatus.contacted:
        return 'Contacted';
      case CustomOrderStatus.confirmed:
        return 'Confirmed';
      case CustomOrderStatus.processing:
        return 'Processing';
      case CustomOrderStatus.shipped:
        return 'Shipped';
      case CustomOrderStatus.delivered:
        return 'Delivered';
      case CustomOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case CustomOrderStatus.pendingContact:
        return 'Waiting for team to contact customer';
      case CustomOrderStatus.contacted:
        return 'Team has contacted the customer';
      case CustomOrderStatus.confirmed:
        return 'Order confirmed after discussion';
      case CustomOrderStatus.processing:
        return 'Jewelry is being crafted';
      case CustomOrderStatus.shipped:
        return 'Order has been shipped';
      case CustomOrderStatus.delivered:
        return 'Order has been delivered';
      case CustomOrderStatus.cancelled:
        return 'Order has been cancelled';
    }
  }

  bool get canContact => this == CustomOrderStatus.pendingContact;
  bool get canConfirm => this == CustomOrderStatus.contacted;
  bool get canProcess => this == CustomOrderStatus.confirmed;
  bool get canShip => this == CustomOrderStatus.processing;
  bool get canDeliver => this == CustomOrderStatus.shipped;
  bool get canCancel =>
      this == CustomOrderStatus.pendingContact ||
      this == CustomOrderStatus.contacted ||
      this == CustomOrderStatus.confirmed;
}
