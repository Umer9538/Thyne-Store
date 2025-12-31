import 'package:flutter/material.dart';
import 'package:thyne_jewls/utils/theme.dart';
import 'package:thyne_jewls/data/services/api_service.dart';
import 'package:thyne_jewls/data/models/product.dart';

class CreateShowcaseForm extends StatefulWidget {
  const CreateShowcaseForm({super.key});

  @override
  State<CreateShowcaseForm> createState() => _CreateShowcaseFormState();
}

class _CreateShowcaseFormState extends State<CreateShowcaseForm> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _loadingProducts = false;

  // Form fields
  Product? _selectedProduct;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  final List<TextEditingController> _imageControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _priority = 1;

  List<Product> _availableProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _thumbnailUrlController.dispose();
    for (var controller in _imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final response = await ApiService.getProducts(limit: 100);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> productsList;

        // Handle different response formats
        if (data is List) {
          productsList = data;
        } else if (data is Map && data['products'] != null) {
          productsList = data['products'] as List;
        } else if (data is Map && data['items'] != null) {
          productsList = data['items'] as List;
        } else {
          productsList = [];
        }

        setState(() {
          _availableProducts = productsList
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
    setState(() => _loadingProducts = false);
  }

  Future<void> _saveShowcase() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    final images360 = _imageControllers
        .map((c) => c.text.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    if (images360.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least 4 images for 360° rotation')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await ApiService.createShowcase360(
        productId: _selectedProduct!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        images: images360,
        videoUrl: _videoUrlController.text.trim().isNotEmpty
            ? _videoUrlController.text.trim()
            : null,
        priority: _priority,
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('360° Showcase created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response['error'] ?? 'Failed to create showcase'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating showcase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Text(
                  'Select Product',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _availableProducts.length,
                        itemBuilder: (context, index) {
                          final product = _availableProducts[index];
                          final isSelected = _selectedProduct?.id == product.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: RadioListTile<String>(
                              value: product.id,
                              groupValue: _selectedProduct?.id,
                              onChanged: (value) {
                                setState(() => _selectedProduct = product);
                                Navigator.pop(context);
                              },
                              activeColor: AppTheme.primaryGold,
                              title: Text(
                                product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '\$${product.price.toStringAsFixed(2)} • Stock: ${product.stock}',
                              ),
                              secondary: product.images.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product.images.first,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.image),
                                          );
                                        },
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addImageField() {
    setState(() {
      _imageControllers.add(TextEditingController());
    });
  }

  void _removeImageField(int index) {
    if (_imageControllers.length > 4) {
      setState(() {
        _imageControllers[index].dispose();
        _imageControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create 360° Showcase'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveShowcase,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Selection
              Text(
                'Product',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _showProductPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (_selectedProduct?.images.isNotEmpty ?? false)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _selectedProduct!.images.first,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image),
                              );
                            },
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedProduct?.name ?? 'Tap to select product',
                              style: TextStyle(
                                fontWeight: _selectedProduct != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedProduct != null
                                    ? Colors.black
                                    : Colors.grey.shade600,
                              ),
                            ),
                            if (_selectedProduct != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '\$${_selectedProduct!.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppTheme.primaryGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Basic Info
              Text(
                'Showcase Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Stunning Diamond Ring 360° View',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the showcase',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // 360° Images
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '360° Images',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addImageField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Image'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Add at least 4 images taken from different angles (every 45-90°)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              ...List.generate(_imageControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imageControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Image ${index + 1} URL',
                            hintText: 'https://example.com/image${index + 1}.jpg',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.image),
                          ),
                          validator: (value) {
                            if (index < 4 && (value == null || value.isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_imageControllers.length > 4)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeImageField(index),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Video & Thumbnail
              Text(
                'Additional Media',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL (Optional)',
                  hintText: 'https://example.com/video.mp4',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.videocam),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _thumbnailUrlController,
                decoration: const InputDecoration(
                  labelText: 'Thumbnail URL (Optional)',
                  hintText: 'https://example.com/thumbnail.jpg',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.photo),
                ),
              ),

              const SizedBox(height: 32),

              // Priority
              Text(
                'Display Priority',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Higher priority showcases appear first',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _priority.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _priority.toString(),
                      activeColor: AppTheme.primaryGold,
                      onChanged: (value) {
                        setState(() => _priority = value.toInt());
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _priority.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Preview
              Text(
                'Preview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.rotate_right, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '360° SHOWCASE',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _titleController.text.isEmpty
                          ? 'Showcase Title'
                          : _titleController.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (_descriptionController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _descriptionController.text,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_imageControllers.where((c) => c.text.isNotEmpty).length} Images',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (_videoUrlController.text.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.videocam, size: 12, color: Colors.purple.shade900),
                                const SizedBox(width: 4),
                                Text(
                                  'Video',
                                  style: TextStyle(
                                    color: Colors.purple.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
