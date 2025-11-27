import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/prompt_validator.dart';

class ImageGenerationService {
  final Dio _dio;

  // Using Hugging Face's free API for image generation
  // You can replace this with your preferred image generation API
  static const String _huggingFaceToken = 'hf_YOUR_TOKEN_HERE'; // Replace with actual token
  static const String _apiUrl = 'https://api-inference.huggingface.co/models/';

  // Alternative free model options:
  // - stabilityai/stable-diffusion-2-1
  // - prompthero/openjourney
  // - SG161222/Realistic_Vision_V1.4
  static const String _modelId = 'SG161222/Realistic_Vision_V1.4';

  // Singleton pattern
  static final ImageGenerationService _instance = ImageGenerationService._internal();
  factory ImageGenerationService() => _instance;

  ImageGenerationService._internal() : _dio = Dio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Authorization': 'Bearer $_huggingFaceToken',
        'Content-Type': 'application/json',
      },
    );
  }

  /// Generates a jewelry image from text prompt
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
      final enhancedPrompt = PromptValidator.enhancePrompt(userPrompt);

      // Make API request
      final response = await _dio.post(
        '$_apiUrl$_modelId',
        data: jsonEncode({
          'inputs': enhancedPrompt,
          'parameters': {
            'negative_prompt': 'blurry, bad quality, distorted, deformed, ugly, cartoon, anime, drawing, sketch',
            'num_inference_steps': 50,
            'guidance_scale': 7.5,
          },
        }),
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Convert bytes to base64 for storage
        final base64Image = base64Encode(response.data);

        return ImageGenerationResult(
          success: true,
          imageData: response.data,
          base64Image: base64Image,
          prompt: userPrompt,
          enhancedPrompt: enhancedPrompt,
        );
      } else {
        throw Exception('Failed to generate image: ${response.statusCode}');
      }

    } on DioException catch (e) {
      print('DioError generating image: ${e.message}');

      // Handle specific error cases
      if (e.response?.statusCode == 503) {
        return ImageGenerationResult(
          success: false,
          errorMessage: 'Model is loading. Please try again in a few seconds.',
        );
      }

      return ImageGenerationResult(
        success: false,
        errorMessage: 'Network error: ${e.message}',
      );
    } catch (e) {
      print('Error generating image: $e');
      return ImageGenerationResult(
        success: false,
        errorMessage: 'Failed to generate image. Please try again.',
      );
    }
  }

  /// Alternative method using a mock/placeholder service for testing
  Future<ImageGenerationResult> generatePlaceholderImage(String userPrompt) async {
    try {
      // Validate prompt
      final validation = PromptValidator.validatePrompt(userPrompt);
      if (!validation.isValid) {
        return ImageGenerationResult(
          success: false,
          errorMessage: validation.message,
        );
      }

      final enhancedPrompt = PromptValidator.enhancePrompt(userPrompt);

      // Generate a simple placeholder image using a public API that doesn't have CORS issues
      // Using DiceBear API to generate unique avatars/patterns
      final seed = userPrompt.replaceAll(' ', '_');
      final randomId = DateTime.now().millisecondsSinceEpoch;

      // Use a placeholder image service that works with CORS
      final imageUrl = 'https://api.dicebear.com/7.x/shapes/svg?seed=$seed$randomId&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';

      // For now, just return the URL directly
      return ImageGenerationResult(
        success: true,
        imageUrl: imageUrl,
        prompt: userPrompt,
        enhancedPrompt: enhancedPrompt,
      );

    } catch (e) {
      print('Error generating placeholder: $e');

      // Fallback to a simple data URL if SVG generation fails
      final fallbackSvg = '''
<svg width="800" height="800" xmlns="http://www.w3.org/2000/svg">
  <rect width="800" height="800" fill="#e0e0e0"/>
  <text x="400" y="400" font-family="Arial" font-size="32" fill="#666" text-anchor="middle">
    Jewelry Design
  </text>
</svg>
      ''';

      final svgBytes = utf8.encode(fallbackSvg);
      final base64String = base64Encode(svgBytes);
      final dataUrl = 'data:image/svg+xml;base64,$base64String';

      return ImageGenerationResult(
        success: true,
        imageUrl: dataUrl,
        prompt: userPrompt,
        enhancedPrompt: PromptValidator.enhancePrompt(userPrompt),
      );
    }
  }
}

/// Result of image generation
class ImageGenerationResult {
  final bool success;
  final dynamic imageData; // Uint8List of image bytes
  final String? base64Image;
  final String? imageUrl;
  final String? prompt;
  final String? enhancedPrompt;
  final String? errorMessage;

  ImageGenerationResult({
    required this.success,
    this.imageData,
    this.base64Image,
    this.imageUrl,
    this.prompt,
    this.enhancedPrompt,
    this.errorMessage,
  });

  bool get hasImage => imageData != null || imageUrl != null || base64Image != null;
}