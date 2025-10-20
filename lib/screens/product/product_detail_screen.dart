import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/video_player_widget.dart';
import 'review_submission_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isDescriptionExpanded = false;
  bool _isSpecificationsExpanded = true;

  // Selected customization options
  String? _selectedColor;
  String? _selectedPolish;
  String? _selectedStoneColor;
  String? _selectedGemstone;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading product details...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Simulate data loading (in real app, this would fetch from API)
    await Future.delayed(const Duration(milliseconds: 800));

    // Initialize default selections
    if (widget.product.availableColors.isNotEmpty) {
      _selectedColor = widget.product.availableColors.first;
    }
    if (widget.product.availablePolishTypes.isNotEmpty) {
      _selectedPolish = widget.product.availablePolishTypes.first;
    }
    if (widget.product.availableStoneColors.isNotEmpty) {
      _selectedStoneColor = widget.product.availableStoneColors.first;
    }
    if (widget.product.availableGemstones.isNotEmpty) {
      _selectedGemstone = widget.product.availableGemstones.first;
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      setState(() {
        // Refresh UI with initialized data
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getMediaCount() {
    return widget.product.images.length + widget.product.videos.length;
  }

  bool _isVideo(int index) {
    return index < widget.product.videos.length;
  }

  Widget _buildMediaItem(int index) {
    // Videos come first, then images
    if (_isVideo(index)) {
      return Stack(
        children: [
          VideoPlayerWidget(videoUrl: widget.product.videos[index]),
          const Positioned(
            top: 16,
            right: 16,
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      );
    }

    // Show image with optimized loading
    int imageIndex = index - widget.product.videos.length;
    return CachedNetworkImage(
      imageUrl: widget.product.images[imageIndex],
      fit: BoxFit.cover,
      width: double.infinity,
      memCacheWidth: 1080, // Limit memory cache size
      maxWidthDiskCache: 1080, // Limit disk cache size
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Failed to load image',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(int index) {
    final isSelected = _currentImageIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _isVideo(index)
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.black87,
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                )
              : CachedNetworkImage(
                  imageUrl: widget.product.images[index - widget.product.videos.length],
                  fit: BoxFit.cover,
                  memCacheWidth: 120, // Small thumbnail cache
                  maxWidthDiskCache: 120,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 16, color: Colors.grey),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isInWishlist = wishlistProvider.isInWishlist(widget.product.id);
    final relatedProducts = productProvider.getRelatedProducts(widget.product);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Image
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: _getMediaCount(),
                    itemBuilder: (context, index) {
                      return _buildMediaItem(index);
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_getMediaCount(), (index) => index).asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_outline,
                    color: isInWishlist ? AppTheme.errorRed : AppTheme.textPrimary,
                  ),
                  onPressed: () {
                    wishlistProvider.toggleWishlist(widget.product.id);
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: AppTheme.textPrimary),
                  onPressed: () {
                    // Share functionality
                  },
                ),
              ),
            ],
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU: ${widget.product.id}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${widget.product.price.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.primaryGold,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (widget.product.originalPrice != null)
                            Text(
                              '₹${widget.product.originalPrice!.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          if (widget.product.discount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${widget.product.discount.toStringAsFixed(0)}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Media Thumbnails Gallery
                  if (_getMediaCount() > 1) ...[
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _getMediaCount(),
                        itemBuilder: (context, index) => _buildThumbnail(index),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Rating and Reviews
                  if (widget.product.rating > 0)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewSubmissionScreen(
                              product: widget.product,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          RatingBarIndicator(
                            rating: widget.product.rating,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: AppTheme.warningAmber,
                            ),
                            itemCount: 5,
                            itemSize: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.product.rating.toString(),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${widget.product.reviewCount} reviews)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Color Selector
                  if (widget.product.availableColors.isNotEmpty) ...[
                    Text(
                      'Select Color',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.product.availableColors.map((color) {
                        final isSelected = color == _selectedColor;
                        return ChoiceChip(
                          label: Text(color),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          selectedColor: AppTheme.primaryGold,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Polish/Finish Selector
                  if (widget.product.availablePolishTypes.isNotEmpty) ...[
                    Text(
                      'Polish Finish',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.product.availablePolishTypes.map((polish) {
                        final isSelected = polish == _selectedPolish;
                        return ChoiceChip(
                          label: Text(polish),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPolish = polish;
                            });
                          },
                          selectedColor: AppTheme.primaryGold,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stone Color Selector
                  if (widget.product.availableStoneColors.isNotEmpty) ...[
                    Text(
                      'Stone Color',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.product.availableStoneColors.map((stoneColor) {
                        final isSelected = stoneColor == _selectedStoneColor;
                        return ChoiceChip(
                          label: Text(stoneColor),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStoneColor = stoneColor;
                            });
                          },
                          selectedColor: AppTheme.primaryGold,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Gemstone Selector
                  if (widget.product.availableGemstones.isNotEmpty) ...[
                    Text(
                      'Select Gemstone',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.product.availableGemstones.map((gemstone) {
                        final isSelected = gemstone == _selectedGemstone;
                        return ChoiceChip(
                          label: Text(gemstone),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedGemstone = gemstone;
                            });
                          },
                          selectedColor: AppTheme.primaryGold,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Size/Variation Selector (if applicable)
                  if (widget.product.size != null) ...[
                    Text(
                      'Size',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['5', '6', '7', '8', '9'].map((size) {
                        final isSelected = size == widget.product.size;
                        return ChoiceChip(
                          label: Text(size),
                          selected: isSelected,
                          onSelected: (selected) {
                            // Handle size selection
                          },
                          selectedColor: AppTheme.primaryGold,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quantity Selector
                  Row(
                    children: [
                      Text(
                        'Quantity',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _quantity > 1
                                  ? () {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  : null,
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 40),
                              child: Text(
                                _quantity.toString(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _quantity < widget.product.stockQuantity
                                  ? () {
                                      setState(() {
                                        _quantity++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.product.stockQuantity < 10)
                    Text(
                      'Only ${widget.product.stockQuantity} left in stock',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningAmber,
                          ),
                    ),
                  const SizedBox(height: 24),

                  // Description
                  _buildExpandableSection(
                    title: 'Description',
                    isExpanded: _isDescriptionExpanded,
                    onToggle: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    content: Text(
                      widget.product.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Specifications
                  _buildExpandableSection(
                    title: 'Specifications',
                    isExpanded: _isSpecificationsExpanded,
                    onToggle: () {
                      setState(() {
                        _isSpecificationsExpanded = !_isSpecificationsExpanded;
                      });
                    },
                    content: Column(
                      children: [
                        _buildSpecificationRow('Metal Type', widget.product.metalType),
                        if (widget.product.stoneType != null)
                          _buildSpecificationRow('Stone Type', widget.product.stoneType!),
                        if (widget.product.weight != null)
                          _buildSpecificationRow(
                              'Weight', '${widget.product.weight} grams'),
                        // Selected customizations
                        if (_selectedColor != null)
                          _buildSpecificationRow('Selected Color', _selectedColor!),
                        if (_selectedPolish != null)
                          _buildSpecificationRow('Polish Finish', _selectedPolish!),
                        if (_selectedStoneColor != null)
                          _buildSpecificationRow('Stone Color', _selectedStoneColor!),
                        if (_selectedGemstone != null)
                          _buildSpecificationRow('Gemstone', _selectedGemstone!),
                        _buildSpecificationRow('Category', widget.product.category),
                        _buildSpecificationRow('Subcategory', widget.product.subcategory),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Related Products
                  if (relatedProducts.isNotEmpty) ...[
                    Text(
                      'You May Also Like',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedProducts.length,
                        itemBuilder: (context, index) {
                          final product = relatedProducts[index];
                          return Container(
                            width: 180,
                            margin: const EdgeInsets.only(right: 12),
                            child: ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      product: product,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.product.isAvailable
                    ? () {
                        cartProvider.addToCart(widget.product, quantity: _quantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added $_quantity items to cart'),
                            action: SnackBarAction(
                              label: 'View Cart',
                              onPressed: () {
                                Navigator.pushNamed(context, '/cart');
                              },
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('Add to Cart'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.product.isAvailable
                    ? () {
                        cartProvider.addToCart(widget.product, quantity: _quantity);
                        Navigator.pushNamed(context, '/checkout');
                      }
                    : null,
                child: const Text('Buy Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}