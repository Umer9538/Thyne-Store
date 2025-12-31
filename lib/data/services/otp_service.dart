import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

/// OTP Channel for delivery
enum OTPChannel {
  sms,
  whatsapp,
}

/// Response from sending OTP
class SendOTPResponse {
  final bool success;
  final String message;
  final String? messageId;
  final int expiresIn;
  final String channel;
  final String maskedPhone;

  SendOTPResponse({
    required this.success,
    required this.message,
    this.messageId,
    this.expiresIn = 600,
    this.channel = 'sms',
    this.maskedPhone = '',
  });

  factory SendOTPResponse.fromJson(Map<String, dynamic> json) {
    return SendOTPResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      messageId: json['messageId'],
      expiresIn: json['expiresIn'] ?? 600,
      channel: json['channel'] ?? 'sms',
      maskedPhone: json['phone'] ?? '',
    );
  }
}

/// Response from verifying OTP
class VerifyOTPResponse {
  final bool success;
  final bool verified;
  final String message;

  VerifyOTPResponse({
    required this.success,
    required this.verified,
    required this.message,
  });

  factory VerifyOTPResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOTPResponse(
      success: json['success'] ?? false,
      verified: json['verified'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

/// Service for handling OTP operations via Mtalkz
class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  /// Send OTP to phone number
  ///
  /// [phone] - Phone number with country code (e.g., 919876543210)
  /// [channel] - Delivery channel (sms or whatsapp)
  /// [purpose] - Purpose of OTP (login, register, reset_password, verify_phone)
  Future<SendOTPResponse> sendOTP({
    required String phone,
    OTPChannel channel = OTPChannel.sms,
    String purpose = 'login',
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/otp/send');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': _normalizePhone(phone),
          'channel': channel == OTPChannel.whatsapp ? 'whatsapp' : 'sms',
          'purpose': purpose,
        }),
      ).timeout(ApiConfig.requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SendOTPResponse.fromJson(data);
      } else {
        return SendOTPResponse(
          success: false,
          message: data['error'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      return SendOTPResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Verify OTP
  ///
  /// [phone] - Phone number with country code
  /// [otp] - 6-digit OTP code
  Future<VerifyOTPResponse> verifyOTP({
    required String phone,
    required String otp,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/otp/verify');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': _normalizePhone(phone),
          'otp': otp,
        }),
      ).timeout(ApiConfig.requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return VerifyOTPResponse.fromJson(data);
      } else {
        return VerifyOTPResponse(
          success: false,
          verified: false,
          message: data['error'] ?? 'Failed to verify OTP',
        );
      }
    } catch (e) {
      return VerifyOTPResponse(
        success: false,
        verified: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Resend OTP
  ///
  /// [phone] - Phone number with country code
  /// [channel] - Delivery channel (can switch channel on resend)
  Future<SendOTPResponse> resendOTP({
    required String phone,
    OTPChannel channel = OTPChannel.sms,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/otp/resend');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': _normalizePhone(phone),
          'channel': channel == OTPChannel.whatsapp ? 'whatsapp' : 'sms',
        }),
      ).timeout(ApiConfig.requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SendOTPResponse.fromJson(data);
      } else {
        return SendOTPResponse(
          success: false,
          message: data['error'] ?? 'Failed to resend OTP',
        );
      }
    } catch (e) {
      return SendOTPResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Check OTP service status
  Future<bool> isServiceAvailable() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/otp/status');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['enabled'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Normalize phone number to include country code
  String _normalizePhone(String phone) {
    // Remove any non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Add India country code if not present
    if (cleaned.length == 10) {
      cleaned = '91$cleaned';
    }

    return cleaned;
  }
}
