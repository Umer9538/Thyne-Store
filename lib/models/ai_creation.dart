/// Intent type for AI prompts
enum AIIntentType { text, image }

/// View type for generated images
enum ImageViewType { profile, front, top, perspective, custom }

class AICreation {
  final String id;
  final String prompt;
  final String imageUrl;
  final DateTime createdAt;
  final bool isSuccessful;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  // New fields for intent analysis and view type
  final AIIntentType intentType;
  final ImageViewType viewType;
  final bool isProfileView;
  final double? textConfidence;
  final double? imageConfidence;

  AICreation({
    required this.id,
    required this.prompt,
    required this.imageUrl,
    required this.createdAt,
    this.isSuccessful = true,
    this.errorMessage,
    this.metadata,
    this.intentType = AIIntentType.image,
    this.viewType = ImageViewType.profile,
    this.isProfileView = true,
    this.textConfidence,
    this.imageConfidence,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isSuccessful': isSuccessful,
      'errorMessage': errorMessage,
      'metadata': metadata,
      'intentType': intentType.name,
      'viewType': viewType.name,
      'isProfileView': isProfileView,
      'textConfidence': textConfidence,
      'imageConfidence': imageConfidence,
    };
  }

  // Create from JSON
  factory AICreation.fromJson(Map<String, dynamic> json) {
    return AICreation(
      id: json['id'],
      prompt: json['prompt'],
      imageUrl: json['imageUrl'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      isSuccessful: _parseBool(json['isSuccessful'], defaultValue: true),
      errorMessage: json['errorMessage'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      intentType: _parseIntentType(json['intentType']),
      viewType: _parseViewType(json['viewType']),
      isProfileView: _parseBool(json['isProfileView'], defaultValue: true),
      textConfidence: json['textConfidence']?.toDouble(),
      imageConfidence: json['imageConfidence']?.toDouble(),
    );
  }

  // Parse intent type from string
  static AIIntentType _parseIntentType(dynamic value) {
    if (value == null) return AIIntentType.image;
    if (value == 'text') return AIIntentType.text;
    return AIIntentType.image;
  }

  // Parse view type from string
  static ImageViewType _parseViewType(dynamic value) {
    if (value == null) return ImageViewType.profile;
    final viewTypes = {
      'profile': ImageViewType.profile,
      'front': ImageViewType.front,
      'top': ImageViewType.top,
      'perspective': ImageViewType.perspective,
      'custom': ImageViewType.custom,
    };
    return viewTypes[value] ?? ImageViewType.profile;
  }

  // Helper to parse boolean from various types (bool, int, string)
  static bool _parseBool(dynamic value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }

  // Create a copy with modified fields
  AICreation copyWith({
    String? id,
    String? prompt,
    String? imageUrl,
    DateTime? createdAt,
    bool? isSuccessful,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    AIIntentType? intentType,
    ImageViewType? viewType,
    bool? isProfileView,
    double? textConfidence,
    double? imageConfidence,
  }) {
    return AICreation(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      intentType: intentType ?? this.intentType,
      viewType: viewType ?? this.viewType,
      isProfileView: isProfileView ?? this.isProfileView,
      textConfidence: textConfidence ?? this.textConfidence,
      imageConfidence: imageConfidence ?? this.imageConfidence,
    );
  }
}

/// Intent analysis result from backend
class IntentAnalysisResult {
  final AIIntentType intent;
  final double textConfidence;
  final double imageConfidence;
  final String reason;
  final String? enhancedPrompt;
  final bool isProfileView;

  IntentAnalysisResult({
    required this.intent,
    required this.textConfidence,
    required this.imageConfidence,
    required this.reason,
    this.enhancedPrompt,
    this.isProfileView = true,
  });

  factory IntentAnalysisResult.fromJson(Map<String, dynamic> json) {
    return IntentAnalysisResult(
      intent: json['intent'] == 'text' ? AIIntentType.text : AIIntentType.image,
      textConfidence: (json['textConfidence'] ?? 50).toDouble(),
      imageConfidence: (json['imageConfidence'] ?? 50).toDouble(),
      reason: json['reason'] ?? '',
      enhancedPrompt: json['enhancedPrompt'],
      isProfileView: json['isProfileView'] ?? true,
    );
  }

  bool get isTextIntent => intent == AIIntentType.text;
  bool get isImageIntent => intent == AIIntentType.image;
}

/// Token usage tracking for monthly limits
class TokenUsage {
  final int tokensUsed;
  final int tokenLimit;
  final int tokensRemaining;
  final double usagePercent;
  final int imageCount;
  final bool canGenerate;
  final String resetDate;
  final String month;

  TokenUsage({
    required this.tokensUsed,
    required this.tokenLimit,
    required this.tokensRemaining,
    required this.usagePercent,
    required this.imageCount,
    required this.canGenerate,
    required this.resetDate,
    required this.month,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      tokensUsed: json['tokensUsed'] ?? 0,
      tokenLimit: json['tokenLimit'] ?? 1000000,
      tokensRemaining: json['tokensRemaining'] ?? 1000000,
      usagePercent: (json['usagePercent'] ?? 0).toDouble(),
      imageCount: json['imageCount'] ?? 0,
      canGenerate: json['canGenerate'] ?? true,
      resetDate: json['resetDate'] ?? '',
      month: json['month'] ?? '',
    );
  }

  // Check if usage is low (under 25%)
  bool get isUsageLow => usagePercent < 25;

  // Check if usage is medium (25-75%)
  bool get isUsageMedium => usagePercent >= 25 && usagePercent < 75;

  // Check if usage is high (75-100%)
  bool get isUsageHigh => usagePercent >= 75;

  // Format tokens for display
  String get tokensUsedFormatted => _formatTokens(tokensUsed);
  String get tokenLimitFormatted => _formatTokens(tokenLimit);
  String get tokensRemainingFormatted => _formatTokens(tokensRemaining);

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    } else if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(1)}K';
    }
    return tokens.toString();
  }
}

/// Price estimate for custom AI jewelry design
class PriceEstimate {
  final String jewelryType;
  final String metalType;
  final double estimatedWeight;
  final double metalPrice;
  final double basePrice;
  final double makingCharges;
  final double customBuildFee;
  final double stoneEstimate;
  final double minPrice;
  final double maxPrice;
  final String currency;
  final String priceBreakdown;

  PriceEstimate({
    required this.jewelryType,
    required this.metalType,
    required this.estimatedWeight,
    required this.metalPrice,
    required this.basePrice,
    required this.makingCharges,
    required this.customBuildFee,
    required this.stoneEstimate,
    required this.minPrice,
    required this.maxPrice,
    required this.currency,
    required this.priceBreakdown,
  });

  factory PriceEstimate.fromJson(Map<String, dynamic> json) {
    return PriceEstimate(
      jewelryType: json['jewelryType'] ?? 'other',
      metalType: json['metalType'] ?? 'gold_18k',
      estimatedWeight: (json['estimatedWeight'] ?? 0).toDouble(),
      metalPrice: (json['metalPrice'] ?? 0).toDouble(),
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      makingCharges: (json['makingCharges'] ?? 0).toDouble(),
      customBuildFee: (json['customBuildFee'] ?? 2000).toDouble(),
      stoneEstimate: (json['stoneEstimate'] ?? 0).toDouble(),
      minPrice: (json['minPrice'] ?? 0).toDouble(),
      maxPrice: (json['maxPrice'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      priceBreakdown: json['priceBreakdown'] ?? '',
    );
  }

  // Format price range for display
  String get priceRange => '₹${_formatPrice(minPrice)} - ₹${_formatPrice(maxPrice)}';

  // Format individual price
  String _formatPrice(double price) {
    if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(1)}L';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    }
    return price.toStringAsFixed(0);
  }

  // Display-friendly jewelry type
  String get jewelryTypeDisplay {
    final types = {
      'ring': 'Ring',
      'necklace': 'Necklace',
      'bracelet': 'Bracelet',
      'earring': 'Earrings',
      'pendant': 'Pendant',
      'bangle': 'Bangle',
      'other': 'Jewelry',
    };
    return types[jewelryType] ?? 'Jewelry';
  }

  // Display-friendly metal type
  String get metalTypeDisplay {
    final metals = {
      'gold_14k': '14K Gold',
      'gold_18k': '18K Gold',
      'gold_22k': '22K Gold',
      'silver': 'Sterling Silver',
      'platinum': 'Platinum',
      'rose_gold': 'Rose Gold',
      'white_gold': 'White Gold',
    };
    return metals[metalType] ?? 'Gold';
  }
}