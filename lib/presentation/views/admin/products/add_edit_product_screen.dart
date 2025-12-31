import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../utils/theme.dart';
import '../../../models/product.dart';
import '../../../models/store_settings.dart';
import '../../../providers/store_settings_provider.dart';
import '../../../../data/services/api_service.dart';
import '../../../constants/style_options.dart';

// Import StockType from product model

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

  String? _selectedCategoryId;  // Store category ID instead of name
  String? _selectedSubcategory;
  String _selectedMetalType = 'Gold';
  String _selectedStoneType = 'Diamond';
  List<String> _selectedGenders = [];
  List<String> _selectedStyles = [];  // Selected style tags
  List<String> _customTags = [];       // Non-style tags entered by user
  bool _isAvailable = true;
  bool _isFeatured = false;
  StockType _selectedStockType = StockType.stocked;  // Stock type selector
  List<String> _imageUrls = [];
  String? _videoUrl;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;

  // Dynamic categories from backend
  List<Map<String, dynamic>> _categories = [];
  List<String> _subcategories = [];
  bool _loadingCategories = true;

  // Store settings for customization options
  StoreSettings? _storeSettings;
  bool _loadingSettings = true;

  // Available gender options
  final List<String> _genderOptions = ['Men', 'Women', 'Children', 'Unisex'];

  // Predefined options for dropdowns
  final List<String> _materialOptions = [
    '18K Gold',
    '14K Gold',
    '22K Gold',
    '24K Gold',
    '925 Silver',
    '950 Platinum',
    'Rose Gold Plated',
    'White Gold Plated',
    'Rhodium Plated',
    'Custom',
  ];

  final List<String> _weightOptions = [
    '1g',
    '1.5g',
    '2g',
    '2.5g',
    '3g',
    '3.5g',
    '4g',
    '5g',
    '7.5g',
    '10g',
    '15g',
    '20g',
    '25g',
    '50g',
    'Custom',
  ];

  final List<String> _dimensionOptions = [
    '5mm',
    '8mm',
    '10mm',
    '12mm',
    '15mm',
    '18mm',
    '20mm',
    '25mm',
    '10mm x 8mm',
    '15mm x 10mm',
    '20mm x 15mm',
    '25mm x 20mm',
    'Custom',
  ];

  // Customization options
  List<String> _availableMetals = [];
  List<String> _availablePlatingColors = [];
  List<String> _availableSizes = [];
  List<StoneConfig> _stones = [];
  bool _engravingEnabled = false;
  int _maxEngravingChars = 15;
  double _engravingPrice = 500.0;
  Map<String, double> _metalPriceModifiers = {};
  Map<String, double> _platingPriceModifiers = {};

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
    _loadCategories();
    // Defer store settings loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoreSettings();
    });
  }

  Future<void> _loadStoreSettings() async {
    try {
      final provider = context.read<StoreSettingsProvider>();
      await provider.loadSettings();
      if (mounted) {
        setState(() {
          _storeSettings = provider.settings;
          _loadingSettings = false;
        });
      }
    } catch (e) {
      print('Error loading store settings: $e');
      if (mounted) {
        setState(() {
          _storeSettings = StoreSettings(); // Use defaults
          _loadingSettings = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      print('📂 Loading categories from backend...');
      final response = await ApiService.getAllCategories();
      print('📂 Categories response: $response');

      if (response['success'] != true || response['data'] == null) {
        throw Exception('Invalid response: ${response['message'] ?? 'No data'}');
      }

      final categoriesData = response['data'] as List;
      print('📂 Categories data: $categoriesData');

      if (categoriesData.isEmpty) {
        throw Exception('No categories found in backend');
      }

      setState(() {
        _categories = categoriesData.map((data) => {
          'id': data['id'] as String,  // Store category ID for unique identification
          'name': data['name'] as String,
          'subcategories': List<String>.from(data['subcategories'] ?? []),
        }).toList();
        print('📂 Loaded ${_categories.length} categories: $_categories');

        // Set default category if available
        if (_categories.isNotEmpty && _selectedCategoryId == null) {
          _selectedCategoryId = _categories.first['id'] as String;
          _updateSubcategories(_selectedCategoryId!);
        }

        _loadingCategories = false;

        // Now populate fields if editing
        if (widget.product != null) {
          _populateFields();
        }
      });
    } catch (e) {
      // Fallback to default categories if API fails
      print('📂 Error loading categories: $e');
      print('📂 Using fallback categories');
      setState(() {
        _categories = [
          {'id': 'fallback_rings', 'name': 'Rings', 'subcategories': ['Engagement Rings', 'Wedding Rings', 'Fashion Rings', 'Statement Rings']},
          {'id': 'fallback_necklaces', 'name': 'Necklaces', 'subcategories': ['Chain Necklaces', 'Pendant Necklaces', 'Chokers', 'Statement Necklaces']},
          {'id': 'fallback_earrings', 'name': 'Earrings', 'subcategories': ['Stud Earrings', 'Drop Earrings', 'Hoop Earrings', 'Chandelier Earrings']},
          {'id': 'fallback_bracelets', 'name': 'Bracelets', 'subcategories': ['Chain Bracelets', 'Bangle Bracelets', 'Charm Bracelets', 'Tennis Bracelets']},
          {'id': 'fallback_pendants', 'name': 'Pendants', 'subcategories': ['Diamond Pendants', 'Gold Pendants', 'Silver Pendants', 'Custom Pendants']},
        ];
        _selectedCategoryId = _categories.first['id'] as String;
        _updateSubcategories(_selectedCategoryId!);
        _loadingCategories = false;

        if (widget.product != null) {
          _populateFields();
        }
      });
    }
  }

  void _updateSubcategories(String categoryId) {
    Map<String, dynamic>? categoryData;
    for (final c in _categories) {
      if (c['id'] == categoryId) {
        categoryData = c;
        break;
      }
    }

    if (categoryData != null) {
      _subcategories = List<String>.from(categoryData['subcategories'] ?? []);
    } else {
      _subcategories = [];
    }

    if (_subcategories.isNotEmpty && (_selectedSubcategory == null || !_subcategories.contains(_selectedSubcategory))) {
      _selectedSubcategory = _subcategories.first;
    } else if (_subcategories.isEmpty) {
      _selectedSubcategory = null;
    }
  }

  void _populateFields() {
    final product = widget.product!;
    print('📝 Populating fields for product: ${product.name}');
    print('📝 Product category: ${product.category}');
    print('📝 Product gender: ${product.gender}');
    print('📝 Available categories: $_categories');

    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _originalPriceController.text = product.originalPrice?.toString() ?? '';
    _stockController.text = product.stockQuantity.toString();
    _materialController.text = product.metalType;
    _weightController.text = product.weight?.toString() ?? '';
    _dimensionsController.text = product.size ?? '';

    // Ensure dropdown values always match available items to avoid assertion errors
    // Category and Subcategory - use dynamic categories from backend
    // Find category by name and get its ID (take first match)
    String? matchingCategoryId;
    for (final c in _categories) {
      final categoryName = c['name'] as String;
      print('📝 Checking category: $categoryName against product.category: ${product.category}');
      if (categoryName.toLowerCase() == product.category.toLowerCase()) {
        matchingCategoryId = c['id'] as String;
        print('📝 Found matching category ID: $matchingCategoryId');
        break;
      }
    }
    if (matchingCategoryId != null) {
      _selectedCategoryId = matchingCategoryId;
    } else if (_categories.isNotEmpty) {
      print('📝 No matching category found, using first category');
      _selectedCategoryId = _categories.first['id'] as String;
    }
    if (_selectedCategoryId != null) {
      _updateSubcategories(_selectedCategoryId!);
      if (_subcategories.contains(product.subcategory)) {
        _selectedSubcategory = product.subcategory;
      } else if (product.subcategory != null && product.subcategory!.isNotEmpty) {
        // Try case-insensitive match for subcategory
        for (final sub in _subcategories) {
          if (sub.toLowerCase() == product.subcategory!.toLowerCase()) {
            _selectedSubcategory = sub;
            break;
          }
        }
      }
    }

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

    // Gender/Target Audience - ensure we have valid selections
    if (product.gender.isNotEmpty) {
      // Map product genders to valid options (case-insensitive matching)
      _selectedGenders = [];
      for (final productGender in product.gender) {
        for (final validGender in _genderOptions) {
          if (productGender.toLowerCase() == validGender.toLowerCase()) {
            _selectedGenders.add(validGender);
            break;
          }
        }
      }
      print('📝 Set selected genders: $_selectedGenders from product.gender: ${product.gender}');
    } else {
      _selectedGenders = [];
    }

    _selectedStockType = product.stockType;
    // Show ∞ for made-to-order products
    if (_selectedStockType == StockType.madeToOrder) {
      _stockController.text = '∞';
    }

    // Extract styles and custom tags from product tags
    if (product.tags.isNotEmpty) {
      _selectedStyles = ProductStyles.extractStyleTags(product.tags);
      _customTags = ProductStyles.extractNonStyleTags(product.tags);
      print('📝 Extracted styles: $_selectedStyles');
      print('📝 Extracted custom tags: $_customTags');
    }

    // Video URL
    if (product.videos.isNotEmpty) {
      _videoUrl = product.videos.first;
      _initializeVideoPlayer(_videoUrl!);
    }

    // Customization options
    _availableMetals = List.from(product.availableMetals);
    _availablePlatingColors = List.from(product.availablePlatingColors);
    _availableSizes = List.from(product.availableSizes);
    _stones = List.from(product.stones);
    _engravingEnabled = product.engravingEnabled;
    _maxEngravingChars = product.maxEngravingChars;
    _engravingPrice = product.engravingPrice;
    _metalPriceModifiers = Map.from(product.metalPriceModifiers);
    _platingPriceModifiers = Map.from(product.platingPriceModifiers);

    print('📝 Final selectedCategoryId: $_selectedCategoryId');
    print('📝 Final selectedSubcategory: $_selectedSubcategory');
    print('📝 Final selectedGenders: $_selectedGenders');
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
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer(String url) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
      }).catchError((error) {
        print('Video initialization error: $error');
        setState(() {
          _isVideoInitialized = false;
        });
      });
  }

  void _toggleVideoPlayback() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoController!.play();
        _isVideoPlaying = true;
      }
    });
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
                label: 'Description (min 10 characters)',
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Description is required';
                  if (value!.length < 10) return 'Description must be at least 10 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Section
              if (_loadingCategories)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: _inputDecoration('Category'),
                        isExpanded: true,
                        items: _categories
                            .map((category) => DropdownMenuItem(
                                  value: category['id'] as String,  // Use ID as value for uniqueness
                                  child: Text(category['name'] as String, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value!;
                            _updateSubcategories(value);
                          });
                        },
                        validator: (value) => value == null ? 'Please select a category' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubcategory,
                        decoration: _inputDecoration('Subcategory'),
                        isExpanded: true,
                        items: _subcategories.isEmpty
                            ? [const DropdownMenuItem(value: '', child: Text('No subcategories'))]
                            : _subcategories
                                .map((subcategory) => DropdownMenuItem(
                                      value: subcategory,
                                      child: Text(subcategory, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                        onChanged: _subcategories.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedSubcategory = value;
                                });
                              },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Target Audience Section
              _buildSectionHeader('Target Audience'),
              const SizedBox(height: 12),
              _buildGenderSelection(),
              const SizedBox(height: 24),

              // Style Section
              _buildSectionHeader('Product Styles'),
              const SizedBox(height: 12),
              _buildStyleSelection(),
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

              // Stock Type Selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedStockType == StockType.madeToOrder
                      ? AppTheme.primaryGold.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedStockType == StockType.madeToOrder
                        ? AppTheme.primaryGold
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stock Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStockTypeOption(
                            title: 'Stocked',
                            subtitle: 'Limited inventory',
                            icon: Icons.inventory_2_outlined,
                            isSelected: _selectedStockType == StockType.stocked,
                            onTap: () {
                              setState(() {
                                _selectedStockType = StockType.stocked;
                                if (_stockController.text == '∞') {
                                  _stockController.text = ''; // Clear infinite symbol
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStockTypeOption(
                            title: 'Made to Order',
                            subtitle: 'Always available',
                            icon: Icons.handyman_outlined,
                            isSelected: _selectedStockType == StockType.madeToOrder,
                            onTap: () {
                              setState(() {
                                _selectedStockType = StockType.madeToOrder;
                                _stockController.text = '∞'; // Show infinite for made-to-order
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_selectedStockType == StockType.madeToOrder)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppTheme.primaryGold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This product will always show as available regardless of stock quantity.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stock Quantity (only relevant for stocked products)
              AnimatedOpacity(
                opacity: _selectedStockType == StockType.stocked ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: _buildTextField(
                  controller: _stockController,
                  label: _selectedStockType == StockType.madeToOrder
                      ? 'Stock Quantity (optional for made-to-order)'
                      : 'Stock Quantity',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedStockType == StockType.stocked && (value?.isEmpty == true)) {
                      return 'Stock quantity is required for stocked products';
                    }
                    return null;
                  },
                ),
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
                  // Only show Stone Type dropdown when no Stone Configuration is set
                  // Otherwise, stoneType is auto-derived from Stone Configuration
                  Expanded(
                    child: _stones.isEmpty
                        ? DropdownButtonFormField<String>(
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
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade100,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Stone Type',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _stones.first.name,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                Tooltip(
                                  message: 'Auto-set from Stone Configuration',
                                  child: Icon(Icons.auto_awesome, size: 16, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdownWithCustomInput(
                controller: _materialController,
                label: 'Material Details',
                options: _materialOptions,
                hint: 'Select or enter material',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownWithCustomInput(
                      controller: _weightController,
                      label: 'Weight',
                      options: _weightOptions,
                      hint: 'Select or enter weight',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownWithCustomInput(
                      controller: _dimensionsController,
                      label: 'Dimensions',
                      options: _dimensionOptions,
                      hint: 'Select or enter dimensions',
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
              _buildVideoUploadSection(),
              const SizedBox(height: 24),

              // Customization Options Section
              _buildSectionHeader('Customization Options'),
              const SizedBox(height: 12),
              _buildCustomizationSection(),
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

  Widget _buildDropdownWithCustomInput({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    String? hint,
  }) {
    // Check if current value matches any option
    String? selectedValue;
    final currentText = controller.text.trim();
    if (currentText.isNotEmpty && options.contains(currentText)) {
      selectedValue = currentText;
    } else if (currentText.isNotEmpty) {
      selectedValue = 'Custom';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown for predefined options
        DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: _inputDecoration(label),
          isExpanded: true,
          hint: Text(hint ?? 'Select an option', style: TextStyle(color: Colors.grey.shade500)),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              if (value == 'Custom') {
                // Show dialog for custom input
                _showCustomInputDialog(controller, label);
              } else if (value != null) {
                controller.text = value;
              }
            });
          },
        ),
        // Show custom value if it doesn't match predefined options
        if (currentText.isNotEmpty && !options.contains(currentText) && currentText != 'Custom')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, size: 16, color: AppTheme.primaryGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Custom: $currentText',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCustomInputDialog(controller, label),
                    child: Icon(Icons.edit, size: 16, color: AppTheme.primaryGold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showCustomInputDialog(TextEditingController controller, String label) {
    final customController = TextEditingController(text: controller.text);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppTheme.primaryGold),
            const SizedBox(width: 8),
            Expanded(child: Text('Enter Custom $label')),
          ],
        ),
        content: TextField(
          controller: customController,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Enter custom value',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGold),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (customController.text.trim().isNotEmpty) {
                setState(() {
                  controller.text = customController.text.trim();
                });
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
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
        // Required indicator
        if (_imageUrls.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'At least one product image is required',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_imageUrls.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = _imageUrls[index];
                final isValidUrl = imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.hasAbsolutePath == true;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: isValidUrl
                            ? Image.network(
                                imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade200,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, color: Colors.grey.shade400),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Invalid',
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, color: Colors.grey),
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

  Widget _buildVideoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_videoUrl != null && _videoUrl!.isNotEmpty) ...[
          // Video Preview Card with actual video player
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Video Player Area
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.black,
                        child: _isVideoInitialized && _videoController != null
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryGold,
                                ),
                              ),
                      ),
                      // Play/Pause overlay button
                      if (_isVideoInitialized)
                        GestureDetector(
                          onTap: _toggleVideoPlayback,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // Remove button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            _videoController?.pause();
                            _videoController?.dispose();
                            setState(() {
                              _videoUrl = null;
                              _videoController = null;
                              _isVideoInitialized = false;
                              _isVideoPlaying = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      // MP4 badge
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.videocam, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'MP4',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Video Progress Bar
                if (_isVideoInitialized && _videoController != null)
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: AppTheme.primaryGold,
                      bufferedColor: AppTheme.primaryGold.withOpacity(0.3),
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                // Video URL Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Colors.grey.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _videoUrl!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Add Video Button
        OutlinedButton.icon(
          onPressed: _addVideoUrl,
          icon: const Icon(Icons.video_library),
          label: Text(_videoUrl != null && _videoUrl!.isNotEmpty ? 'Change Video' : 'Add Video URL'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryGold,
            side: const BorderSide(color: AppTheme.primaryGold),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Supported format: .mp4',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _addVideoUrl() {
    final controller = TextEditingController(text: _videoUrl ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.video_library, color: AppTheme.primaryGold),
            const SizedBox(width: 8),
            const Text('Add Video URL'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Video URL',
                hintText: 'https://example.com/video.mp4',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'URL must end with .mp4 extension',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                if (url.toLowerCase().endsWith('.mp4')) {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _videoUrl = url;
                    _isVideoInitialized = false;
                    _isVideoPlaying = false;
                  });
                  // Initialize video player
                  _initializeVideoPlayer(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid .mp4 video URL'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Video'),
          ),
        ],
      ),
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

  Widget _buildStockTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGold : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGold.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : AppTheme.primaryGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : AppTheme.primaryGold,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Checkmark indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: AppTheme.primaryGold,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select target audience (multiple allowed)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genderOptions.map((gender) {
              final isSelected = _selectedGenders.contains(gender);
              return FilterChip(
                label: Text(gender),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      // If Unisex is selected, clear others and just add Unisex
                      if (gender == 'Unisex') {
                        _selectedGenders.clear();
                        _selectedGenders.add('Unisex');
                      } else {
                        // If selecting a specific gender, remove Unisex if present
                        _selectedGenders.remove('Unisex');
                        _selectedGenders.add(gender);
                      }
                    } else {
                      _selectedGenders.remove(gender);
                    }
                  });
                },
                selectedColor: AppTheme.primaryGold.withValues(alpha: 0.3),
                checkmarkColor: AppTheme.primaryGold,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryGold : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          if (_selectedGenders.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Please select at least one target audience',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStyleSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select styles that describe this product (helps with filtering)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProductStyles.all.map((style) {
              final isSelected = _selectedStyles.contains(style.slug);
              return FilterChip(
                label: Text(style.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedStyles.add(style.slug);
                    } else {
                      _selectedStyles.remove(style.slug);
                    }
                  });
                },
                selectedColor: AppTheme.primaryGold.withValues(alpha: 0.3),
                checkmarkColor: AppTheme.primaryGold,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryGold : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                tooltip: style.description,
              );
            }).toList(),
          ),
          if (_selectedStyles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppTheme.primaryGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${_selectedStyles.map((s) => ProductStyles.getBySlug(s)?.name ?? s).join(", ")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Custom tags input
          Row(
            children: [
              const Text(
                'Custom Tags',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(for search & SEO)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryGold),
                onPressed: _showAddTagDialog,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_customTags.isEmpty)
            Text(
              'No custom tags added',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customTags.map((tag) {
                return InputChip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() {
                      _customTags.remove(tag);
                    });
                  },
                  backgroundColor: Colors.blue.shade50,
                  deleteIconColor: Colors.blue.shade700,
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Custom Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tag',
            hintText: 'e.g., wedding, gift, anniversary',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final tag = controller.text.trim().toLowerCase();
              if (tag.isNotEmpty && !_customTags.contains(tag)) {
                setState(() {
                  _customTags.add(tag);
                });
              }
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationSection() {
    if (_loadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }

    final settings = _storeSettings ?? StoreSettings();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available Metals - Dropdown from store settings
          _buildMetalSelectionFromSettings(settings),
          const Divider(height: 24),

          // Plating Colors - Dropdown from store settings
          _buildPlatingSelectionFromSettings(settings),
          const Divider(height: 24),

          // Available Sizes - Dropdown from store settings
          _buildSizeSelectionFromSettings(settings),
          const Divider(height: 24),

          // Stone Configuration - Dropdown from store settings
          _buildStoneSelectionFromSettings(settings),
          const Divider(height: 24),

          // Engraving Options
          _buildSwitchTile('Enable Engraving', _engravingEnabled, (value) {
            setState(() {
              _engravingEnabled = value;
            });
          }),
          if (_engravingEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _maxEngravingChars.toString(),
                    decoration: _inputDecoration('Max Characters'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        _maxEngravingChars = parsed;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _engravingPrice.toString(),
                    decoration: _inputDecoration('Engraving Price (₹)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) {
                        _engravingPrice = parsed;
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetalSelectionFromSettings(StoreSettings settings) {
    // Build flat list of metal options with subtypes
    final List<String> allMetalOptions = [];
    for (final metal in settings.metalOptions) {
      for (final subtype in metal.subtypes) {
        final optionName = '${metal.type} - ${subtype.name}';
        allMetalOptions.add(optionName);
      }
    }

    // Include custom metals that are not in store settings
    final customMetals = _availableMetals.where((m) => !allMetalOptions.contains(m)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Available Metals', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryGold, size: 20),
              tooltip: 'Add Custom Metal',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showAddCustomOptionDialog(
                title: 'Add Custom Metal',
                hint: 'e.g., Titanium - Grade 5',
                onAdd: (value) {
                  setState(() {
                    if (!_availableMetals.contains(value)) {
                      _availableMetals.add(value);
                      _metalPriceModifiers[value] = 0.0;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              icon: const Icon(Icons.select_all, size: 16),
              label: const Text('Select All', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() {
                  _availableMetals = List.from(allMetalOptions);
                  for (final metal in allMetalOptions) {
                    _metalPriceModifiers.putIfAbsent(metal, () => 0.0);
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...allMetalOptions.map((metal) {
              final isSelected = _availableMetals.contains(metal);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(metal),
                    if (isSelected && (_metalPriceModifiers[metal] ?? 0) > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+₹${_metalPriceModifiers[metal]!.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _availableMetals.add(metal);
                      _metalPriceModifiers[metal] = 0.0;
                    } else {
                      _availableMetals.remove(metal);
                      _metalPriceModifiers.remove(metal);
                    }
                  });
                },
                selectedColor: AppTheme.primaryGold.withOpacity(0.3),
                checkmarkColor: AppTheme.primaryGold,
              );
            }),
            // Custom metals (not from store settings)
            ...customMetals.map((metal) {
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(metal),
                    if ((_metalPriceModifiers[metal] ?? 0) > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+₹${_metalPriceModifiers[metal]!.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                      ),
                    ],
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _availableMetals.remove(metal);
                          _metalPriceModifiers.remove(metal);
                        });
                      },
                      child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                selected: true,
                onSelected: (_) {},
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
              );
            }),
          ],
        ),
        if (_availableMetals.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Tap selected metal to set price modifier:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableMetals.map((metal) {
              return ActionChip(
                avatar: const Icon(Icons.attach_money, size: 14),
                label: Text('${metal.split(' - ').last}: +₹${(_metalPriceModifiers[metal] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                onPressed: () => _showPriceModifierDialog(metal, _metalPriceModifiers[metal] ?? 0, (item, price) {
                  setState(() => _metalPriceModifiers[item] = price);
                }),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPlatingSelectionFromSettings(StoreSettings settings) {
    // Get store plating color names
    final storePlatingNames = settings.platingColors.map((c) => c.name).toList();
    // Include custom plating colors that are not in store settings
    final customPlatingColors = _availablePlatingColors.where((c) => !storePlatingNames.contains(c)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Plating Colors', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryGold, size: 20),
              tooltip: 'Add Custom Plating Color',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showAddCustomOptionDialog(
                title: 'Add Custom Plating Color',
                hint: 'e.g., Gunmetal, Two-Tone',
                onAdd: (value) {
                  setState(() {
                    if (!_availablePlatingColors.contains(value)) {
                      _availablePlatingColors.add(value);
                      _platingPriceModifiers[value] = 0.0;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              icon: const Icon(Icons.select_all, size: 16),
              label: const Text('Select All', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() {
                  _availablePlatingColors = settings.platingColors.map((c) => c.name).toList();
                  for (final color in _availablePlatingColors) {
                    _platingPriceModifiers.putIfAbsent(color, () => 0.0);
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...settings.platingColors.map((color) {
              final isSelected = _availablePlatingColors.contains(color.name);
              return FilterChip(
                avatar: color.hexColor != null
                    ? Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _hexToColor(color.hexColor!),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400, width: 0.5),
                        ),
                      )
                    : null,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(color.name),
                    if (isSelected && (_platingPriceModifiers[color.name] ?? 0) > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+₹${_platingPriceModifiers[color.name]!.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _availablePlatingColors.add(color.name);
                      _platingPriceModifiers[color.name] = 0.0;
                    } else {
                      _availablePlatingColors.remove(color.name);
                      _platingPriceModifiers.remove(color.name);
                    }
                  });
                },
                selectedColor: AppTheme.primaryGold.withOpacity(0.3),
                checkmarkColor: AppTheme.primaryGold,
              );
            }),
            // Custom plating colors (not from store settings)
            ...customPlatingColors.map((color) {
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(color),
                    if ((_platingPriceModifiers[color] ?? 0) > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+₹${_platingPriceModifiers[color]!.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                      ),
                    ],
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _availablePlatingColors.remove(color);
                          _platingPriceModifiers.remove(color);
                        });
                      },
                      child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                selected: true,
                onSelected: (_) {},
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
              );
            }),
          ],
        ),
        if (_availablePlatingColors.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Tap to set price modifier:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availablePlatingColors.map((color) {
              return ActionChip(
                avatar: const Icon(Icons.attach_money, size: 14),
                label: Text('$color: +₹${(_platingPriceModifiers[color] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                onPressed: () => _showPriceModifierDialog(color, _platingPriceModifiers[color] ?? 0, (item, price) {
                  setState(() => _platingPriceModifiers[item] = price);
                }),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Widget _buildSizeSelectionFromSettings(StoreSettings settings) {
    // Determine which size category to show based on selected category
    String sizeCategory = 'Ring'; // Default
    String categoryName = '';
    try {
      final category = _categories.firstWhere((c) => c['id'] == _selectedCategoryId);
      categoryName = category['name']?.toString().toLowerCase() ?? '';
    } catch (_) {
      // Category not found, use empty string
    }

    if (categoryName.contains('ring')) {
      sizeCategory = 'Ring';
    } else if (categoryName.contains('chain') || categoryName.contains('necklace') || categoryName.contains('pendant')) {
      sizeCategory = 'Chain';
    } else if (categoryName.contains('bracelet')) {
      sizeCategory = 'Bracelet';
    } else if (categoryName.contains('bangle')) {
      sizeCategory = 'Bangle';
    }

    final sizeOption = settings.sizeOptions.firstWhere(
      (s) => s.category == sizeCategory,
      orElse: () => settings.sizeOptions.isNotEmpty ? settings.sizeOptions.first : SizeOption(category: 'Ring', sizes: []),
    );

    // Get store size values for the current category
    final storeSizeValues = sizeOption.sizes.map((s) => s.value).toList();
    // Include custom sizes that are not in store settings
    final customSizes = _availableSizes.where((s) => !storeSizeValues.contains(s)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text('Available Sizes ($sizeCategory)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Size category selector
                DropdownButton<String>(
                  value: sizeCategory,
                  isDense: true,
                  underline: const SizedBox(),
                  items: settings.sizeOptions.map((opt) => DropdownMenuItem(
                    value: opt.category,
                    child: Text(opt.category, style: const TextStyle(fontSize: 12)),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _availableSizes.clear(); // Clear when changing category
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryGold, size: 20),
                  tooltip: 'Add Custom Size',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showAddCustomOptionDialog(
                    title: 'Add Custom Size',
                    hint: 'e.g., US 15, XXL, 24 inch',
                    onAdd: (value) {
                      setState(() {
                        if (!_availableSizes.contains(value)) {
                          _availableSizes.add(value);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(Icons.select_all, size: 16),
                  label: const Text('All', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      _availableSizes = sizeOption.sizes.map((s) => s.value).toList();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...sizeOption.sizes.map((size) {
              final isSelected = _availableSizes.contains(size.value);
              return FilterChip(
                label: Text(size.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _availableSizes.add(size.value);
                    } else {
                      _availableSizes.remove(size.value);
                    }
                  });
                },
                selectedColor: AppTheme.primaryGold.withOpacity(0.3),
                checkmarkColor: AppTheme.primaryGold,
              );
            }),
            // Custom sizes (not from store settings)
            ...customSizes.map((size) {
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(size),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _availableSizes.remove(size);
                        });
                      },
                      child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                selected: true,
                onSelected: (_) {},
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildStoneSelectionFromSettings(StoreSettings settings) {
    // Group stones by category
    final stonesByCategory = <String, List<StoneType>>{};
    for (final stone in settings.stoneTypes) {
      stonesByCategory.putIfAbsent(stone.category, () => []).add(stone);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Stone Configuration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryGold),
              onPressed: () => _showAddStoneFromSettingsDialog(settings),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_stones.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                Icon(Icons.diamond_outlined, color: Colors.grey.shade500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No stones configured. Tap + to add stone options.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ..._stones.map((stone) => _buildStoneCard(stone)),
      ],
    );
  }

  void _showAddStoneFromSettingsDialog(StoreSettings settings) {
    String? selectedStoneName;
    String? selectedCut;
    List<String> selectedColors = [];
    final countController = TextEditingController();

    // Get all stone names
    final stoneNames = settings.stoneTypes.map((s) => s.name).toList();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Find selected stone type
          final selectedStone = selectedStoneName != null
              ? settings.stoneTypes.firstWhere((s) => s.name == selectedStoneName, orElse: () => settings.stoneTypes.first)
              : null;

          return AlertDialog(
            title: const Text('Add Stone'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stone Name Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedStoneName,
                    decoration: const InputDecoration(
                      labelText: 'Stone Type',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: stoneNames.map((name) => DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStoneName = value;
                        selectedCut = null;
                        selectedColors.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Cut/Shape Dropdown
                  if (selectedStone != null) ...[
                    DropdownButtonFormField<String>(
                      value: selectedCut,
                      decoration: const InputDecoration(
                        labelText: 'Cut/Shape',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: selectedStone.availableCuts.map((cut) => DropdownMenuItem(
                        value: cut,
                        child: Text(cut),
                      )).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedCut = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Available Colors (multi-select)
                    const Text('Available Colors:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedStone.availableColors.map((color) {
                        final isSelected = selectedColors.contains(color);
                        return FilterChip(
                          label: Text(color, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedColors.add(color);
                              } else {
                                selectedColors.remove(color);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryGold.withOpacity(0.3),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Count
                  TextField(
                    controller: countController,
                    decoration: const InputDecoration(
                      labelText: 'Count (optional)',
                      hintText: 'e.g., 6',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedStoneName != null && selectedCut != null) {
                    final count = int.tryParse(countController.text);
                    setState(() {
                      _stones.add(StoneConfig(
                        name: selectedStoneName!,
                        shape: selectedCut!,
                        availableColors: selectedColors,
                        count: count,
                      ));
                    });
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChipInputSection({
    required String title,
    required String hint,
    required List<String> items,
    required Function(String) onAdd,
    required Function(String) onRemove,
    Map<String, double>? priceModifiers,
    Function(String, double)? onPriceChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryGold),
              onPressed: () => _showAddItemDialog(title, hint, onAdd),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text('No $title added', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return InputChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item),
                    if (priceModifiers != null && priceModifiers.containsKey(item)) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+₹${priceModifiers[item]!.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                      ),
                    ],
                  ],
                ),
                onDeleted: () => onRemove(item),
                onPressed: priceModifiers != null && onPriceChange != null
                    ? () => _showPriceModifierDialog(item, priceModifiers[item] ?? 0, onPriceChange)
                    : null,
                backgroundColor: AppTheme.primaryGold.withOpacity(0.1),
                deleteIconColor: AppTheme.errorRed,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildStoneConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Stone Configuration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryGold),
              onPressed: _showAddStoneDialog,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_stones.isEmpty)
          Text('No stones configured', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
        else
          ..._stones.map((stone) => _buildStoneCard(stone)),
      ],
    );
  }

  Widget _buildStoneCard(StoneConfig stone) {
    final index = _stones.indexOf(stone);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stone.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${stone.shape}${stone.count != null ? ' × ${stone.count}' : ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditStoneDialog(index, stone),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: AppTheme.errorRed),
                  onPressed: () {
                    setState(() {
                      _stones.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            if (stone.availableColors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: stone.availableColors.map((color) {
                  final modifier = stone.colorPriceModifiers?[color] ?? 0.0;
                  return Chip(
                    label: Text(
                      modifier > 0 ? '$color (+₹${modifier.toStringAsFixed(0)})' : color,
                      style: const TextStyle(fontSize: 11),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(String title, String hint, Function(String) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            hintText: hint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showPriceModifierDialog(String item, double currentPrice, Function(String, double) onPriceChange) {
    final controller = TextEditingController(text: currentPrice.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Price Modifier for $item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Price Modifier (₹)',
            hintText: 'Additional price for this option',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final price = double.tryParse(controller.text) ?? 0.0;
              onPriceChange(item, price);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomOptionDialog({
    required String title,
    required String hint,
    required Function(String) onAdd,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Custom Option',
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onAdd(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                onAdd(value);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddStoneDialog() {
    final nameController = TextEditingController();
    final shapeController = TextEditingController();
    final countController = TextEditingController();
    final colorsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Stone Name', hintText: 'e.g., Center Stone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shapeController,
                decoration: const InputDecoration(labelText: 'Shape', hintText: 'e.g., Round, Oval'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countController,
                decoration: const InputDecoration(labelText: 'Count (optional)', hintText: 'e.g., 6'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorsController,
                decoration: const InputDecoration(
                  labelText: 'Available Colors (comma separated)',
                  hintText: 'e.g., Clear, Red, Blue',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty && shapeController.text.trim().isNotEmpty) {
                final colors = colorsController.text
                    .split(',')
                    .map((c) => c.trim())
                    .where((c) => c.isNotEmpty)
                    .toList();
                final count = int.tryParse(countController.text);
                setState(() {
                  _stones.add(StoneConfig(
                    name: nameController.text.trim(),
                    shape: shapeController.text.trim(),
                    availableColors: colors,
                    count: count,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditStoneDialog(int index, StoneConfig stone) {
    final nameController = TextEditingController(text: stone.name);
    final shapeController = TextEditingController(text: stone.shape);
    final countController = TextEditingController(text: stone.count?.toString() ?? '');
    final colorsController = TextEditingController(text: stone.availableColors.join(', '));
    Map<String, double> colorModifiers = Map.from(stone.colorPriceModifiers ?? {});

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Stone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Stone Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shapeController,
                  decoration: const InputDecoration(labelText: 'Shape'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countController,
                  decoration: const InputDecoration(labelText: 'Count (optional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorsController,
                  decoration: const InputDecoration(
                    labelText: 'Available Colors (comma separated)',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),
                const Text('Color Price Modifiers:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...colorsController.text.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).map((color) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(color)),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '+₹',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: (colorModifiers[color] ?? 0).toString()),
                            onChanged: (value) {
                              colorModifiers[color] = double.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final colors = colorsController.text
                    .split(',')
                    .map((c) => c.trim())
                    .where((c) => c.isNotEmpty)
                    .toList();
                final count = int.tryParse(countController.text);
                // Clean up modifiers to only include colors that exist
                final cleanModifiers = <String, double>{};
                for (final color in colors) {
                  if (colorModifiers.containsKey(color) && colorModifiers[color]! > 0) {
                    cleanModifiers[color] = colorModifiers[color]!;
                  }
                }
                setState(() {
                  _stones[index] = StoneConfig(
                    name: nameController.text.trim(),
                    shape: shapeController.text.trim(),
                    availableColors: colors,
                    count: count,
                    colorPriceModifiers: cleanModifiers.isNotEmpty ? cleanModifiers : null,
                  );
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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
      // Validate images - at least one image is required
      if (_imageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one product image'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }

      // Validate gender selection
      if (_selectedGenders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one target audience'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }

      try {
        // Get category name from selected ID for backend
        String? categoryName;
        for (final c in _categories) {
          if (c['id'] == _selectedCategoryId) {
            categoryName = c['name'] as String;
            break;
          }
        }

        final productData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': _parseRequiredDouble(_priceController.text),
          'originalPrice': _originalPriceController.text.isNotEmpty
              ? _parseNullableDouble(_originalPriceController.text)
              : null,
          'stockType': _selectedStockType == StockType.madeToOrder ? 'made_to_order' : 'stocked',
          'stockQuantity': _selectedStockType == StockType.madeToOrder
              ? 999999  // Large number for made-to-order (always available)
              : (_stockController.text.isNotEmpty && _stockController.text != '∞'
                  ? _parseRequiredInt(_stockController.text)
                  : 0),
          'category': categoryName,
          'subcategory': _selectedSubcategory,
          'metalType': _selectedMetalType,
          // Auto-derive stoneType from Stone Configuration if available
          'stoneType': _stones.isNotEmpty ? _stones.first.name : _selectedStoneType,
          'material': _materialController.text,
          'weight': _weightController.text.isNotEmpty ? _parseNullableDouble(_weightController.text) : null,
          'size': _dimensionsController.text,
          'images': _imageUrls,
          'videoUrl': _videoUrl,
          'isAvailable': _isAvailable,
          'isFeatured': _isFeatured,
          'tags': [..._selectedStyles, ..._customTags], // Combine styles and custom tags
          'gender': _selectedGenders,
          // Customization options
          'availableMetals': _availableMetals,
          'availablePlatingColors': _availablePlatingColors,
          'availableSizes': _availableSizes,
          'stones': _stones.map((s) => s.toJson()).toList(),
          'engravingEnabled': _engravingEnabled,
          'maxEngravingChars': _maxEngravingChars,
          'engravingPrice': _engravingPrice,
          'metalPriceModifiers': _metalPriceModifiers,
          'platingPriceModifiers': _platingPriceModifiers,
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