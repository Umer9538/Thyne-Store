#!/usr/bin/env dart
/// Test script for Gemini 2.5 Flash Image Generation API using Dart
/// Tests generating a minimalistic gold ring with diamond image.
///
/// Run with: dart test_gemini_image_dart.dart

import 'dart:convert';
import 'dart:io';

// API Configuration
const String apiKey = 'AIzaSyDVWMp8jiNiA5bFSKOsThYp70Bqj9MVHc4';
const String model = 'gemini-2.5-flash-image';
const String apiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

// Output directory
const String outputDir = 'generated-image';

/// Result class for image generation
class ImageGenerationResult {
  final bool success;
  final String? imagePath;
  final String? mimeType;
  final int? sizeBytes;
  final String? error;
  final String? textResponse;

  ImageGenerationResult({
    required this.success,
    this.imagePath,
    this.mimeType,
    this.sizeBytes,
    this.error,
    this.textResponse,
  });
}

/// Generate an image using Gemini 2.5 Flash Image API
Future<ImageGenerationResult> generateImage(String prompt) async {
  print('\n${'=' * 60}');
  print('Gemini 2.5 Flash Image Generation Test (Dart)');
  print('=' * 60);
  print('Prompt: $prompt');
  print('Model: $model');
  print('=' * 60 + '\n');

  final client = HttpClient();

  try {
    // Prepare the request
    final uri = Uri.parse('$apiUrl?key=$apiKey');
    final request = await client.postUrl(uri);

    // Set headers
    request.headers.set('Content-Type', 'application/json');

    // Prepare payload with responseModalities for image output
    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE']
      }
    };

    // Write the request body
    request.write(jsonEncode(payload));

    print('Sending request to Gemini API...');

    // Get response
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('Response Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('Error Response: $responseBody');
      return ImageGenerationResult(
        success: false,
        error: 'API Error ${response.statusCode}: $responseBody',
      );
    }

    // Parse JSON response
    final data = jsonDecode(responseBody) as Map<String, dynamic>;

    // Debug: Print response structure (truncated)
    final responsePreview = responseBody.length > 500
        ? '${responseBody.substring(0, 500)}...'
        : responseBody;
    print('\nResponse structure preview:');
    print(responsePreview);

    // Extract image from response
    if (data.containsKey('candidates') && (data['candidates'] as List).isNotEmpty) {
      final candidate = data['candidates'][0] as Map<String, dynamic>;

      if (candidate.containsKey('content')) {
        final content = candidate['content'] as Map<String, dynamic>;

        if (content.containsKey('parts')) {
          final parts = content['parts'] as List;
          String? textResponse;

          for (final part in parts) {
            final partMap = part as Map<String, dynamic>;

            // Check for text response
            if (partMap.containsKey('text')) {
              textResponse = partMap['text'] as String;
              print('\nText response: ${textResponse.substring(0, textResponse.length.clamp(0, 200))}...');
            }

            // Check for inline_data (base64 image)
            if (partMap.containsKey('inlineData')) {
              final inlineData = partMap['inlineData'] as Map<String, dynamic>;
              final mimeType = inlineData['mimeType'] as String? ?? 'image/png';
              final imageData = inlineData['data'] as String? ?? '';

              if (imageData.isNotEmpty) {
                // Determine file extension
                String ext = 'png';
                if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
                  ext = 'jpg';
                } else if (mimeType.contains('webp')) {
                  ext = 'webp';
                }

                // Create output directory if not exists
                final dir = Directory(outputDir);
                if (!await dir.exists()) {
                  await dir.create(recursive: true);
                }

                // Generate filename with timestamp
                final timestamp = DateTime.now()
                    .toIso8601String()
                    .replaceAll(':', '')
                    .replaceAll('-', '')
                    .substring(0, 15);
                final filename = 'gold_ring_dart_$timestamp.$ext';
                final filepath = '$outputDir/$filename';

                // Decode and save image
                final imageBytes = base64Decode(imageData);
                final file = File(filepath);
                await file.writeAsBytes(imageBytes);

                print('\n${'=' * 60}');
                print('SUCCESS! Image saved to: $filepath');
                print('File size: ${imageBytes.length} bytes');
                print('MIME type: $mimeType');
                print('=' * 60 + '\n');

                return ImageGenerationResult(
                  success: true,
                  imagePath: filepath,
                  mimeType: mimeType,
                  sizeBytes: imageBytes.length,
                  textResponse: textResponse,
                );
              }
            }
          }
        }
      }
    }

    return ImageGenerationResult(
      success: false,
      error: 'No image data found in response',
    );
  } on SocketException catch (e) {
    return ImageGenerationResult(
      success: false,
      error: 'Network error: ${e.message}',
    );
  } on FormatException catch (e) {
    return ImageGenerationResult(
      success: false,
      error: 'Failed to parse response: ${e.message}',
    );
  } catch (e) {
    return ImageGenerationResult(
      success: false,
      error: 'Unexpected error: $e',
    );
  } finally {
    client.close();
  }
}

/// Main function to test image generation
Future<void> main() async {
  // Test prompt
  const prompt = 'Create a minimalistic Gold ring with a diamond on it.';

  // Generate image
  final result = await generateImage(prompt);

  // Print result
  print('\n${'=' * 60}');
  print('FINAL RESULT');
  print('=' * 60);

  if (result.success) {
    print('Status: SUCCESS');
    print('Image saved to: ${result.imagePath}');
    print('Size: ${result.sizeBytes} bytes');
    print('Type: ${result.mimeType}');
    if (result.textResponse != null) {
      print('AI Description: ${result.textResponse!.substring(0, result.textResponse!.length.clamp(0, 100))}...');
    }
  } else {
    print('Status: FAILED');
    print('Error: ${result.error}');
  }

  print('=' * 60 + '\n');
}
