import 'cart.dart';
import 'user.dart';

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final Address shippingAddress;
  final String paymentMethod;
  final OrderStatus status;
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? trackingNumber;
  final DateTime? processedAt;
  final DateTime? shippedAt;
  final String? cancellationReason;
  final String? returnReason;
  final String? refundStatus;
  final double? refundAmount;
  final DateTime? refundedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.createdAt,
    this.deliveredAt,
    this.trackingNumber,
    this.processedAt,
    this.shippedAt,
    this.cancellationReason,
    this.returnReason,
    this.refundStatus,
    this.refundAmount,
    this.refundedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? json['_id'],
      userId: json['userId'] ?? '',
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      shippingAddress: Address.fromJson(json['shippingAddress']),
      paymentMethod: json['paymentMethod'] ?? 'cod',
      status: _parseOrderStatus(json['status']),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      shipping: (json['shipping'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      trackingNumber: json['trackingNumber'],
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
      shippedAt: json['shippedAt'] != null
          ? DateTime.parse(json['shippedAt'])
          : null,
      cancellationReason: json['cancellationReason'],
      returnReason: json['returnReason'],
      refundStatus: json['refundStatus'],
      refundAmount: json['refundAmount']?.toDouble(),
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'])
          : null,
    );
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return OrderStatus.placed;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'returned':
        return OrderStatus.returned;
      default:
        return OrderStatus.placed;
    }
  }
}

enum OrderStatus {
  placed,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  returnRequested,
  returned,
  refunded,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returnRequested:
        return 'Return Requested';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  bool get canCancel {
    return this == OrderStatus.placed || this == OrderStatus.confirmed;
  }

  bool get canReturn {
    return this == OrderStatus.delivered;
  }

  bool get canTrack {
    return this == OrderStatus.shipped ||
           this == OrderStatus.outForDelivery ||
           this == OrderStatus.delivered;
  }
}