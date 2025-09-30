import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/theme.dart';
import '../../../models/product.dart';
import '../../../services/api_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _materialController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();

  String _selectedCategory = 'Rings';
  String _selectedSubcategory = 'Engagement Rings';
  String _selectedMetalType = 'Gold';
  String _selectedStoneType = 'Diamond';
  bool _isAvailable = true;
  bool _isFeatured = false;
  List<String> _imageUrls = [];
  String? _videoUrl;

  String _sanitizeNumericString(String input, {bool allowDecimal = true, bool allowNegative = false}) {
    final pattern = allowDecimal
        ? (allowNegative ? RegExp(r'[^0-9.\-]') : RegExp(r'[^0-9.]'))
        : (allowNegative ? RegExp(r'[^0-9\-]') : RegExp(r'[^0-9]'));
    // Remove all non-allowed characters
    String cleaned = input.replaceAll(pattern, '');
    // Normalize to a valid numeric format: keep only first dot and first leading minus
    if (allowDecimal) {
      final parts = cleaned.split('.');
      if (parts.length > 2) {
        cleaned = parts.first + '.' + parts.sublist(1).join('');
      }
    }
    if (allowNegative && cleaned.contains('-')) {
      // Keep only a single leading minus
      cleaned = (cleaned.startsWith('-') ? '-' : '') + cleaned.replaceAll('-', '');
    } else {
      cleaned = cleaned.replaceAll('-', '');
    }
    return cleaned;
  }

  double? _parseNullableDouble(String input) {
    final trimmed = _sanitizeNumericString(input, allowDecimal: true, allowNegative: false).trim();
    if (trimmed.isEmpty) return null;
    return double.parse(trimmed);
  }

  double _parseRequiredDouble(String input) {
    final trimmed = _sanitizeNumericString(input, allowDecimal: true, allowNegative: false).trim();
    return double.parse(trimmed);
  }

  int _parseRequiredInt(String input) {
    final trimmed = _sanitizeNumericString(input, allowDecimal: false, allowNegative: false).trim();
    return int.parse(trimmed);
  }

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _originalPriceController.text = product.originalPrice?.toString() ?? '';
    _stockController.text = product.stockQuantity.toString();
    _materialController.text = product.metalType;
    _weightController.text = product.weight?.toString() ?? '';
    _dimensionsController.text = product.size ?? '';
    // Ensure dropdown values always match available items to avoid assertion errors
    // Category and Subcategory
    final availableCategories = ['Rings', 'Necklaces', 'Earrings', 'Bracelets', 'Pendants'];
    _selectedCategory = availableCategories.contains(product.category)
        ? product.category
        : availableCategories.first;
    final availableSubcategories = _getSubcategories(_selectedCategory);
    _selectedSubcategory = availableSubcategories.contains(product.subcategory)
        ? product.subcategory
        : availableSubcategories.first;
    // Metal Type
    final availableMetalTypes = ['Gold', 'Silver', 'Platinum', 'Rose Gold', 'White Gold'];
    _selectedMetalType = availableMetalTypes.contains(product.metalType)
        ? product.metalType
        : availableMetalTypes.first;
    // Stone Type (nullable in model)
    final availableStoneTypes = ['Diamond', 'Ruby', 'Emerald', 'Sapphire', 'Pearl', 'None'];
    final stoneType = product.stoneType ?? 'None';
    _selectedStoneType = availableStoneTypes.contains(stoneType)
        ? stoneType
        : 'None';
    _isAvailable = product.isAvailable;
    _isFeatured = product.isFeatured;
    _imageUrls = List.from(product.images);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _materialController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveProduct,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
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
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: 'Product Name',
                validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // Category Section
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration('Category'),
                      items: ['Rings', 'Necklaces', 'Earrings', 'Bracelets', 'Pendants']
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          _selectedSubcategory = _getSubcategories(value)[0];
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubcategory,
                      decoration: _inputDecoration('Subcategory'),
                      items: _getSubcategories(_selectedCategory)
                          .map((subcategory) => DropdownMenuItem(
                                value: subcategory,
                                child: Text(subcategory),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubcategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pricing Section
              _buildSectionHeader('Pricing'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Selling Price (₹)',
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty == true ? 'Price is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _originalPriceController,
                      label: 'Original Price (₹)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Inventory Section
              _buildSectionHeader('Inventory'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _stockController,
                label: 'Stock Quantity',
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Stock quantity is required' : null,
              ),
              const SizedBox(height: 24),

              // Product Details Section
              _buildSectionHeader('Product Details'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMetalType,
                      decoration: _inputDecoration('Metal Type'),
                      items: ['Gold', 'Silver', 'Platinum', 'Rose Gold', 'White Gold']
                          .map((metal) => DropdownMenuItem(
                                value: metal,
                                child: Text(metal),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMetalType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStoneType,
                      decoration: _inputDecoration('Stone Type'),
                      items: ['Diamond', 'Ruby', 'Emerald', 'Sapphire', 'Pearl', 'None']
                          .map((stone) => DropdownMenuItem(
                                value: stone,
                                child: Text(stone),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStoneType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _materialController,
                label: 'Material Details',
                placeholder: 'e.g., 18K Gold, 925 Silver',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: 'Weight',
                      placeholder: 'e.g., 2.5g',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _dimensionsController,
                      label: 'Dimensions',
                      placeholder: 'e.g., 15mm x 10mm',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Images Section
              _buildSectionHeader('Product Images'),
              const SizedBox(height: 12),
              _buildImageUploadSection(),
              const SizedBox(height: 24),

              // Video Section
              _buildSectionHeader('Product Video (Optional)'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: TextEditingController(text: _videoUrl ?? ''),
                label: 'Video URL',
                placeholder: 'https://example.com/video.mp4',
                onChanged: (value) => _videoUrl = value,
              ),
              const SizedBox(height: 24),

              // Settings Section
              _buildSectionHeader('Settings'),
              const SizedBox(height: 12),
              _buildSwitchTile('Available for Sale', _isAvailable, (value) {
                setState(() {
                  _isAvailable = value;
                });
              }),
              _buildSwitchTile('Featured Product', _isFeatured, (value) {
                setState(() {
                  _isFeatured = value;
                });
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGold,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? placeholder,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, placeholder),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label, [String? hint]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryGold),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imageUrls.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _imageUrls[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imageUrls.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.errorRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: _addImageUrl,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Image URL'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryGold,
            side: const BorderSide(color: AppTheme.primaryGold),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, void Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryGold,
      contentPadding: EdgeInsets.zero,
    );
  }

  List<String> _getSubcategories(String category) {
    switch (category) {
      case 'Rings':
        return ['Engagement Rings', 'Wedding Rings', 'Fashion Rings', 'Statement Rings'];
      case 'Necklaces':
        return ['Chain Necklaces', 'Pendant Necklaces', 'Chokers', 'Statement Necklaces'];
      case 'Earrings':
        return ['Stud Earrings', 'Drop Earrings', 'Hoop Earrings', 'Chandelier Earrings'];
      case 'Bracelets':
        return ['Chain Bracelets', 'Bangle Bracelets', 'Charm Bracelets', 'Tennis Bracelets'];
      case 'Pendants':
        return ['Diamond Pendants', 'Gold Pendants', 'Silver Pendants', 'Custom Pendants'];
      default:
        return ['General'];
    }
  }

  void _addImageUrl() {
    showDialog(
      context: context,
      builder: (context) {
        final urlController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Image URL'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              hintText: 'https://example.com/image.jpg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (urlController.text.isNotEmpty) {
                  setState(() {
                    _imageUrls.add(urlController.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final productData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': _parseRequiredDouble(_priceController.text),
          'originalPrice': _originalPriceController.text.isNotEmpty
              ? _parseNullableDouble(_originalPriceController.text)
              : null,
          'stockQuantity': _parseRequiredInt(_stockController.text),
          'category': _selectedCategory,
          'subcategory': _selectedSubcategory,
          'metalType': _selectedMetalType,
          'stoneType': _selectedStoneType,
          'material': _materialController.text,
          'weight': _weightController.text.isNotEmpty ? _parseNullableDouble(_weightController.text) : null,
          'size': _dimensionsController.text,
          'images': _imageUrls,
          'videoUrl': _videoUrl,
          'isAvailable': _isAvailable,
          'isFeatured': _isFeatured,
          'tags': [], // Add tags if needed
        };

        if (widget.product != null) {
          // Update existing product
          await ApiService.updateProduct(
            productId: widget.product!.id,
            productData: productData,
          );
        } else {
          // Create new product
          await ApiService.createProduct(productData: productData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null
                  ? 'Product updated successfully'
                  : 'Product added successfully',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}