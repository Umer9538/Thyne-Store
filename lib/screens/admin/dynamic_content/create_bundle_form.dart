import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thyne_jewls/utils/theme.dart';
import 'package:thyne_jewls/services/api_service.dart';
import 'package:thyne_jewls/models/product.dart';

class BundleItemData {
  final Product product;
  int quantity;

  BundleItemData({required this.product, this.quantity = 1});
}

class CreateBundleForm extends StatefulWidget {
  const CreateBundleForm({super.key});

  @override
  State<CreateBundleForm> createState() => _CreateBundleFormState();
}

class _CreateBundleFormState extends State<CreateBundleForm> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _loadingProducts = false;

  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Bridal Set';
  int _discountPercent = 15;
  int _stock = 20;

  final List<String> _categories = [
    'Bridal Set',
    'Gift Set',
    'Office Look',
    'Party Wear',
    'Casual Collection',
    'Luxury Package',
  ];

  // Product bundle
  List<Product> _availableProducts = [];
  List<BundleItemData> _bundleItems = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

        final productList = productsList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          _availableProducts = productList;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _loadingProducts = false);
  }

  double get _originalPrice {
    return _bundleItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  double get _bundlePrice {
    return _originalPrice * (1 - _discountPercent / 100);
  }

  double get _savings {
    return _originalPrice - _bundlePrice;
  }

  Future<void> _saveBundle() async {
    if (!_formKey.currentState!.validate()) return;

    if (_bundleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product to the bundle')),
      );
      return;
    }

    if (_bundleItems.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bundle must contain at least 2 products')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Prepare items for API
      final items = _bundleItems.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
      }).toList();

      // Call the API to create bundle deal
      final response = await ApiService.createBundleDeal(
        title: _titleController.text,
        description: _descriptionController.text,
        items: items,
        bundlePrice: _bundlePrice,
        stock: _stock,
        priority: 0,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bundle Deal created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to create bundle deal');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating bundle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  void _showProductSelector() {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filter products based on search query
          final filteredProducts = searchQuery.isEmpty
              ? _availableProducts
              : _availableProducts.where((product) {
                  final query = searchQuery.toLowerCase();
                  return product.name.toLowerCase().contains(query) ||
                      product.category.toLowerCase().contains(query) ||
                      product.description.toLowerCase().contains(query);
                }).toList();

          return Dialog(
            child: Container(
              width: 600,
              height: 700,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Add Product to Bundle',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setDialogState(() => searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setDialogState(() => searchQuery = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Content
                  Expanded(
                    child: _loadingProducts
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading products...'),
                              ],
                            ),
                          )
                        : filteredProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      searchQuery.isNotEmpty ? 'No products found' : 'No Products Available',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      searchQuery.isNotEmpty
                                          ? 'Try a different search term'
                                          : 'Please add products to your store first',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (searchQuery.isEmpty) ...[
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _loadProducts();
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryGold,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  final isAlreadyAdded = _bundleItems.any((item) => item.product.id == product.id);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      leading: product.images.isNotEmpty
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
                                          : Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.inventory_2),
                                            ),
                                      title: Text(
                                        product.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '₹${product.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: AppTheme.primaryGold,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Stock: ${product.stock}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: isAlreadyAdded
                                          ? Icon(Icons.check_circle, color: AppTheme.primaryGold, size: 32)
                                          : Container(
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryGold,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const IconButton(
                                                icon: Icon(Icons.add, color: Colors.white),
                                                onPressed: null,
                                              ),
                                            ),
                                      enabled: !isAlreadyAdded,
                                      onTap: isAlreadyAdded ? null : () {
                                        setState(() {
                                          _bundleItems.add(BundleItemData(product: product));
                                        });
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${product.name} added to bundle'),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _editQuantity(int index) {
    final item = _bundleItems[index];
    final controller = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Quantity: ${item.product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(controller.text);
              if (newQuantity != null && newQuantity > 0) {
                setState(() {
                  item.quantity = newQuantity;
                });
                Navigator.pop(context);
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

  void _removeItem(int index) {
    setState(() {
      _bundleItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bundle Deal'),
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
              onPressed: _saveBundle,
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
              // Basic Info
              Text(
                'Bundle Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Bundle Title',
                  hintText: 'e.g., Complete Bridal Set',
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
                  hintText: 'Describe the bundle',
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
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Bundle Items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bundle Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showProductSelector,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_bundleItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'No products added',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Add Product" to start building your bundle',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: List.generate(_bundleItems.length, (index) {
                    final item = _bundleItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (item.product.images.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.product.images.first,
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
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
                                    style: TextStyle(
                                      color: AppTheme.primaryGold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Subtotal: \$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _editQuantity(index),
                                  tooltip: 'Edit Quantity',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _removeItem(index),
                                  tooltip: 'Remove',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 32),

              // Discount
              Text(
                'Bundle Discount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _discountPercent.toDouble(),
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: '$_discountPercent%',
                      activeColor: AppTheme.primaryGold,
                      onChanged: (value) {
                        setState(() => _discountPercent = value.toInt());
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
                      '$_discountPercent%',
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

              // Stock
              Text(
                'Stock',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _stock.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Available Stock',
                  hintText: 'Number of bundles available',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  final stock = int.tryParse(value);
                  if (stock == null || stock < 1) {
                    return 'Stock must be at least 1';
                  }
                  return null;
                },
                onChanged: (value) {
                  final stock = int.tryParse(value);
                  if (stock != null) {
                    setState(() => _stock = stock);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Pricing Preview
              Text(
                'Pricing Preview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Original Price:'),
                        Text(
                          '\$${_originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bundle Price:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${_bundlePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.savings, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'You Save:',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${_savings.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bundle Preview
              if (_bundleItems.isNotEmpty) ...[
                Text(
                  'Bundle Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.card_giftcard, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'BUNDLE DEAL',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _titleController.text.isEmpty
                            ? 'Bundle Title'
                            : _titleController.text,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SAVE $_discountPercent%',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedCategory,
                              style: TextStyle(
                                color: Colors.purple.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
