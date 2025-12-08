#!/usr/bin/env python3
"""
Test script for Gemini 2.5 Flash Image Generation API
Tests generating a minimalistic gold ring with diamond image.
"""

import base64
import json
import os
import requests
from datetime import datetime

# API Configuration
API_KEY = 'AIzaSyDVWMp8jiNiA5bFSKOsThYp70Bqj9MVHc4'
MODEL = 'gemini-2.5-flash-image'  # Production model for image generation
API_URL = f'https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent'

# Output directory
OUTPUT_DIR = 'generated-image'

def generate_image(prompt: str) -> dict:
    """
    Generate an image using Gemini 2.5 Flash Image Generation API.

    Args:
        prompt: The text prompt for image generation

    Returns:
        Dictionary with success status and image path or error message
    """
    print(f"\n{'='*60}")
    print(f"Gemini 2.5 Flash Image Generation Test")
    print(f"{'='*60}")
    print(f"Prompt: {prompt}")
    print(f"Model: {MODEL}")
    print(f"{'='*60}\n")

    headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': API_KEY
    }

    payload = {
        'contents': [{
            'parts': [{
                'text': prompt
            }]
        }],
        'generationConfig': {
            'responseModalities': ['TEXT', 'IMAGE']
        }
    }

    try:
        print("Sending request to Gemini API...")
        response = requests.post(API_URL, headers=headers, json=payload, timeout=60)

        print(f"Response Status: {response.status_code}")

        if response.status_code != 200:
            error_detail = response.text
            print(f"Error Response: {error_detail}")
            return {
                'success': False,
                'error': f"API Error {response.status_code}: {error_detail}"
            }

        data = response.json()

        # Debug: Print response structure
        print(f"\nResponse structure:")
        print(json.dumps(data, indent=2, default=str)[:1000] + "...")

        # Extract image from response
        if 'candidates' in data and len(data['candidates']) > 0:
            candidate = data['candidates'][0]

            if 'content' in candidate and 'parts' in candidate['content']:
                parts = candidate['content']['parts']

                for i, part in enumerate(parts):
                    # Check for inline_data (base64 image)
                    if 'inlineData' in part:
                        inline_data = part['inlineData']
                        mime_type = inline_data.get('mimeType', 'image/png')
                        image_data = inline_data.get('data', '')

                        if image_data:
                            # Determine file extension
                            ext = 'png'
                            if 'jpeg' in mime_type or 'jpg' in mime_type:
                                ext = 'jpg'
                            elif 'webp' in mime_type:
                                ext = 'webp'

                            # Create output directory if not exists
                            os.makedirs(OUTPUT_DIR, exist_ok=True)

                            # Generate filename with timestamp
                            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                            filename = f"gold_ring_{timestamp}.{ext}"
                            filepath = os.path.join(OUTPUT_DIR, filename)

                            # Decode and save image
                            image_bytes = base64.b64decode(image_data)
                            with open(filepath, 'wb') as f:
                                f.write(image_bytes)

                            print(f"\n{'='*60}")
                            print(f"SUCCESS! Image saved to: {filepath}")
                            print(f"File size: {len(image_bytes)} bytes")
                            print(f"MIME type: {mime_type}")
                            print(f"{'='*60}\n")

                            return {
                                'success': True,
                                'image_path': filepath,
                                'mime_type': mime_type,
                                'size_bytes': len(image_bytes)
                            }

                    # Check for text response
                    if 'text' in part:
                        print(f"\nText response: {part['text'][:500]}...")

        return {
            'success': False,
            'error': 'No image data found in response'
        }

    except requests.exceptions.Timeout:
        return {
            'success': False,
            'error': 'Request timed out after 60 seconds'
        }
    except requests.exceptions.RequestException as e:
        return {
            'success': False,
            'error': f'Network error: {str(e)}'
        }
    except json.JSONDecodeError as e:
        return {
            'success': False,
            'error': f'Failed to parse response: {str(e)}'
        }
    except Exception as e:
        return {
            'success': False,
            'error': f'Unexpected error: {str(e)}'
        }


def main():
    """Main function to test image generation."""

    # Test prompt
    prompt = "Create a minimalistic Gold ring with a diamond on it."

    # Generate image
    result = generate_image(prompt)

    # Print result
    print("\n" + "="*60)
    print("FINAL RESULT")
    print("="*60)

    if result['success']:
        print(f"Status: SUCCESS")
        print(f"Image saved to: {result['image_path']}")
        print(f"Size: {result['size_bytes']} bytes")
        print(f"Type: {result['mime_type']}")
    else:
        print(f"Status: FAILED")
        print(f"Error: {result['error']}")

    print("="*60 + "\n")

    return result


if __name__ == '__main__':
    main()
