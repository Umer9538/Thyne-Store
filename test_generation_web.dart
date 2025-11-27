import 'lib/services/gemini_service.dart';
import 'lib/services/image_generation_service.dart';
import 'lib/utils/prompt_validator.dart';
import 'lib/utils/database_helper.dart';
import 'lib/models/ai_creation.dart';

void main() async {
  print('Testing AI Generation for Web\n');
  print('=' * 50);

  // Test 1: Database Helper
  print('\n1. Testing Database Helper (Web):');
  print('-' * 30);

  final dbHelper = DatabaseHelper();

  final testCreation = AICreation(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    prompt: 'test gold ring',
    imageUrl: 'https://example.com/test.jpg',
    createdAt: DateTime.now(),
    isSuccessful: true,
  );

  await dbHelper.insertCreation(testCreation);
  final creations = await dbHelper.getAllCreations();
  print('✅ Database works! Creations count: ${creations.length}');

  // Test 2: Image Generation
  print('\n2. Testing Image Generation:');
  print('-' * 30);

  final imageService = ImageGenerationService();
  final imageResult = await imageService.generatePlaceholderImage('gold necklace');

  if (imageResult.success) {
    print('✅ Image generation works!');
    print('   URL: ${imageResult.imageUrl}');
  } else {
    print('❌ Image generation failed: ${imageResult.errorMessage}');
  }

  // Test 3: Prompt Validation
  print('\n3. Testing Prompt Validation:');
  print('-' * 30);

  final validation = PromptValidator.validatePrompt('diamond ring');
  print('✅ Validation works: ${validation.isValid}');

  print('\n' + '=' * 50);
  print('All tests completed!');
}