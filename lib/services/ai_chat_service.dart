import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'api_service.dart';

/// Service for AI-powered jewelry chat and recommendations
class AIChatService {
  // Gemini API Configuration
  static const String _apiKey = 'AIzaSyDVWMp8jiNiA5bFSKOsThYp70Bqj9MVHc4';
  static const String _model = 'gemini-2.0-flash';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  // Singleton pattern
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;
  AIChatService._internal();

  /// Main chat method - processes user message and returns AI response
  Future<ChatResponse> chat(String userMessage, {List<Product>? availableProducts}) async {
    try {
      print('🤖 AIChatService: Processing message: $userMessage');

      // Step 1: Analyze user intent
      final intent = await _analyzeIntent(userMessage);
      print('🤖 AIChatService: Detected intent: ${intent.type}');

      // Step 2: Based on intent, either give general advice or fetch products
      if (intent.type == IntentType.productRecommendation) {
        // Fetch products based on parsed criteria
        final products = await _fetchProducts(intent);

        if (products.isEmpty) {
          return ChatResponse(
            message: "I couldn't find any products matching your criteria. Try adjusting your budget or category preferences.",
            products: [],
            intentType: intent.type,
          );
        }

        // Generate recommendation text with products
        final recommendation = await _generateProductRecommendation(
          userMessage,
          products,
          intent,
        );

        return ChatResponse(
          message: recommendation,
          products: products,
          intentType: intent.type,
        );
      } else {
        // General jewelry advice/information
        final response = await _generateGeneralResponse(userMessage);
        return ChatResponse(
          message: response,
          products: [],
          intentType: intent.type,
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

  /// Analyze user message to determine intent and extract parameters
  Future<UserIntent> _analyzeIntent(String message) async {
    final prompt = '''Analyze this jewelry shopping query and extract information in JSON format.

User message: "$message"

Return ONLY a JSON object with these fields:
{
  "intentType": "product_recommendation" or "general_question",
  "minBudget": number or null (in INR),
  "maxBudget": number or null (in INR),
  "category": string or null (one of: "rings", "necklaces", "earrings", "bracelets", "pendants", "bangles", "chains", "anklets", "nose-pins", "mangalsutra"),
  "metalType": string or null (one of: "gold", "silver", "platinum", "rose-gold"),
  "occasion": string or null,
  "style": string or null,
  "gender": string or null (one of: "men", "women", "unisex")
}

Examples:
- "Show me gold rings under 50000" → {"intentType": "product_recommendation", "maxBudget": 50000, "category": "rings", "metalType": "gold"}
- "What's the difference between 22k and 24k gold?" → {"intentType": "general_question"}
- "I want a necklace for my wife's birthday, budget 1 lakh" → {"intentType": "product_recommendation", "maxBudget": 100000, "category": "necklaces", "gender": "women", "occasion": "birthday"}

Return ONLY valid JSON, no other text.''';

    try {
      final response = await _callGemini(prompt);
      final jsonStr = _extractJson(response);
      final data = jsonDecode(jsonStr);

      return UserIntent(
        type: data['intentType'] == 'product_recommendation'
            ? IntentType.productRecommendation
            : IntentType.general,
        minBudget: data['minBudget']?.toDouble(),
        maxBudget: data['maxBudget']?.toDouble(),
        category: data['category'],
        metalType: data['metalType'],
        occasion: data['occasion'],
        style: data['style'],
        gender: data['gender'],
      );
    } catch (e) {
      print('❌ Intent parsing error: $e');
      // Default to general question if parsing fails
      return UserIntent(type: IntentType.general);
    }
  }

  /// Fetch products from API based on user intent
  Future<List<Product>> _fetchProducts(UserIntent intent) async {
    try {
      print('🔍 Fetching products with filters:');
      print('   Category: ${intent.category}');
      print('   Budget: ${intent.minBudget} - ${intent.maxBudget}');
      print('   Metal: ${intent.metalType}');

      final result = await ApiService.getProducts(
        category: intent.category,
        minPrice: intent.minBudget,
        maxPrice: intent.maxBudget,
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
        if (intent.metalType != null) {
          return products
              .where((p) => p.metalType.toLowerCase().contains(intent.metalType!.toLowerCase()))
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

  /// Generate product recommendation text
  Future<String> _generateProductRecommendation(
    String userMessage,
    List<Product> products,
    UserIntent intent,
  ) async {
    final productSummary = products.take(5).map((p) =>
      '- ${p.name}: ₹${p.price.toStringAsFixed(0)} (${p.metalType}, ${p.category})'
    ).join('\n');

    final prompt = '''You are a friendly jewelry shopping assistant at Thyne Jewels.

User asked: "$userMessage"

Based on their preferences, here are the top matching products:
$productSummary

Write a friendly, helpful response that:
1. Acknowledges their request
2. Briefly highlights 2-3 top recommendations from the list
3. Mentions key features like metal type, design, and value
4. Keeps the response concise (3-4 sentences max)
5. Sounds natural and conversational

Don't include prices in your response - they'll see them in the product cards.''';

    return await _callGemini(prompt);
  }

  /// Generate general jewelry advice response
  Future<String> _generateGeneralResponse(String userMessage) async {
    final prompt = '''You are a knowledgeable jewelry expert assistant at Thyne Jewels, an Indian jewelry store.

User question: "$userMessage"

Provide a helpful, informative response that:
1. Answers their question accurately
2. Includes relevant jewelry expertise (materials, care, traditions, etc.)
3. Is friendly and conversational
4. Stays concise (3-5 sentences)
5. Considers Indian jewelry traditions and preferences when relevant

If they seem interested in buying, gently suggest they can ask for product recommendations with their budget and preferences.''';

    return await _callGemini(prompt);
  }

  /// Call Gemini API
  Future<String> _callGemini(String prompt) async {
    final uri = Uri.parse('$_apiUrl?key=$_apiKey');

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 500,
      }
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    return parts[0]['text'] as String;
  }

  /// Extract JSON from response text
  String _extractJson(String text) {
    // Try to find JSON in the response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }
    throw Exception('No JSON found in response');
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

  ChatResponse({
    required this.message,
    required this.products,
    required this.intentType,
    this.error,
  });

  bool get hasProducts => products.isNotEmpty;
  bool get hasError => error != null;
}
