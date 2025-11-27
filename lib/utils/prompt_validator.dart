class PromptValidator {
  // Jewelry-related keywords
  static const List<String> jewelryKeywords = [
    // Types
    'ring', 'rings', 'band', 'bands',
    'necklace', 'necklaces', 'pendant', 'pendants', 'chain', 'chains',
    'bracelet', 'bracelets', 'bangle', 'bangles', 'cuff', 'cuffs',
    'earring', 'earrings', 'stud', 'studs', 'hoop', 'hoops', 'drop',
    'brooch', 'brooches', 'pin', 'pins',
    'anklet', 'anklets', 'toe ring',
    'tiara', 'crown', 'diadem',
    'watch', 'watches', 'timepiece',
    'locket', 'charm', 'charms',
    'jewelry', 'jewellery', 'jewel', 'jewels',

    // Materials
    'gold', 'silver', 'platinum', 'rose gold', 'white gold', 'yellow gold',
    'diamond', 'diamonds', 'gemstone', 'gemstones',
    'pearl', 'pearls', 'ruby', 'rubies', 'emerald', 'emeralds',
    'sapphire', 'sapphires', 'amethyst', 'topaz', 'opal',
    'crystal', 'crystals', 'stone', 'stones',

    // Styles
    'engagement', 'wedding', 'bridal', 'anniversary',
    'vintage', 'antique', 'modern', 'contemporary',
    'minimalist', 'statement', 'luxury', 'designer',
    'traditional', 'ethnic', 'bohemian', 'art deco',

    // Occasions
    'wedding ring', 'engagement ring', 'promise ring',
    'cocktail ring', 'eternity band', 'signet ring',
    'mangalsutra', 'kada', 'jhumka', 'kundan', 'polki', 'meenakari'
  ];

  // Non-jewelry keywords to block
  static const List<String> blockedKeywords = [
    'weapon', 'gun', 'knife', 'drug', 'violence',
    'explicit', 'adult', 'nude', 'nsfw',
    'car', 'vehicle', 'house', 'building',
    'food', 'drink', 'animal', 'person', 'people',
    'landscape', 'portrait', 'selfie'
  ];

  /// Validates if the prompt is jewelry-related
  static ValidationResult validatePrompt(String prompt) {
    final lowercasePrompt = prompt.toLowerCase().trim();

    // Check if prompt is too short
    if (lowercasePrompt.length < 3) {
      return ValidationResult(
        isValid: false,
        message: 'Please provide a more detailed description.',
      );
    }

    // Check for blocked keywords
    for (final blocked in blockedKeywords) {
      if (lowercasePrompt.contains(blocked)) {
        return ValidationResult(
          isValid: false,
          message: 'Please describe a jewelry item. Your prompt seems unrelated to jewelry design.',
        );
      }
    }

    // Check for jewelry keywords
    bool hasJewelryKeyword = false;
    for (final keyword in jewelryKeywords) {
      if (lowercasePrompt.contains(keyword)) {
        hasJewelryKeyword = true;
        break;
      }
    }

    if (!hasJewelryKeyword) {
      return ValidationResult(
        isValid: false,
        message: 'Please include jewelry-related terms in your description.\n\nTry describing: rings, necklaces, bracelets, earrings, or other jewelry items.',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Enhances the user prompt for better AI generation
  static String enhancePrompt(String userPrompt) {
    // Base enhancement template for realistic jewelry photography
    final enhancedPrompt = '''
Create a photorealistic, high-quality product photograph of $userPrompt.
Professional jewelry photography with:
- Clean white or gradient background
- Professional studio lighting with soft shadows
- Ultra-detailed, 8K resolution
- Macro lens detail showing texture and craftsmanship
- Realistic metallic reflections and gemstone sparkle
- Luxury product photography style
- Sharp focus on the jewelry piece
- Natural material rendering (gold, silver, diamonds, etc.)
''';

    return enhancedPrompt.trim();
  }

  /// Provides prompt suggestions based on category
  static List<String> getPromptSuggestions({String? category}) {
    final Map<String, List<String>> suggestions = {
      'rings': [
        'Elegant solitaire diamond engagement ring in white gold',
        'Vintage-inspired ruby cocktail ring with intricate details',
        'Modern minimalist gold band with subtle texture',
        'Three-stone emerald ring with diamond accents',
      ],
      'necklaces': [
        'Delicate gold chain with pearl pendant',
        'Statement diamond necklace with graduated stones',
        'Layered silver chains with geometric pendants',
        'Traditional kundan necklace with emerald drops',
      ],
      'bracelets': [
        'Tennis bracelet with round brilliant diamonds',
        'Gold bangle set with intricate filigree work',
        'Modern cuff bracelet with geometric patterns',
        'Charm bracelet with personalized pendants',
      ],
      'earrings': [
        'Classic diamond stud earrings in platinum',
        'Chandelier earrings with cascading pearls',
        'Gold hoop earrings with twisted design',
        'Drop earrings with sapphire and diamonds',
      ],
      'default': [
        'Minimalist gold ring with single diamond',
        'Pearl necklace with silver clasp',
        'Diamond tennis bracelet',
        'Vintage pearl earrings',
        'Rose gold wedding band',
        'Emerald pendant necklace',
        'Silver charm bracelet',
        'Ruby stud earrings',
      ],
    };

    return suggestions[category?.toLowerCase()] ?? suggestions['default']!;
  }
}

/// Result of prompt validation
class ValidationResult {
  final bool isValid;
  final String? message;

  ValidationResult({
    required this.isValid,
    this.message,
  });
}