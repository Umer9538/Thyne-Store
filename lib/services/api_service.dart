import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Retry a request once if unauthorized by refreshing the token
  static Future<http.Response> _withAuthRetry(Future<http.Response> Function() makeRequest) async {
    http.Response response = await makeRequest();
    if (response.statusCode != 401) {
      return response;
    }

    try {
      final existingRefreshToken = await _storage.read(key: 'refresh_token');
      if (existingRefreshToken == null) {
        return response;
      }

      // Attempt token refresh
      final refreshResponse = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: await _getHeaders(),
        body: json.encode({'refreshToken': existingRefreshToken}),
      );

      if (refreshResponse.statusCode >= 200 && refreshResponse.statusCode < 300) {
        final parsed = json.decode(refreshResponse.body) as Map<String, dynamic>;
        final data = (parsed['data'] ?? {}) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newAccess != null) {
          await _storage.write(key: 'auth_token', value: newAccess);
        }
        if (newRefresh != null) {
          await _storage.write(key: 'refresh_token', value: newRefresh);
        }

        // Retry original request with updated headers
        return await makeRequest();
      }
    } catch (_) {
      // Fall through to return original unauthorized response
    }

    return response;
  }
  
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
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final guestSessionId = await _getGuestSessionId();
    if (guestSessionId != null) {
      headers['X-Guest-Session-ID'] = guestSessionId;
    }

    return headers;
  }

  // Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Handle empty response body
      if (response.body.isEmpty) {
        return {'success': false, 'error': 'Empty response from server'};
      }

      try {
        return json.decode(response.body);
      } catch (e) {
        print('JSON parse error: $e');
        print('Response body: ${response.body}');
        return {'success': false, 'error': 'Invalid JSON response: $e'};
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        throw ApiException(
          message: errorData['error'] ?? 'An error occurred',
          code: errorData['code'] ?? 'UNKNOWN_ERROR',
          statusCode: response.statusCode,
        );
      } catch (e) {
        throw ApiException(
          message: 'Server error: ${response.statusCode}',
          code: 'HTTP_ERROR',
          statusCode: response.statusCode,
        );
      }
    }
  }

  // Authentication APIs
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(),
      body: json.encode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(),
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: await _getHeaders(),
      body: json.encode({
        'refreshToken': refreshToken,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: await _getHeaders(),
      body: json.encode({
        'email': email,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: await _getHeaders(),
      body: json.encode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  // User APIs
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (profileImage != null) body['profileImage'] = profileImage;

    final response = await _withAuthRetry(() async {
      return await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode(body),
      );
    });

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/change-password'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  // Address APIs
  static Future<Map<String, dynamic>> addAddress({
    required String street,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    bool isDefault = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/addresses'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
        'isDefault': isDefault,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    required String street,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    bool isDefault = false,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/addresses/$addressId'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
        'isDefault': isDefault,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteAddress({
    required String addressId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/addresses/$addressId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> setDefaultAddress({
    required String addressId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/addresses/$addressId/default'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // Product APIs
  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (inStock != null) queryParams['inStock'] = inStock.toString();

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Storefront (public) APIs
  static Future<Map<String, dynamic>> getStorefrontConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/storefront/config'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getHomePageConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/storefront/homepage'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getStorefrontFeaturedProducts({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/storefront/featured-products?limit=$limit'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getStorefrontNewArrivals({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/storefront/new-arrivals?limit=$limit'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getStorefrontBestSellers({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/storefront/best-sellers?limit=$limit'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getVisibleCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/storefront/categories'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Storefront (admin) APIs
  static Future<Map<String, dynamic>> updateStorefrontConfig({
    required Map<String, dynamic> config,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/storefront/config'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(config),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateCategoryVisibility({
    required List<Map<String, dynamic>> categories,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/storefront/categories/visibility'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({'categories': categories}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updatePromotionalBanners({
    required Map<String, dynamic> promotionalBanners,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/storefront/promotional-banners'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(promotionalBanners),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateThemeConfig({
    required Map<String, dynamic> themeConfig,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/storefront/theme'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(themeConfig),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateFeatureFlags({
    required Map<String, dynamic> featureFlags,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/storefront/features'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(featureFlags),
    );
    return _handleResponse(response);
  }

  // Admin - Users (Customers) APIs
  static Future<Map<String, dynamic>> adminGetUsers({int page = 1, int limit = 20}) async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/admin/users?page=$page&limit=$limit'),
        headers: await _getHeaders(requireAuth: true),
      );
    });
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> adminSearchUsers({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/admin/users/search?q=${Uri.encodeQueryComponent(query)}&page=$page&limit=$limit'),
        headers: await _getHeaders(requireAuth: true),
      );
    });
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> adminGetUserById(String userId) async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: await _getHeaders(requireAuth: true),
      );
    });
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> adminActivateUser(String userId) async {
    final response = await _withAuthRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/admin/users/$userId/activate'),
        headers: await _getHeaders(requireAuth: true),
      );
    });
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> adminDeactivateUser(String userId) async {
    final response = await _withAuthRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/admin/users/$userId/deactivate'),
        headers: await _getHeaders(requireAuth: true),
      );
    });
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> adminMakeUserAdmin(String userId) async {
    final response = await _withAuthRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/admin/users/$userId/make-admin'),
        headers: await _getHeaders(requireAuth: true),
      );
    });
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> adminRemoveUserAdmin(String userId) async {
    final response = await _withAuthRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/admin/users/$userId/remove-admin'),
        headers: await _getHeaders(requireAuth: true),
      );
    });
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProduct({
    required String productId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/categories'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getFeaturedProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/featured'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> searchProducts({
    required String query,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/search?q=$query'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Review APIs
  static Future<Map<String, dynamic>> createReview({
    required String productId,
    required double rating,
    required String comment,
    List<String> images = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reviews'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'productId': productId,
        'rating': rating,
        'comment': comment,
        'images': images,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProductReviews({
    required String productId,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId/reviews?page=$page&limit=$limit'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Cart APIs
  static Future<Map<String, dynamic>> getCart() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/items'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'productId': productId,
        'quantity': quantity,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateCartItem({
    required String productId,
    required int quantity,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cart/items'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'productId': productId,
        'quantity': quantity,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> removeFromCart({
    required String productId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/items/$productId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> applyCoupon({
    required String couponCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/coupon'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'couponCode': couponCode,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> removeCoupon() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/coupon'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> clearCart() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // Order APIs
  static Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> orderData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(orderData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders?page=$page&limit=$limit'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getOrder({
    required String orderId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> trackOrder({
    required String orderId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/track'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> searchOrderByNumber({
    required String orderNumber,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/orders/search?orderNumber=${Uri.encodeQueryComponent(orderNumber)}'),
        headers: await _getHeaders(requireAuth: true),
      );
    });

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> returnOrder({
    required String orderId,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/return'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'reason': reason,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> refundOrder({
    required String orderId,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/refund'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'reason': reason,
      }),
    );

    return _handleResponse(response);
  }

  // Payment APIs
  static Future<Map<String, dynamic>> createPaymentOrder({
    required String orderId,
    required double amount,
    required String currency,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/orders'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      }),
    );

    return _handleResponse(response);
  }

  // Guest Session APIs
  static Future<Map<String, dynamic>> createGuestSession() async {
    final response = await http.post(
      Uri.parse('$baseUrl/guest/sessions'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getGuestSession({
    required String sessionId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/guest/sessions/$sessionId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateGuestSession({
    required String sessionId,
    String? email,
    String? phone,
    String? name,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (name != null) body['name'] = name;

    final response = await http.put(
      Uri.parse('$baseUrl/guest/sessions/$sessionId'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteGuestSession({
    required String sessionId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/guest/sessions/$sessionId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Admin APIs
  
  // Dashboard
  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard/stats'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminUserStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard/users'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminProductStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard/products'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminRecentActivities({
    int limit = 50,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard/activities?limit=$limit'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // Product Management
  static Future<Map<String, dynamic>> createProduct({
    required Map<String, dynamic> productData,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/admin/products'),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode(productData),
      );
    });

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProduct({
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.put(
        Uri.parse('$baseUrl/admin/products/$productId'),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode(productData),
      );
    });

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteProduct({
    required String productId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/products/$productId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProductStock({
    required String productId,
    required int quantity,
    String? reason,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/products/$productId/stock'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'quantity': quantity,
        'reason': reason ?? 'Stock update',
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> bulkUploadProducts(PlatformFile file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/admin/products/bulk-upload'),
    );

    // Add headers
    final headers = await _getHeaders(requireAuth: true);
    request.headers.addAll(headers);

    // Add file
    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );
    } else {
      throw Exception('File bytes are null');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  // Category Management
  static Future<Map<String, dynamic>> getAllCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/categories'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createCategory({
    required String name,
    required String description,
    List<String> subcategories = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/categories'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'name': name,
        'description': description,
        'subcategories': subcategories,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    required String name,
    required String description,
    List<String> subcategories = const [],
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/categories/$categoryId'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'name': name,
        'description': description,
        'subcategories': subcategories,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteCategory({
    required String categoryId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/categories/$categoryId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // Order Management
  static Future<Map<String, dynamic>> getAdminOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri.parse('$baseUrl/admin/orders').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? trackingNumber,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/orders/$orderId/status'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'status': status,
        'trackingNumber': trackingNumber,
      }),
    );

    return _handleResponse(response);
  }

  // User Management
  static Future<Map<String, dynamic>> getAdminUsers({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users?page=$page&limit=$limit'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> searchAdminUsers({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/search?q=$query&page=$page&limit=$limit'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // System
  static Future<Map<String, dynamic>> getSystemHealth() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/system/health'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> broadcastNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
    String audience = 'all',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/notifications/broadcast'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'audience': audience,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> exportData({
    required String type,
    String format = 'csv',
    String? startDate,
    String? endDate,
    Map<String, dynamic>? filters,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/export'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'type': type,
        'format': format,
        'startDate': startDate,
        'endDate': endDate,
        'filters': filters,
      }),
    );

    return _handleResponse(response);
  }

  // Loyalty Program API Methods

  /// Get user's loyalty program
  static Future<Map<String, dynamic>> getLoyaltyProgram() async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/loyalty/program'),
        headers: await _getHeaders(requireAuth: true),
      );
    });

    return _handleResponse(response);
  }

  /// Get loyalty credits history
  static Future<Map<String, dynamic>> getCreditHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/loyalty/credits/history?limit=$limit&offset=$offset'),
        headers: await _getHeaders(requireAuth: true),
      );
    });

    return _handleResponse(response);
  }

  /// Trigger daily login bonus check
  static Future<Map<String, dynamic>> checkDailyLogin() async {
    final response = await _withAuthRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/loyalty/daily-login'),
        headers: await _getHeaders(requireAuth: true),
      );
    });

    return _handleResponse(response);
  }

  /// Get available redemption options
  static Future<Map<String, dynamic>> getRedemptionOptions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/loyalty/redemption-options'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  /// Redeem credits for voucher or discount
  static Future<Map<String, dynamic>> redeemCredits({
    required String redemptionId,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/loyalty/redeem'),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode({
          'redemptionId': redemptionId,
        }),
      );
    });

    return _handleResponse(response);
  }

  /// Get available vouchers for redemption
  static Future<Map<String, dynamic>> getAvailableVouchers() async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/vouchers/available'),
        headers: await _getHeaders(requireAuth: true),
      );
    });

    return _handleResponse(response);
  }

  /// Redeem a voucher with loyalty credits
  static Future<Map<String, dynamic>> redeemVoucher({
    required String voucherId,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/vouchers/redeem'),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode({
          'voucherId': voucherId,
        }),
      );
    });

    return _handleResponse(response);
  }

  /// Get user's vouchers
  static Future<Map<String, dynamic>> getUserVouchers({
    bool unusedOnly = false,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/vouchers/my?unused_only=$unusedOnly'),
        headers: await _getHeaders(requireAuth: true),
      );
    });

    return _handleResponse(response);
  }

  /// Use a voucher during checkout
  static Future<Map<String, dynamic>> useVoucher({
    required String voucherCode,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/vouchers/use'),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode({
          'voucherCode': voucherCode,
        }),
      );
    });

    return _handleResponse(response);
  }

  /// Get loyalty program configuration
  static Future<Map<String, dynamic>> getLoyaltyConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/loyalty/config'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  /// Get loyalty tier information
  static Future<Map<String, dynamic>> getLoyaltyTiers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/loyalty/tiers'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Admin Loyalty APIs

  /// Add credits to user (Admin only)
  static Future<Map<String, dynamic>> addCreditsToUser({
    required String userId,
    required int credits,
    required String description,
    required String type,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.post(
        Uri.parse('$baseUrl/admin/loyalty/credits/add'),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode({
          'userId': userId,
          'credits': credits,
          'description': description,
          'type': type,
        }),
      );
    });

    return _handleResponse(response);
  }

  /// Get loyalty statistics (Admin only)
  static Future<Map<String, dynamic>> getLoyaltyStatistics() async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/admin/loyalty/statistics'),
        headers: await _getHeaders(requireAuth: true),
      );
    });

    return _handleResponse(response);
  }

  /// Get top loyalty members (Admin only)
  static Future<Map<String, dynamic>> getTopLoyaltyMembers({
    int limit = 10,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/admin/loyalty/top-members?limit=$limit'),
        headers: await _getHeaders(requireAuth: true),
      );
    });

    return _handleResponse(response);
  }

  /// Export loyalty data (Admin only)
  static Future<http.Response> exportLoyaltyData() async {
    final response = await _withAuthRetry(() async {
      return await http.get(
        Uri.parse('$baseUrl/admin/loyalty/export'),
        headers: await _getHeaders(requireAuth: true),
      );
    });

    return response; // Return raw response for CSV download
  }

  /// Update loyalty configuration (Admin only)
  static Future<Map<String, dynamic>> updateLoyaltyConfig({
    required Map<String, dynamic> config,
  }) async {
    final response = await _withAuthRetry(() async {
      return await http.put(
        Uri.parse('$baseUrl/admin/loyalty/config'),
        headers: await _getHeaders(requireAuth: true),
        body: json.encode(config),
      );
    });

    return _handleResponse(response);
  }

  // Wishlist APIs
  static Future<Map<String, dynamic>> getWishlist({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/wishlist?page=$page&limit=$limit'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> addToWishlist({
    required String productId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/wishlist'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'productId': productId,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> removeFromWishlist({
    required String productId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/wishlist/$productId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // Notification APIs
  static Future<Map<String, dynamic>> updateNotificationPreferences({
    required Map<String, bool> preferences,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/notification-preferences'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(preferences),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/notification-preferences'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getUserNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'unreadOnly': unreadOnly.toString(),
    };

    final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markNotificationAsRead({
    required String notificationId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteNotification({
    required String notificationId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/notifications/$notificationId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // Banner Management APIs
  static Future<Map<String, dynamic>> getBanners({
    bool activeOnly = false,
  }) async {
    final queryParams = activeOnly ? '?activeOnly=true' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/admin/banners$queryParams'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createBanner({
    required Map<String, dynamic> bannerData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/banners'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(bannerData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateBanner({
    required String bannerId,
    required Map<String, dynamic> bannerData,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/banners/$bannerId'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(bannerData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteBanner({
    required String bannerId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/banners/$bannerId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getActiveBanners() async {
    final response = await http.get(
      Uri.parse('$baseUrl/banners/active'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Event Management APIs
  static Future<Map<String, dynamic>> getEvents({
    bool upcomingOnly = false,
  }) async {
    final queryParams = upcomingOnly ? '?upcomingOnly=true' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/admin/events$queryParams'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createEvent({
    required Map<String, dynamic> eventData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/events'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(eventData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    required Map<String, dynamic> eventData,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/events/$eventId'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(eventData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteEvent({
    required String eventId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/events/$eventId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getUpcomingEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/upcoming'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Theme Configuration APIs
  static Future<Map<String, dynamic>> getThemeConfigs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/themes'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createThemeConfig({
    required Map<String, dynamic> themeData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/themes'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(themeData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> activateTheme({
    required String themeId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/themes/$themeId/activate'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getActiveTheme() async {
    final response = await http.get(
      Uri.parse('$baseUrl/theme/active'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getThemes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/themes'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // Promotion APIs
  static Future<Map<String, dynamic>> getActivePromotions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/promotions/active'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPopupPromotions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/promotions/popups'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createPromotion({
    required Map<String, dynamic> promotionData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/promotions'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode(promotionData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deletePromotion({
    required String promotionId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/promotions/$promotionId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // Invoice APIs
  static Future<Map<String, dynamic>> generateInvoice({
    required String orderId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoices/generate'),
      headers: await _getHeaders(requireAuth: true),
      body: json.encode({
        'orderId': orderId,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getInvoices({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/invoices?page=$page&limit=$limit'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getInvoice({
    required String invoiceId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/invoices/$invoiceId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getInvoiceByOrderId({
    required String orderId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/invoices/order/$orderId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markInvoiceAsDownloaded({
    required String invoiceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoices/$invoiceId/download'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // Admin Invoice APIs
  static Future<Map<String, dynamic>> getAdminInvoices({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri.parse('$baseUrl/admin/invoices').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  static Future<http.Response> exportInvoicesCSV({
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = <String, String>{};

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['dateFrom'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams['dateTo'] = dateTo;
    }

    final uri = Uri.parse('$baseUrl/admin/invoices/export/csv').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await _getHeaders(requireAuth: true),
    );

    return response; // Return raw response for CSV download
  }

  static Future<Map<String, dynamic>> deleteInvoice({
    required String invoiceId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/invoices/$invoiceId'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  // Homepage APIs

  /// Get complete homepage data with all sections
  static Future<Map<String, dynamic>> getHomepage() async {
    final response = await http.get(
      Uri.parse('$baseUrl/homepage'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  /// Get active deal of the day
  static Future<Map<String, dynamic>> getActiveDealOfDay() async {
    final response = await http.get(
      Uri.parse('$baseUrl/homepage/deal-of-day'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  /// Get active flash sales
  static Future<Map<String, dynamic>> getActiveFlashSales() async {
    final response = await http.get(
      Uri.parse('$baseUrl/homepage/flash-sales'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  /// Get active brands
  static Future<Map<String, dynamic>> getActiveBrands() async {
    final response = await http.get(
      Uri.parse('$baseUrl/homepage/brands'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  /// Track product view for recently viewed section
  static Future<Map<String, dynamic>> trackProductView({
    required String productId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/homepage/track/$productId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  /// Get recently viewed products
  static Future<Map<String, dynamic>> getRecentlyViewed({
    int limit = 10,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/homepage/recently-viewed?limit=$limit'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  /// Get homepage layout configuration (Admin only)
  static Future<Map<String, dynamic>> getHomepageLayout() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/homepage/layout'),
      headers: await _getHeaders(requireAuth: true),
    );

    return _handleResponse(response);
  }

  /// Update homepage layout configuration (Admin only)
  static Future<Map<String, dynamic>> updateHomepageLayout(
    Map<String, dynamic> layoutData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/homepage/layout'),
      headers: await _getHeaders(requireAuth: true),
      body: jsonEncode(layoutData),
    );

    return _handleResponse(response);
  }
  // ==================== Community API Methods ====================

  // Get community feed
  static Future<Map<String, dynamic>> getCommunityFeed({
    int page = 1,
    int limit = 20,
    String sortBy = 'latest',
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/community/feed?page=$page&limit=$limit&sortBy=$sortBy'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Get single post
  static Future<Map<String, dynamic>> getPost(String postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/community/posts/$postId'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Get user posts
  static Future<Map<String, dynamic>> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/community/users/$userId/posts?page=$page&limit=$limit'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Create community post
  static Future<Map<String, dynamic>> createCommunityPost({
    required String content,
    List<String>? images,
    List<String>? videos,
    List<String>? tags,
    bool isFeatured = false,
    bool isPinned = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/community/posts'),
      headers: await _getHeaders(requireAuth: true),
      body: jsonEncode({
        'content': content,
        if (images != null && images.isNotEmpty) 'images': images,
        if (videos != null && videos.isNotEmpty) 'videos': videos,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        'isFeatured': isFeatured,
        'isPinned': isPinned,
      }),
    );
    return _handleResponse(response);
  }

  // Update post
  static Future<Map<String, dynamic>> updatePost(
    String postId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/community/posts/$postId'),
      headers: await _getHeaders(requireAuth: true),
      body: jsonEncode(updates),
    );
    return _handleResponse(response);
  }

  // Delete post
  static Future<Map<String, dynamic>> deletePost(String postId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/community/posts/$postId'),
      headers: await _getHeaders(requireAuth: true),
    );
    return _handleResponse(response);
  }

  // Like post
  static Future<Map<String, dynamic>> likePost(String postId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/community/posts/$postId/like'),
      headers: await _getHeaders(requireAuth: true),
    );
    return _handleResponse(response);
  }

  // Vote on post
  static Future<Map<String, dynamic>> votePost(String postId, String voteType) async {
    final response = await http.post(
      Uri.parse('$baseUrl/community/posts/$postId/vote'),
      headers: await _getHeaders(requireAuth: true),
      body: jsonEncode({'voteType': voteType}),
    );
    return _handleResponse(response);
  }

  // Get post engagement
  static Future<Map<String, dynamic>> getPostEngagement(String postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/community/posts/$postId/engagement'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Get post comments
  static Future<Map<String, dynamic>> getPostComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/community/posts/$postId/comments?page=$page&limit=$limit'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Create comment
  static Future<Map<String, dynamic>> createComment(
    String postId,
    String content,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/community/comments'),
      headers: await _getHeaders(requireAuth: true),
      body: jsonEncode({
        'postId': postId,
        'content': content,
      }),
    );
    return _handleResponse(response);
  }

  // Link Instagram
  static Future<Map<String, dynamic>> linkInstagram({
    required String instagramId,
    required String username,
    String? displayName,
    String? profilePicUrl,
    String? bio,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/community/instagram/link'),
      headers: await _getHeaders(requireAuth: true),
      body: jsonEncode({
        'instagramId': instagramId,
        'username': username,
        if (displayName != null) 'displayName': displayName,
        if (profilePicUrl != null) 'profilePicUrl': profilePicUrl,
        if (bio != null) 'bio': bio,
      }),
    );
    return _handleResponse(response);
  }

  // Get Instagram profile
  static Future<Map<String, dynamic>> getInstagramProfile(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/community/instagram/$userId'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Unlink Instagram
  static Future<Map<String, dynamic>> unlinkInstagram() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/community/instagram/unlink'),
      headers: await _getHeaders(requireAuth: true),
    );
    return _handleResponse(response);
  }

  // Admin: Toggle feature post
  static Future<Map<String, dynamic>> toggleFeaturePost(String postId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/community/posts/$postId/feature'),
      headers: await _getHeaders(requireAuth: true),
    );
    return _handleResponse(response);
  }

  // Admin: Toggle pin post
  static Future<Map<String, dynamic>> togglePinPost(String postId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/community/posts/$postId/pin'),
      headers: await _getHeaders(requireAuth: true),
    );
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  ApiException({
    required this.message,
    required this.code,
    required this.statusCode,
  });

  @override
  String toString() {
    return 'ApiException: $message (Code: $code, Status: $statusCode)';
  }
}
