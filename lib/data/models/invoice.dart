class Invoice {
  final String id;
  final String invoiceNumber;
  final String orderId;
  final String? userId;
  final String? guestSessionId;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final InvoiceStatus status;
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;
  final String currency;
  final String? notes;
  final String? pdfUrl;
  final bool isDownloaded;
  final DateTime? downloadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    this.userId,
    this.guestSessionId,
    required this.invoiceDate,
    this.dueDate,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.currency,
    this.notes,
    this.pdfUrl,
    required this.isDownloaded,
    this.downloadedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB ObjectId format
    String invoiceId;
    if (json['_id'] != null) {
      if (json['_id'] is Map && json['_id']['\$oid'] != null) {
        invoiceId = json['_id']['\$oid'];
      } else {
        invoiceId = json['_id'].toString();
      }
    } else {
      invoiceId = json['id']?.toString() ?? '';
    }

    return Invoice(
      id: invoiceId,
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      userId: json['userId']?.toString(),
      guestSessionId: json['guestSessionId']?.toString(),
      invoiceDate: _parseDateTime(json['invoiceDate']),
      dueDate: json['dueDate'] != null ? _parseDateTime(json['dueDate']) : null,
      status: _parseInvoiceStatus(json['status']),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      shipping: (json['shipping'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      notes: json['notes'],
      pdfUrl: json['pdfUrl'],
      isDownloaded: json['isDownloaded'] ?? false,
      downloadedAt: json['downloadedAt'] != null ? _parseDateTime(json['downloadedAt']) : null,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'orderId': orderId,
      'userId': userId,
      'guestSessionId': guestSessionId,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'status': status.value,
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'currency': currency,
      'notes': notes,
      'pdfUrl': pdfUrl,
      'isDownloaded': isDownloaded,
      'downloadedAt': downloadedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    // Handle MongoDB date format: {"$date": "2025-09-23T15:00:18.013Z"}
    if (dateValue is Map && dateValue['\$date'] != null) {
      return DateTime.parse(dateValue['\$date']);
    }

    // Handle regular string format
    if (dateValue is String) {
      return DateTime.parse(dateValue);
    }

    // Fallback
    return DateTime.now();
  }

  static InvoiceStatus _parseInvoiceStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return InvoiceStatus.draft;
      case 'issued':
        return InvoiceStatus.issued;
      case 'paid':
        return InvoiceStatus.paid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      case 'refunded':
        return InvoiceStatus.refunded;
      default:
        return InvoiceStatus.issued;
    }
  }
}

enum InvoiceStatus {
  draft,
  issued,
  paid,
  overdue,
  cancelled,
  refunded,
}

extension InvoiceStatusExtension on InvoiceStatus {
  String get value {
    switch (this) {
      case InvoiceStatus.draft:
        return 'draft';
      case InvoiceStatus.issued:
        return 'issued';
      case InvoiceStatus.paid:
        return 'paid';
      case InvoiceStatus.overdue:
        return 'overdue';
      case InvoiceStatus.cancelled:
        return 'cancelled';
      case InvoiceStatus.refunded:
        return 'refunded';
    }
  }

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.issued:
        return 'Issued';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
      case InvoiceStatus.refunded:
        return 'Refunded';
    }
  }
}
