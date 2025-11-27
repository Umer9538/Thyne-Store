import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  const apiKey = 'AIzaSyDVWMp8jiNiA5bFSKOsThYp70Bqj9MVHc4';

  print('Testing Gemini API connection...\n');

  // Try different model names
  final modelNames = [
    'gemini-pro',
    'gemini-1.0-pro',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];

  for (final modelName in modelNames) {
    print('Testing model: $modelName');
    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      );

      final content = [Content.text('Say hello')];
      final response = await model.generateContent(content);

      if (response.text != null) {
        print('✅ Success! Response: ${response.text!.substring(0, 50)}...');
        print('   This model works!\n');
      }
    } catch (e) {
      print('❌ Error: ${e.toString().split('\n')[0]}\n');
    }
  }

  print('Test complete!');
}