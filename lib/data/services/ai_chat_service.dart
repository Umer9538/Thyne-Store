import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../../config/api_config.dart';
import 'api_service.dart';

/// Service for AI-powered jewelry chat and recommendations
/// Routes through deployed backend API (uses OpenAI)
class AIChatService {
  // Singleton pattern
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;
  AIChatService._internal();

  /// Main chat method - processes user message and returns AI response
  /// Uses deployed backend API for AI processing
  Future<ChatResponse> chat(String userMessage, {List<Product>? availableProducts}) async {
    try {
      print('🤖 AIChatService: Processing message: $userMessage');

      // Call the backend's combined intent analysis and response endpoint
      final response = await _callBackendChat(userMessage);

      print('🤖 AIChatService: Backend response - Intent: ${response['intent']}, Success: ${response['success']}');

      // Extract token info
      final tokensUsed = (response['tokensUsed'] ?? 0) as int;
      final tokensRemaining = (response['tokensRemaining'] ?? 1000000) as int;
      final tokenLimit = (response['tokenLimit'] ?? 1000000) as int;

      // If intent is search, fetch matching products
      if (response['intent'] == 'search' && response['success'] == true) {
        final products = await _fetchProducts(
          category: response['category'],
          minPrice: response['minPrice']?.toDouble(),
          maxPrice: response['maxPrice']?.toDouble(),
          metalType: response['metalType'],
        );

        if (products.isEmpty) {
          return ChatResponse(
            message: response['message'] ?? "I couldn't find any products matching your criteria. Try adjusting your budget or category preferences.",
            products: [],
            intentType: IntentType.productRecommendation,
            tokensUsed: tokensUsed,
            tokensRemaining: tokensRemaining,
            tokenLimit: tokenLimit,
          );
        }

        // Generate product-aware response if we have products
        final productContext = products.take(5).map((p) =>
          '- ${p.name}: ₹${p.price.toStringAsFixed(0)} (${p.metalType}, ${p.category})'
        ).join('\n');

        final enhancedResponse = await _generateProductResponse(userMessage, productContext);

        return ChatResponse(
          message: enhancedResponse,
          products: products,
          intentType: IntentType.productRecommendation,
          tokensUsed: tokensUsed,
          tokensRemaining: tokensRemaining,
          tokenLimit: tokenLimit,
        );
      } else {
        // General response - no products needed
        return ChatResponse(
          message: response['message'] ?? "I'm here to help with your jewelry questions!",
          products: [],
          intentType: IntentType.general,
          tokensUsed: tokensUsed,
          tokensRemaining: tokensRemaining,
          tokenLimit: tokenLimit,
        );
      }
    } catch (e) {
      print('❌ AIChatService: Error: $e');
      return ChatResponse(
        message: "I'm sorry, I encountered an error processing your request. Please try again.",
        products: [],
        intentType: IntentType.general,
        error: e.toString(),
      );
    }
  }

  /// Call the backend's combined chat endpoint
  Future<Map<String, dynamic>> _callBackendChat(String message) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ai/chat/full');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        print('❌ Backend API Error ${response.statusCode}: ${response.body}');
        throw Exception('Backend API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }

      return {
        'message': 'I encountered an issue processing your request.',
        'intent': 'general',
        'success': false,
      };
    } catch (e) {
      print('❌ Backend chat error: $e');
      rethrow;
    }
  }

  /// Generate a product-aware response using backend
  Future<String> _generateProductResponse(String userMessage, String productContext) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ai/chat/generate');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userMessage': userMessage,
          'type': 'product_recommendation',
          'productContext': productContext,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return "Here are some great options that match your preferences!";
      }

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data']['message'] ?? "Here are some recommendations for you!";
      }

      return "I found some beautiful pieces that might interest you!";
    } catch (e) {
      print('❌ Product response generation error: $e');
      return "Here are some lovely options based on your preferences!";
    }
  }

  /// Fetch products from API based on filters
  Future<List<Product>> _fetchProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? metalType,
  }) async {
    try {
      print('🔍 Fetching products with filters:');
      print('   Category: $category');
      print('   Budget: $minPrice - $maxPrice');
      print('   Metal: $metalType');

      final result = await ApiService.getProducts(
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        limit: 10,
        sortBy: 'rating',
        inStock: true,
      );

      if (result['success'] == true && result['data'] != null) {
        final productsData = result['data']['products'] as List<dynamic>? ?? [];
        final products = productsData
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();

        // Filter by metal type if specified
        if (metalType != null && metalType.isNotEmpty) {
          return products
              .where((p) => p.metalType.toLowerCase().contains(metalType.toLowerCase()))
              .toList();
        }

        return products;
      }

      return [];
    } catch (e) {
      print('❌ Error fetching products: $e');
      return [];
    }
  }
}

/// User intent parsed from message
class UserIntent {
  final IntentType type;
  final double? minBudget;
  final double? maxBudget;
  final String? category;
  final String? metalType;
  final String? occasion;
  final String? style;
  final String? gender;

  UserIntent({
    required this.type,
    this.minBudget,
    this.maxBudget,
    this.category,
    this.metalType,
    this.occasion,
    this.style,
    this.gender,
  });
}

enum IntentType {
  general,
  productRecommendation,
}

/// Response from AI chat
class ChatResponse {
  final String message;
  final List<Product> products;
  final IntentType intentType;
  final String? error;
  // Token tracking
  final int tokensUsed;
  final int tokensRemaining;
  final int tokenLimit;

  ChatResponse({
    required this.message,
    required this.products,
    required this.intentType,
    this.error,
    this.tokensUsed = 0,
    this.tokensRemaining = 1000000,
    this.tokenLimit = 1000000,
  });

  bool get hasProducts => products.isNotEmpty;
  bool get hasError => error != null;

  /// Format remaining tokens for display (e.g., "950K" or "1M")
  String get formattedTokensRemaining {
    if (tokensRemaining >= 1000000) {
      return '${(tokensRemaining / 1000000).toStringAsFixed(1)}M';
    } else if (tokensRemaining >= 1000) {
      return '${(tokensRemaining / 1000).toStringAsFixed(0)}K';
    }
    return tokensRemaining.toString();
  }

  /// Usage percentage
  double get usagePercent => tokenLimit > 0 ? (tokensUsed / tokenLimit) * 100 : 0;
}
