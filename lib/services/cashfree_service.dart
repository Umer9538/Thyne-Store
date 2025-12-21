import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class CashfreeService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Callback functions
  Function(String orderId)? onPaymentSuccess;
  Function(CFErrorResponse error, String orderId)? onPaymentFailure;

  // Singleton instance
  static final CashfreeService _instance = CashfreeService._internal();
  factory CashfreeService() => _instance;
  CashfreeService._internal();

  // Get auth token
  static Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Get guest session ID
  static Future<String?> _getGuestSessionId() async {
    return await _storage.read(key: 'guest_session_id');
  }

  // Common headers
  static Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final guestSessionId = await _getGuestSessionId();
    if (guestSessionId != null) {
      headers['X-Guest-Session-ID'] = guestSessionId;
    }

    return headers;
  }

  /// Create a payment order on the backend
  Future<CashfreeOrderResponse?> createPaymentOrder({
    required String orderId,
    required double amount,
    required String customerPhone,
    String? customerEmail,
    String? customerName,
    String? returnUrl,
    String currency = 'INR',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/cashfree/create-order'),
        headers: await _getHeaders(),
        body: json.encode({
          'orderId': orderId,
          'amount': amount,
          'currency': currency,
          'customerPhone': customerPhone,
          'customerEmail': customerEmail,
          'customerName': customerName,
          'returnUrl': returnUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CashfreeOrderResponse.fromJson(data['data']);
        }
      }

      print('❌ Failed to create Cashfree order: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Error creating Cashfree order: $e');
      return null;
    }
  }

  /// Start Cashfree payment flow
  Future<void> startPayment({
    required BuildContext context,
    required String orderId,
    required String paymentSessionId,
    required CFEnvironment environment,
    Function(String orderId)? onSuccess,
    Function(CFErrorResponse error, String orderId)? onFailure,
  }) async {
    try {
      // Store callbacks
      onPaymentSuccess = onSuccess;
      onPaymentFailure = onFailure;

      // Create session
      final session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();

      // Create web checkout payment
      final cfWebCheckout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      // Set payment callback
      final cfPaymentGateway = CFPaymentGatewayService();
      cfPaymentGateway.setCallback((String orderIdCallback) {
        print('✅ Cashfree payment successful for order: $orderIdCallback');
        onPaymentSuccess?.call(orderIdCallback);
      }, (CFErrorResponse error, String orderIdCallback) {
        print('❌ Cashfree payment failed: ${error.getMessage()}');
        onPaymentFailure?.call(error, orderIdCallback);
      });

      // Start payment
      cfPaymentGateway.doPayment(cfWebCheckout);
    } catch (e) {
      print('❌ Error starting Cashfree payment: $e');
      onPaymentFailure?.call(
        CFErrorResponse('INIT_ERROR', e.toString(), 'payment', ''),
        orderId,
      );
    }
  }

  /// Start payment in external browser (bypasses SDK trust check)
  /// Use this for development/testing when app is not installed from Play Store
  Future<bool> startPaymentInBrowser({
    required String paymentSessionId,
    required CFEnvironment environment,
  }) async {
    try {
      // Construct the Cashfree payment URL
      final baseUrl = environment == CFEnvironment.PRODUCTION
          ? 'https://payments.cashfree.com/order'
          : 'https://payments-test.cashfree.com/order';

      final paymentUrl = Uri.parse('$baseUrl/#$paymentSessionId');

      print('🌐 Opening Cashfree payment in browser: $paymentUrl');

      if (await canLaunchUrl(paymentUrl)) {
        await launchUrl(
          paymentUrl,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        print('❌ Could not launch payment URL');
        return false;
      }
    } catch (e) {
      print('❌ Error launching payment URL: $e');
      return false;
    }
  }

  /// Verify payment on backend
  Future<CashfreeVerifyResponse?> verifyPayment(String orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/cashfree/verify'),
        headers: await _getHeaders(),
        body: json.encode({'orderId': orderId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CashfreeVerifyResponse.fromJson(data);
      }

      print('❌ Failed to verify Cashfree payment: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Error verifying Cashfree payment: $e');
      return null;
    }
  }

  /// Get payment status
  Future<CashfreeStatusResponse?> getPaymentStatus(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/cashfree/status/$orderId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CashfreeStatusResponse.fromJson(data['data']);
        }
      }

      print('❌ Failed to get Cashfree payment status: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Error getting Cashfree payment status: $e');
      return null;
    }
  }

  /// Check if Cashfree service is enabled
  Future<bool> isServiceEnabled() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/cashfree/status'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['enabled'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Error checking Cashfree service status: $e');
      return false;
    }
  }

  /// Get the appropriate environment based on backend config
  Future<CFEnvironment> getEnvironment() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/cashfree/status'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final env = data['data']?['environment']?.toString().toUpperCase();
        if (env == 'PRODUCTION') {
          return CFEnvironment.PRODUCTION;
        }
      }
      return CFEnvironment.SANDBOX;
    } catch (e) {
      print('❌ Error getting Cashfree environment: $e');
      return CFEnvironment.SANDBOX;
    }
  }
}

// Response Models

class CashfreeOrderResponse {
  final String? cfOrderId; // Changed to String to handle both string and int from API
  final String orderId;
  final double orderAmount;
  final String orderCurrency;
  final String orderStatus;
  final String paymentSessionId;
  final String? environment;

  CashfreeOrderResponse({
    this.cfOrderId,
    required this.orderId,
    required this.orderAmount,
    required this.orderCurrency,
    required this.orderStatus,
    required this.paymentSessionId,
    this.environment,
  });

  factory CashfreeOrderResponse.fromJson(Map<String, dynamic> json) {
    // Handle cfOrderId as either string or int
    String? cfOrderId;
    if (json['cfOrderId'] != null) {
      cfOrderId = json['cfOrderId'].toString();
    }

    return CashfreeOrderResponse(
      cfOrderId: cfOrderId,
      orderId: json['orderId'] ?? '',
      orderAmount: (json['orderAmount'] ?? 0).toDouble(),
      orderCurrency: json['orderCurrency'] ?? 'INR',
      orderStatus: json['orderStatus'] ?? '',
      paymentSessionId: json['paymentSessionId'] ?? '',
      environment: json['environment'],
    );
  }
}

class CashfreeVerifyResponse {
  final bool success;
  final String message;
  final String? warning;
  final String? orderStatus;
  final List<dynamic>? payments;

  CashfreeVerifyResponse({
    required this.success,
    required this.message,
    this.warning,
    this.orderStatus,
    this.payments,
  });

  factory CashfreeVerifyResponse.fromJson(Map<String, dynamic> json) {
    return CashfreeVerifyResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      warning: json['warning'],
      orderStatus: json['data']?['orderStatus'],
      payments: json['data']?['payments'],
    );
  }
}

class CashfreeStatusResponse {
  final String orderId;
  final String? cfOrderId; // Changed to String to handle both string and int
  final String orderStatus;
  final double orderAmount;
  final bool isPaid;

  CashfreeStatusResponse({
    required this.orderId,
    this.cfOrderId,
    required this.orderStatus,
    required this.orderAmount,
    required this.isPaid,
  });

  factory CashfreeStatusResponse.fromJson(Map<String, dynamic> json) {
    // Handle cfOrderId as either string or int
    String? cfOrderId;
    if (json['cfOrderId'] != null) {
      cfOrderId = json['cfOrderId'].toString();
    }

    return CashfreeStatusResponse(
      orderId: json['orderId'] ?? '',
      cfOrderId: cfOrderId,
      orderStatus: json['orderStatus'] ?? '',
      orderAmount: (json['orderAmount'] ?? 0).toDouble(),
      isPaid: json['isPaid'] ?? false,
    );
  }
}
