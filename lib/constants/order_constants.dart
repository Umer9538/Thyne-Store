import 'package:flutter/material.dart';

/// Order status filter options (includes 'all')
class OrderFilters {
  OrderFilters._();

  static const String all = 'all';
  static const String placed = 'placed';
  static const String confirmed = 'confirmed';
  static const String processing = 'processing';
  static const String shipped = 'shipped';
  static const String outForDelivery = 'out_for_delivery';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
  static const String returned = 'returned';

  /// All filter options for order history
  static const List<String> historyFilters = [
    all,
    placed,
    confirmed,
    processing,
    shipped,
    delivered,
    cancelled,
  ];

  /// Get display name for filter
  static String getDisplayName(String filter) {
    switch (filter) {
      case all:
        return 'All';
      case placed:
        return 'Placed';
      case confirmed:
        return 'Confirmed';
      case processing:
        return 'Processing';
      case shipped:
        return 'Shipped';
      case outForDelivery:
        return 'Out for Delivery';
      case delivered:
        return 'Delivered';
      case cancelled:
        return 'Cancelled';
      case returned:
        return 'Returned';
      default:
        return filter;
    }
  }
}

/// Order status colors mapping
class OrderStatusColors {
  OrderStatusColors._();

  static const Color placed = Colors.blue;
  static const Color confirmed = Colors.indigo;
  static const Color processing = Colors.orange;
  static const Color shipped = Colors.purple;
  static const Color outForDelivery = Colors.deepPurple;
  static const Color delivered = Colors.green;
  static const Color cancelled = Colors.red;
  static const Color returnRequested = Colors.orange;
  static const Color returned = Colors.orange;
  static const Color refunded = Colors.grey;

  /// Get color for status string
  static Color fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
      case 'pending':
        return placed;
      case 'confirmed':
        return confirmed;
      case 'processing':
        return processing;
      case 'shipped':
        return shipped;
      case 'out_for_delivery':
        return outForDelivery;
      case 'delivered':
        return delivered;
      case 'cancelled':
        return cancelled;
      case 'return_requested':
        return returnRequested;
      case 'returned':
        return returned;
      case 'refunded':
        return refunded;
      default:
        return Colors.grey;
    }
  }
}

/// Payment methods
enum PaymentMethod {
  cod('cod', 'Cash on Delivery', Icons.money),
  card('card', 'Credit/Debit Card', Icons.credit_card),
  upi('upi', 'UPI', Icons.account_balance),
  netBanking('netbanking', 'Net Banking', Icons.account_balance_wallet),
  wallet('wallet', 'Wallet', Icons.wallet);

  final String value;
  final String displayName;
  final IconData icon;

  const PaymentMethod(this.value, this.displayName, this.icon);

  static PaymentMethod fromValue(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value.toLowerCase(),
      orElse: () => PaymentMethod.cod,
    );
  }

  static List<PaymentMethod> get available => PaymentMethod.values;
}

/// Refund status options
class RefundStatus {
  RefundStatus._();

  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String completed = 'completed';
  static const String failed = 'failed';

  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Refund Pending';
      case processing:
        return 'Refund Processing';
      case completed:
        return 'Refund Completed';
      case failed:
        return 'Refund Failed';
      default:
        return status;
    }
  }

  static Color getColor(String status) {
    switch (status) {
      case pending:
        return Colors.orange;
      case processing:
        return Colors.blue;
      case completed:
        return Colors.green;
      case failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
