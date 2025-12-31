import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../viewmodels/community_provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../../data/models/community.dart';
import '../../../data/models/order.dart';
import '../../../data/models/product.dart';
import '../../../data/services/api_service.dart';
import '../../../utils/theme.dart';
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

  // Product/Order tagging
  PostTagSource _tagSource = PostTagSource.product;
  List<ProductTag> _selectedProducts = [];
  OrderTag? _selectedOrder;
  bool _isLoadingOrders = false;
  bool _isLoadingProducts = false;
  List<Order> _userOrders = [];
  List<Product> _catalogProducts = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Load user's orders for tagging
    await _loadUserOrders();
    // Load catalog products for direct tagging
    await _loadCatalogProducts();
  }

  Future<void> _loadUserOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final response = await ApiService.getOrders();
      if (response['success'] == true && response['data'] != null) {
        final ordersData = response['data']['orders'] as List<dynamic>? ?? [];
        _userOrders = ordersData
            .map((o) => Order.fromJson(o as Map<String, dynamic>))
            .where((o) => o.status == OrderStatus.delivered) // Only delivered orders
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _loadCatalogProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final response = await ApiService.getProducts(limit: 50);
      if (response['success'] == true && response['data'] != null) {
        final productsData = response['data']['products'] as List<dynamic>? ?? [];
        _catalogProducts = productsData
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  void _selectProductFromCatalog(Product product) {
    final productTag = ProductTag(
      id: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.images.isNotEmpty ? product.images.first : '',
    );

    setState(() {
      _selectedProducts = [productTag];
      _selectedOrder = null;
      _tagSource = PostTagSource.product;
    });
  }

  void _selectProductFromOrder(Order order, int itemIndex) {
    final item = order.items[itemIndex];
    // Note: In the future, customization data will be extracted from the order item
    // once the cart/order system supports storing customization selections

    final productTag = ProductTag(
      id: item.product.id,
      name: item.product.name,
      price: item.effectivePrice,
      imageUrl: item.product.images.isNotEmpty ? item.product.images.first : '',
      customization: null, // Customization data to be added when orders support it
      orderId: order.id,
      orderNumber: order.orderNumber,
    );

    setState(() {
      _selectedProducts = [productTag];
      _selectedOrder = null;
      _tagSource = PostTagSource.order;
    });
  }

  void _selectEntireOrder(Order order) {
    // Note: In the future, customization data will be extracted from the order items
    // once the cart/order system supports storing customization selections
    final products = order.items.map((item) {
      return ProductTag(
        id: item.product.id,
        name: item.product.name,
        price: item.effectivePrice,
        imageUrl: item.product.images.isNotEmpty ? item.product.images.first : '',
        customization: null, // Customization data to be added when orders support it
        orderId: order.id,
        orderNumber: order.orderNumber,
      );
    }).toList();

    final orderTag = OrderTag(
      orderId: order.id,
      orderNumber: order.orderNumber ?? 'N/A',
      orderDate: order.createdAt,
      orderTotal: order.total,
      products: products,
    );

    setState(() {
      _selectedOrder = orderTag;
      _selectedProducts = [];
      _tagSource = PostTagSource.order;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProducts = [];
      _selectedOrder = null;
    });
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

    // Check if product or order is selected (required)
    if (_selectedProducts.isEmpty && _selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product or order to tag'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
        products: _selectedProducts.isNotEmpty ? _selectedProducts : null,
        order: _selectedOrder,
        tagSource: _tagSource,
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
            // Product/Order Selection Section (Required)
            _buildProductOrderSection(),
            const SizedBox(height: 24),

            // Content input
            TextFormField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Share your experience with this product...',
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

  // Product/Order Selection Section
  Widget _buildProductOrderSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tag a Product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select a product from our catalog or from your orders',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Source selector tabs
          Row(
            children: [
              Expanded(
                child: _buildSourceTab(
                  'From Catalog',
                  PostTagSource.product,
                  Icons.store_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSourceTab(
                  'From My Orders',
                  PostTagSource.order,
                  Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selected product display
          if (_selectedProducts.isNotEmpty || _selectedOrder != null) ...[
            _buildSelectedItemDisplay(),
            const SizedBox(height: 12),
          ],

          // Product/Order selection button
          GlassButton(
            text: _selectedProducts.isEmpty && _selectedOrder == null
                ? 'Select ${_tagSource == PostTagSource.product ? 'Product' : 'Order'}'
                : 'Change Selection',
            onPressed: _showSelectionSheet,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedProducts.isEmpty && _selectedOrder == null
                      ? Icons.add
                      : Icons.swap_horiz,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedProducts.isEmpty && _selectedOrder == null
                      ? 'Select ${_tagSource == PostTagSource.product ? 'Product' : 'Order'}'
                      : 'Change Selection',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTab(String label, PostTagSource source, IconData icon) {
    final isSelected = _tagSource == source;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tagSource = source;
          // Clear selection when switching tabs
          _selectedProducts = [];
          _selectedOrder = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primaryGold : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryGold : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedItemDisplay() {
    if (_selectedOrder != null) {
      // Display selected order
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order #${_selectedOrder!.orderNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clearSelection,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedOrder!.products.length} product(s) • ₹${_selectedOrder!.orderTotal.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 8),
            // Show product thumbnails
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedOrder!.products.length,
                itemBuilder: (context, index) {
                  final product = _selectedOrder!.products[index];
                  return Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(product.imageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedProducts.isNotEmpty) {
      final product = _selectedProducts.first;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Product image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(product.imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Show customization if available
                  if (product.customization != null &&
                      product.customization!.hasCustomizations) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.customization!.summary,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Show order badge if from order
                  if (product.isFromOrder) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'From Order #${product.orderNumber}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: _clearSelection,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _tagSource == PostTagSource.product
                      ? 'Select a Product'
                      : 'Select from Your Orders',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: _tagSource == PostTagSource.product
                    ? _buildProductList(scrollController)
                    : _buildOrderList(scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(ScrollController scrollController) {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_catalogProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _catalogProducts.length,
      itemBuilder: (context, index) {
        final product = _catalogProducts[index];
        return _buildProductTile(product);
      },
    );
  }

  Widget _buildProductTile(Product product) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.images.isNotEmpty
              ? Image.network(product.images.first, fit: BoxFit.cover)
              : const Icon(Icons.image, color: Colors.grey),
        ),
      ),
      title: Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '₹${product.price.toStringAsFixed(0)}',
        style: TextStyle(
          color: AppTheme.primaryGold,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _selectProductFromCatalog(product);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildOrderList(ScrollController scrollController) {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No delivered orders yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete an order to tag products from it',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _userOrders.length,
      itemBuilder: (context, index) {
        final order = _userOrders[index];
        return _buildOrderTile(order);
      },
    );
  }

  Widget _buildOrderTile(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          'Order #${order.orderNumber ?? order.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${order.items.length} item(s) • ₹${order.total.toStringAsFixed(0)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt_outlined,
            color: AppTheme.primaryGold,
          ),
        ),
        children: [
          // Option to select entire order
          ListTile(
            leading: const Icon(Icons.select_all, size: 20),
            title: const Text('Tag entire order'),
            subtitle: const Text('All products will be tagged'),
            dense: true,
            onTap: () {
              _selectEntireOrder(order);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          // Individual products from the order
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: item.product.images.isNotEmpty
                      ? Image.network(item.product.images.first, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              title: Text(
                item.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${item.effectivePrice.toStringAsFixed(0)} × ${item.quantity}',
                    style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontSize: 12,
                    ),
                  ),
                  // Note: Customization display will be added when orders support storing customizations
                ],
              ),
              trailing: TextButton(
                onPressed: () {
                  _selectProductFromOrder(order, index);
                  Navigator.pop(context);
                },
                child: const Text('Select'),
              ),
            );
          }),
        ],
      ),
    );
  }
}
