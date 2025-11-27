import 'dart:io';
import 'lib/services/gemini_service.dart';
import 'lib/services/image_generation_service.dart';
import 'lib/utils/prompt_validator.dart';

void main() async {
  print('Testing AI Jewelry Generation System\n');
  print('=' * 50);

  // Test 1: Prompt Validation
  print('\n1. Testing Prompt Validation:');
  print('-' * 30);

  final validPrompts = [
    'gold necklace with diamonds',
    'silver ring with emerald stone',
    'pearl bracelet for wedding',
  ];

  final invalidPrompts = [
    'car with wheels',
    'house in the city',
    'food recipe',
  ];

  for (final prompt in validPrompts) {
    final validation = PromptValidator.validatePrompt(prompt);
    print('✅ "$prompt" - Valid: ${validation.isValid}');
  }

  for (final prompt in invalidPrompts) {
    final validation = PromptValidator.validatePrompt(prompt);
    print('❌ "$prompt" - Valid: ${validation.isValid} (${validation.message})');
  }

  // Test 2: Gemini Service
  print('\n2. Testing Gemini Service:');
  print('-' * 30);

  final geminiService = GeminiService();
  final testPrompt = 'elegant gold necklace with diamonds for wedding';

  print('Generating design for: "$testPrompt"');
  final result = await geminiService.generateJewelryDesign(testPrompt);

  if (result.success) {
    print('✅ Design generated successfully!');
    print('Enhanced prompt: ${result.enhancedPrompt}');
    if (result.designDescription != null) {
      print('Description: ${result.designDescription!.substring(0, 200)}...');
    }
  } else {
    print('❌ Failed: ${result.errorMessage}');
  }

  // Test 3: Image Generation (Placeholder)
  print('\n3. Testing Image Generation:');
  print('-' * 30);

  final imageService = ImageGenerationService();
  print('Generating placeholder image...');
  final imageResult = await imageService.generatePlaceholderImage(testPrompt);

  if (imageResult.success) {
    print('✅ Image generated successfully!');
    print('Has image data: ${imageResult.hasImage}');
    if (imageResult.imageUrl != null) {
      print('URL: ${imageResult.imageUrl}');
    }
  } else {
    print('❌ Failed: ${imageResult.errorMessage}');
  }

  // Test 4: Suggestions
  print('\n4. Testing Suggestions:');
  print('-' * 30);

  final suggestions = PromptValidator.getPromptSuggestions(category: 'wedding');
  print('Wedding jewelry suggestions:');
  for (final suggestion in suggestions.take(3)) {
    print('  - $suggestion');
  }

  print('\n' + '=' * 50);
  print('All tests completed!');

  exit(0);
}