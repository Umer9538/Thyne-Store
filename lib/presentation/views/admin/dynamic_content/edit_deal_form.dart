import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:thyne_jewls/utils/theme.dart';
import 'package:thyne_jewls/data/services/api_service.dart';
import 'package:thyne_jewls/data/models/product.dart';
import 'package:thyne_jewls/data/models/homepage.dart';

class EditDealForm extends StatefulWidget {
  final DealOfDay deal;

  const EditDealForm({super.key, required this.deal});

  @override
  State<EditDealForm> createState() => _EditDealFormState();
}

class _EditDealFormState extends State<EditDealForm> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _loadingProducts = true;

  List<Product> _products = [];
  Product? _selectedProduct;

  late int _discountPercent;
  late int _stock;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    // Initialize with current deal values
    _discountPercent = widget.deal.discountPercent;
    _stock = widget.deal.stock;
    _startTime = widget.deal.startTime;
    _endTime = widget.deal.endTime;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
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
          _products = productsList
              .map((p) => Product.fromJson(p as Map<String, dynamic>))
              .toList();
          
          // Find and set the currently selected product
          _selectedProduct = _products.firstWhere(
            (p) => p.id == widget.deal.productId,
            orElse: () => _products.isNotEmpty ? _products.first : Product(
              id: widget.deal.productId,
              name: 'Unknown Product',
              description: '',
              price: widget.deal.originalPrice,
              stockQuantity: 0,
              category: '',
              subcategory: '',
              metalType: '',
              images: [],
              isAvailable: true,
              isFeatured: false,
            ),
          );
          _loadingProducts = false;
        });
      } else {
        setState(() => _loadingProducts = false);
      }
    } catch (e) {
      setState(() => _loadingProducts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime),
      );
      if (time != null) {
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: _startTime,
      lastDate: _startTime.add(const Duration(days: 30)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime),
      );
      if (time != null) {
        setState(() {
          _endTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _updateDeal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await ApiService.updateDealOfDay(
        id: widget.deal.id,
        productId: _selectedProduct!.id,
        discountPercent: _discountPercent,
        stock: _stock,
        startTime: _startTime,
        endTime: _endTime,
      );

      if (mounted) {
        if (response['success'] == true) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deal of Day updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response['error'] ?? 'Unknown error'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating deal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Deal of Day'),
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
              onPressed: _updateDeal,
              tooltip: 'Save',
            ),
        ],
      ),
      body: _loadingProducts
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Product Selection
                  Text(
                    'Product',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildProductSelector(),

                  const SizedBox(height: 24),

                  // Discount Percentage
                  Text(
                    'Discount Percentage',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildDiscountSlider(),

                  const SizedBox(height: 24),

                  // Stock
                  Text(
                    'Stock Quantity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _stock.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter stock quantity',
                      suffixIcon: Icon(Icons.inventory_2),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      final stock = int.tryParse(value);
                      if (stock == null || stock <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final stock = int.tryParse(value);
                      if (stock != null) _stock = stock;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Date & Time Selection
                  Text(
                    'Schedule',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildDateTimeCard(
                    'Start Time',
                    _startTime,
                    Icons.play_arrow,
                    Colors.green,
                    _selectStartDate,
                  ),
                  const SizedBox(height: 12),
                  _buildDateTimeCard(
                    'End Time',
                    _endTime,
                    Icons.stop,
                    Colors.red,
                    _selectEndDate,
                  ),

                  const SizedBox(height: 24),

                  // Preview
                  if (_selectedProduct != null) _buildPreview(),

                  const SizedBox(height: 24),

                  // Update Button
                  ElevatedButton(
                    onPressed: _loading ? null : _updateDeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Update Deal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductSelector() {
    return InkWell(
      onTap: () => _showProductPicker(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _selectedProduct == null
            ? Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Text(
                    'Tap to select product',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              )
            : Row(
                children: [
                  if (_selectedProduct!.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _selectedProduct!.images.first,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
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
                          _selectedProduct!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_selectedProduct!.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
      ),
    );
  }

  Widget _buildDiscountSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount:'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_discountPercent%',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: _discountPercent.toDouble(),
              min: 10,
              max: 80,
              divisions: 14,
              label: '$_discountPercent%',
              activeColor: AppTheme.primaryGold,
              onChanged: (value) {
                setState(() => _discountPercent = value.toInt());
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('10%', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text('80%', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(
    String label,
    DateTime dateTime,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • HH:mm').format(dateTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final originalPrice = _selectedProduct!.price;
    final dealPrice = originalPrice * (1 - _discountPercent / 100);
    final savings = originalPrice - dealPrice;

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Original Price:'),
                Text(
                  '₹${originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Deal Price:'),
                Text(
                  '₹${dealPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('You Save:'),
                Text(
                  '₹${savings.toStringAsFixed(2)} ($_discountPercent%)',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Duration:'),
                Text(
                  '${_endTime.difference(_startTime).inHours} hours',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductPicker() {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Filter products based on search query
          final filteredProducts = searchQuery.isEmpty
              ? _products
              : _products.where((product) {
                  final query = searchQuery.toLowerCase();
                  return product.name.toLowerCase().contains(query) ||
                      product.category.toLowerCase().contains(query) ||
                      product.description.toLowerCase().contains(query);
                }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Select Product',
                          style: TextStyle(
                            fontSize: 18,
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
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setModalState(() => searchQuery = '');
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
                        setModalState(() => searchQuery = value);
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredProducts.isEmpty
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
                                  searchQuery.isNotEmpty ? 'No products found' : 'No products available',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                if (searchQuery.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Try a different search term',
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: product.images.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            product.images.first,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 50,
                                                height: 50,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image_not_supported),
                                              );
                                            },
                                          ),
                                        )
                                      : null,
                                  title: Text(product.name),
                                  subtitle: Column(
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
                                  trailing: Radio<String>(
                                    value: product.id,
                                    groupValue: _selectedProduct?.id,
                                    activeColor: AppTheme.primaryGold,
                                    onChanged: (value) {
                                      setState(() => _selectedProduct = product);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  onTap: () {
                                    setState(() => _selectedProduct = product);
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
