import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../utils/prompt_validator.dart';

/// Service for generating jewelry images using Gemini 2.5 Flash Image API
class ImageGenerationService {
  // Gemini API Configuration - Updated API key
  static const String _apiKey = 'AIzaSyBEPj4z2lIuAap-4fJnbzBcGzD-Qg2Lpq0';
  static const String _model = 'gemini-2.5-flash-image';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  // Singleton pattern
  static final ImageGenerationService _instance = ImageGenerationService._internal();
  factory ImageGenerationService() => _instance;
  ImageGenerationService._internal();

  /// Generates a jewelry image using Gemini 2.5 Flash Image API
  /// Returns base64 encoded PNG image
  Future<ImageGenerationResult> generateJewelryImage(String userPrompt) async {
    try {
      // Validate prompt
      final validation = PromptValidator.validatePrompt(userPrompt);
      if (!validation.isValid) {
        return ImageGenerationResult(
          success: false,
          errorMessage: validation.message,
        );
      }

      // Enhance prompt for jewelry generation
      final enhancedPrompt = _createJewelryPrompt(userPrompt);
      print('🎨 ImageGen: Starting generation with prompt: $userPrompt');
      print('🎨 ImageGen: Enhanced prompt: $enhancedPrompt');

      // Prepare the API request
      final uri = Uri.parse('$_apiUrl?key=$_apiKey');

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': enhancedPrompt}
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE']
        }
      };

      print('🎨 ImageGen: Sending request to Gemini API...');

      // Make HTTP request
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 60));

      print('🎨 ImageGen: Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('🎨 ImageGen: Error response: ${response.body}');
        return ImageGenerationResult(
          success: false,
          errorMessage: 'API Error ${response.statusCode}: Failed to generate image',
        );
      }

      // Parse response
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Extract image and text from response
      String? base64Image;
      String? mimeType;
      String? textResponse;

      if (data.containsKey('candidates') && (data['candidates'] as List).isNotEmpty) {
        final candidate = data['candidates'][0] as Map<String, dynamic>;

        if (candidate.containsKey('content')) {
          final content = candidate['content'] as Map<String, dynamic>;

          if (content.containsKey('parts')) {
            final parts = content['parts'] as List;

            for (final part in parts) {
              final partMap = part as Map<String, dynamic>;

              // Extract text response (AI description)
              if (partMap.containsKey('text')) {
                textResponse = partMap['text'] as String;
                print('🎨 ImageGen: Got text response: ${textResponse.substring(0, textResponse.length.clamp(0, 100))}...');
              }

              // Extract image data
              if (partMap.containsKey('inlineData')) {
                final inlineData = partMap['inlineData'] as Map<String, dynamic>;
                mimeType = inlineData['mimeType'] as String? ?? 'image/png';
                base64Image = inlineData['data'] as String?;

                if (base64Image != null && base64Image.isNotEmpty) {
                  print('🎨 ImageGen: Got image data, mime: $mimeType, size: ${base64Image.length} chars');
                }
              }
            }
          }
        }
      }

      if (base64Image != null && base64Image.isNotEmpty) {
        // Create data URL for the image
        final imageUrl = 'data:$mimeType;base64,$base64Image';

        print('🎨 ImageGen: SUCCESS! Image generated');

        return ImageGenerationResult(
          success: true,
          base64Image: base64Image,
          imageUrl: imageUrl,
          mimeType: mimeType,
          prompt: userPrompt,
          enhancedPrompt: enhancedPrompt,
          aiDescription: textResponse,
        );
      } else {
        print('🎨 ImageGen: No image data in response');
        return ImageGenerationResult(
          success: false,
          errorMessage: 'No image was generated. Please try a different prompt.',
        );
      }
    } on http.ClientException catch (e) {
      print('🎨 ImageGen: Network error: $e');
      return ImageGenerationResult(
        success: false,
        errorMessage: 'Network error: Please check your internet connection.',
      );
    } on FormatException catch (e) {
      print('🎨 ImageGen: Parse error: $e');
      return ImageGenerationResult(
        success: false,
        errorMessage: 'Failed to process the response.',
      );
    } catch (e) {
      print('🎨 ImageGen: Unexpected error: $e');
      return ImageGenerationResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Creates an enhanced jewelry-specific prompt for better image generation
  /// IMPORTANT: Always generates PROFILE VIEW for CAD designers
  String _createJewelryPrompt(String userPrompt) {
    // Get the basic enhanced prompt
    final baseEnhanced = PromptValidator.enhancePrompt(userPrompt);

    // Add specific jewelry photography instructions for Gemini
    // CRITICAL: Profile view is mandatory for CAD design compatibility
    return '''Create a professional jewelry design image of: $baseEnhanced

MANDATORY VIEW REQUIREMENTS (for CAD design):
- PROFILE VIEW / SIDE VIEW angle - This is critical
- Show the jewelry piece from a side/profile angle that clearly displays:
  * Depth and dimension of the piece
  * Silhouette and outline
  * Setting heights and stone positions
  * Band/chain thickness from the side
- The profile view should be suitable for technical CAD reference

Style requirements:
- High-end jewelry product photography
- Clean, elegant composition
- Soft studio lighting with subtle reflections
- Pure white or neutral gradient background
- Sharp focus on the jewelry piece
- Photorealistic quality
- No text, watermarks, or hands
- Single jewelry piece, centered''';
  }

  /// Fallback method using placeholder (for testing without API)
  Future<ImageGenerationResult> generatePlaceholderImage(String userPrompt) async {
    // Just call the real API now
    return generateJewelryImage(userPrompt);
  }

  /// Decode base64 image to bytes (utility method)
  Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return null;
    }
  }
}

/// Result of image generation
class ImageGenerationResult {
  final bool success;
  final Uint8List? imageData;
  final String? base64Image;
  final String? imageUrl;
  final String? mimeType;
  final String? prompt;
  final String? enhancedPrompt;
  final String? aiDescription;
  final String? errorMessage;

  ImageGenerationResult({
    required this.success,
    this.imageData,
    this.base64Image,
    this.imageUrl,
    this.mimeType,
    this.prompt,
    this.enhancedPrompt,
    this.aiDescription,
    this.errorMessage,
  });

  bool get hasImage => base64Image != null || imageUrl != null;
}
