import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/glass/glass_ui.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  String _uploadStatus = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          // Limit to 10 images
          if (_selectedImages.length > 10) {
            _selectedImages.removeRange(10, _selectedImages.length);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  Future<void> _pickCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<List<String>> _uploadImages() async {
    final List<String> uploadedUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      setState(() {
        _uploadStatus = 'Uploading image ${i + 1} of ${_selectedImages.length}...';
      });

      try {
        final image = _selectedImages[i];
        final bytes = await image.readAsBytes();
        final fileName = image.name;

        Map<String, dynamic> response;

        if (kIsWeb) {
          // For web, use base64 encoding
          final base64Image = base64Encode(bytes);
          response = await ApiService.uploadCommunityImageBase64(base64Image, fileName);
        } else {
          // For mobile, use multipart upload
          response = await ApiService.uploadCommunityImage(bytes, fileName);
        }

        if (response['success'] == true && response['data'] != null) {
          final url = response['data']['url'] ?? response['data']['imageUrl'];
          if (url != null) {
            uploadedUrls.add(url);
          }
        } else {
          // If upload fails, use a placeholder URL for now
          // TODO: Remove this when backend image upload is implemented
          debugPrint('Upload failed for $fileName, upload endpoint may not exist yet');
        }
      } catch (e) {
        debugPrint('Error uploading image: $e');
      }
    }

    return uploadedUrls;
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some content or images'),
        ),
      );
      return;
    }

    // Check if user is authenticated
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to create a post'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadStatus = 'Preparing...';
    });

    try {
      final provider = Provider.of<CommunityProvider>(context, listen: false);

      // Upload images first
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();

        // If some images failed to upload, show warning
        if (imageUrls.length < _selectedImages.length) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_selectedImages.length - imageUrls.length} images failed to upload'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      setState(() {
        _uploadStatus = 'Creating post...';
      });

      final success = await provider.createPost(
        content: _contentController.text.trim(),
        images: imageUrls.isNotEmpty ? imageUrls : null,
        tags: _tags.isNotEmpty ? _tags : null,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show actual error from provider if available
          final errorMessage = provider.error ?? 'Failed to create post. Please make sure you are logged in.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Create Post'),
        actions: [
          if (_isSubmitting)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    if (_uploadStatus.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        _uploadStatus,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitPost,
              child: const Text(
                'POST',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Content input
            TextFormField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value == null || value.trim().isEmpty) &&
                    _selectedImages.isEmpty) {
                  return 'Please enter some content or add images';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Selected images
            if (_selectedImages.isNotEmpty) ...[
              const Text(
                'Selected Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImagePreview(_selectedImages[index]),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GlassIconButton(
                            icon: Icons.close,
                            onPressed: () => _removeImage(index),
                            size: 28,
                            tintColor: AppTheme.errorRed,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Image picker buttons
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    text: '',
                    onPressed: _selectedImages.length < 10 ? _pickImages : null,
                    enabled: _selectedImages.length < 10,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    blur: GlassConfig.softBlur,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 20),
                        SizedBox(width: 8),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlassButton(
                    text: '',
                    onPressed: _selectedImages.length < 10 ? _pickCamera : null,
                    enabled: _selectedImages.length < 10,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    blur: GlassConfig.softBlur,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Camera'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_selectedImages.length >= 10)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Maximum 10 images allowed',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Tags section
            const Text(
              'Tags (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Add tag',
                      border: OutlineInputBorder(),
                      prefixText: '#',
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                GlassIconButton(
                  icon: Icons.add,
                  onPressed: _addTag,
                  size: 40,
                  tintColor: AppTheme.primaryGold,
                ),
              ],
            ),

            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    blur: GlassConfig.softBlur,
                    borderRadius: BorderRadius.circular(16),
                    tintColor: AppTheme.primaryGold,
                    showGlow: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#$tag',
                          style: const TextStyle(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeTag(tag),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              height: 50,
              child: GlassPrimaryButton(
                text: 'CREATE POST',
                onPressed: _isSubmitting ? null : _submitPost,
                enabled: !_isSubmitting,
                isLoading: _isSubmitting,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(XFile image) {
    if (kIsWeb) {
      // For web, use FutureBuilder to load bytes
      return FutureBuilder<List<int>>(
        future: image.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data! as dynamic,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      // For mobile, use File
      return Image.file(
        File(image.path),
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    }
  }
}
