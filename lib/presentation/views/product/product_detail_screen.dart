import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../data/models/product.dart';
import '../../data/models/store_settings.dart';
import '../viewmodels/product_provider.dart';
import '../viewmodels/cart_provider.dart';
import '../viewmodels/wishlist_provider.dart';
import '../viewmodels/recently_viewed_provider.dart';
import '../../data/services/api_service.dart';
import '../../../utils/theme.dart';
import '../widgets/product_card.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/stone_shape_selector.dart';
import '../widgets/diamond_4cs_selector.dart';
import '../widgets/carat_weight_selector.dart';
import 'review_submission_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final double? salePrice; // Optional sale price for deals/flash sales
  final double? originalPrice; // Optional original price override
  final int? discountPercent; // Optional discount percentage
  // Customization intent from community posts (pre-selected customizations)
  final Map<String, dynamic>? customizationIntent;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.salePrice,
    this.originalPrice,
    this.discountPercent,
    this.customizationIntent,
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

  // Selected customization options (legacy)
  String? _selectedColor;
  String? _selectedPolish;
  String? _selectedStoneColor;
  String? _selectedGemstone;
  String? _selectedSize;

  // Enhanced customization options (Diamondere style)
  String? _selectedMetal;
  String? _selectedPlatingColor;
  Map<String, String> _selectedStoneColors = {}; // stone name -> selected color
  Map<String, String> _selectedStoneQualities = {}; // stone name -> selected quality
  Map<String, String> _selectedStoneShapes = {}; // stone name -> selected shape
  Map<String, DiamondGrading> _selectedDiamondGrading = {}; // stone name -> 4Cs grading
  Map<String, double> _selectedCaratWeights = {}; // stone name -> carat weight
  String? _selectedRingSize;
  String _engravingText = '';
  final TextEditingController _engravingController = TextEditingController();

  // Diamondere-style accordion state
  bool _isCustomizeExpanded = true;
  Map<String, bool> _stoneExpanded = {};
  bool _isMetalExpanded = false;
  bool _isPlatingExpanded = false;
  bool _isRingSizeExpanded = false;
  bool _isEngravingExpanded = false;
  bool _isRingDetailsExpanded = false;
  bool _isRingSummaryExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Track product view for recently viewed feature
    _trackProductView();

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
    if (widget.product.size != null) {
      _selectedSize = widget.product.size;
    }

    // Initialize enhanced customization options
    if (widget.product.availableMetals.isNotEmpty) {
      _selectedMetal = widget.product.availableMetals.first;
    }
    if (widget.product.availablePlatingColors.isNotEmpty) {
      _selectedPlatingColor = widget.product.availablePlatingColors.first;
    }
    // Initialize stone color selections with first available color for each stone
    for (final stone in widget.product.stones) {
      if (stone.availableColors.isNotEmpty) {
        _selectedStoneColors[stone.name] = stone.availableColors.first;
      }
      // Initialize quality
      if (stone.availableQualities.isNotEmpty) {
        _selectedStoneQualities[stone.name] = stone.availableQualities.first.name;
      } else {
        // Fallback default
        _selectedStoneQualities[stone.name] = StoneQuality.defaults.first.name;
      }
      // Initialize shape
      if (stone.availableShapes.isNotEmpty) {
        _selectedStoneShapes[stone.name] = stone.availableShapes.first;
      } else {
        _selectedStoneShapes[stone.name] = stone.shape; // Use default shape
      }
      // Initialize diamond grading (only for diamonds)
      if (stone.enableDiamondGrading) {
        _selectedDiamondGrading[stone.name] = DiamondGrading(
          colorGrade: 'G',
          clarityGrade: 'VS1',
          cutGrade: 'Excellent',
        );
      }
      // Initialize carat weight
      if (stone.availableCaratWeights != null && stone.availableCaratWeights!.isNotEmpty) {
        _selectedCaratWeights[stone.name] = stone.defaultCaratWeight ?? stone.availableCaratWeights!.first;
      } else if (stone.defaultCaratWeight != null) {
        _selectedCaratWeights[stone.name] = stone.defaultCaratWeight!;
      }
    }
    if (widget.product.availableSizes.isNotEmpty) {
      // Parse sizes in case they're comma-separated
      final firstSize = widget.product.availableSizes.first;
      if (firstSize.contains(',')) {
        final parsed = firstSize.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        _selectedRingSize = parsed.isNotEmpty ? parsed.first : firstSize;
      } else {
        _selectedRingSize = firstSize;
      }
    }

    // Apply customization intent from community post (if provided)
    _applyCustomizationIntent();

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      setState(() {
        // Refresh UI with initialized data
      });
    }
  }

  /// Apply customization intent passed from community post
  void _applyCustomizationIntent() {
    final intent = widget.customizationIntent;
    if (intent == null) return;

    // Apply metal selection
    if (intent['selectedMetal'] != null) {
      final metal = intent['selectedMetal'].toString();
      if (widget.product.availableMetals.contains(metal)) {
        _selectedMetal = metal;
      }
    }

    // Apply plating color selection
    if (intent['selectedPlating'] != null) {
      final plating = intent['selectedPlating'].toString();
      if (widget.product.availablePlatingColors.contains(plating)) {
        _selectedPlatingColor = plating;
      }
    }

    // Apply stone colors
    if (intent['stoneColors'] != null && intent['stoneColors'] is Map) {
      final stoneColors = Map<String, String>.from(intent['stoneColors']);
      for (final entry in stoneColors.entries) {
        final stoneName = entry.key;
        final colorName = entry.value;
        // Find matching stone and verify color is available
        final stone = widget.product.stones.firstWhere(
          (s) => s.name == stoneName,
          orElse: () => const StoneConfig(name: '', shape: '', availableColors: []),
        );
        if (stone.name.isNotEmpty && stone.availableColors.contains(colorName)) {
          _selectedStoneColors[stoneName] = colorName;
        }
      }
    }

    // Apply size selection
    if (intent['selectedSize'] != null) {
      final size = intent['selectedSize'].toString();
      if (widget.product.availableSizes.contains(size)) {
        _selectedRingSize = size;
      }
    }

    // Apply engraving text
    if (intent['engravingText'] != null && widget.product.engravingEnabled) {
      final text = intent['engravingText'].toString();
      _engravingText = text;
      _engravingController.text = text;
    }

    // Log intent application for debugging
    debugPrint('Applied customization intent: metal=$_selectedMetal, '
        'plating=$_selectedPlatingColor, size=$_selectedRingSize, '
        'engraving=$_engravingText');
  }

  /// Track product view for recently viewed feature
  Future<void> _trackProductView() async {
    try {
      // Update local state immediately for real-time UI update
      final recentlyViewedProvider = context.read<RecentlyViewedProvider>();
      recentlyViewedProvider.addProductLocally(widget.product);

      // Track on server in background
      await ApiService.trackProductView(productId: widget.product.id);
      debugPrint('Tracked product view: ${widget.product.id}');
    } catch (e) {
      // Silently fail - don't interrupt user experience for tracking
      debugPrint('Failed to track product view: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _engravingController.dispose();
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
                          // Use sale price if provided, otherwise use customized price
                          Text(
                            '₹${(widget.salePrice ?? _customizedPrice).toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: widget.salePrice != null ? Colors.green.shade700 : AppTheme.primaryGold,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          // Show base price if customization adds cost
                          if (_priceModifier > 0 && widget.salePrice == null)
                            Text(
                              'Base: ₹${widget.product.price.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          // Show original price if sale price is provided or if product has original price
                          if (widget.salePrice != null)
                            Text(
                              '₹${(widget.originalPrice ?? widget.product.price).toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppTheme.textSecondary,
                                  ),
                            )
                          else if (widget.product.originalPrice != null)
                            Text(
                              '₹${widget.product.originalPrice!.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          // Show customization modifier badge
                          if (_priceModifier > 0 && widget.salePrice == null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+₹${_priceModifier.toStringAsFixed(0)} customization',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          // Show discount badge
                          if (widget.discountPercent != null && widget.discountPercent! > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${widget.discountPercent}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (widget.product.discount > 0)
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

                  // === DIAMONDERE-STYLE CUSTOMIZATION UI ===
                  if (widget.product.hasCustomization) ...[
                    _buildDiamondereCustomizationSection(),
                    const SizedBox(height: 16),
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
                              onPressed: (widget.product.stockType == StockType.madeToOrder || _quantity < widget.product.stockQuantity)
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
                  // Stock status display
                  if (widget.product.stockType == StockType.madeToOrder)
                    Row(
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Made to Order - Always Available',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    )
                  else if (widget.product.stockQuantity < 10 && widget.product.stockQuantity > 0)
                    Text(
                      'Only ${widget.product.stockQuantity} left in stock',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningAmber,
                          ),
                    )
                  else if (widget.product.stockQuantity == 0)
                    Text(
                      'Out of Stock',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
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
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Diamondere-style price bar with ADD TO BAG
              Container(
                color: const Color(0xFF8B2332), // Dark red like Diamondere
                child: Row(
                  children: [
                    // Price section
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          '₹${(widget.salePrice ?? _customizedPrice).toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // ADD TO BAG button
                    Expanded(
                      flex: 3,
                      child: Material(
                        color: const Color(0xFF8B2332),
                        child: InkWell(
                          onTap: widget.product.isAvailable
                              ? () {
                                  final customization = _buildCustomization();
                                  cartProvider.addToCart(
                                    widget.product,
                                    quantity: _quantity,
                                    salePrice: widget.salePrice,
                                    originalPrice: widget.originalPrice,
                                    discountPercent: widget.discountPercent,
                                    customization: customization,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added $_quantity ${widget.product.name} to bag'),
                                      backgroundColor: const Color(0xFF8B2332),
                                      action: SnackBarAction(
                                        label: 'VIEW BAG',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/cart');
                                        },
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.product.isAvailable ? 'ADD TO BAG' : 'OUT OF STOCK',
                                  style: TextStyle(
                                    color: widget.product.isAvailable ? Colors.white : Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Delivery info row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Expedited Delivery between ${_getDeliveryDateRange()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              // Contact for custom request
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.mail_outline, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // TODO: Open contact/custom request
                      },
                      child: Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' For A Custom Request',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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



  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRowWithPrice(String label, String value, double priceModifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (priceModifier > 0)
                  Text(
                    '+₹${priceModifier.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build ProductCustomization from current selections
  ProductCustomization? _buildCustomization() {
    // Only return customization if product has customization options and user made selections
    if (!widget.product.hasCustomization) return null;

    final hasSelection = _selectedMetal != null ||
        _selectedPlatingColor != null ||
        _selectedRingSize != null ||
        _selectedStoneColors.isNotEmpty ||
        _selectedStoneShapes.isNotEmpty ||
        _selectedDiamondGrading.isNotEmpty ||
        _selectedCaratWeights.isNotEmpty ||
        _engravingText.isNotEmpty;

    if (!hasSelection) return null;

    return ProductCustomization(
      metalType: _selectedMetal,
      platingColor: _selectedPlatingColor,
      stoneColorSelections: _selectedStoneColors.isNotEmpty ? Map.from(_selectedStoneColors) : null,
      stoneQualitySelections: _selectedStoneQualities.isNotEmpty ? Map.from(_selectedStoneQualities) : null,
      stoneShapeSelections: _selectedStoneShapes.isNotEmpty ? Map.from(_selectedStoneShapes) : null,
      stoneDiamondGrading: _selectedDiamondGrading.isNotEmpty ? Map.from(_selectedDiamondGrading) : null,
      stoneCaratWeights: _selectedCaratWeights.isNotEmpty ? Map.from(_selectedCaratWeights) : null,
      ringSize: _selectedRingSize,
      engraving: _engravingText.isNotEmpty ? _engravingText : null,
      minThickness: widget.product.minThickness,
      maxThickness: widget.product.maxThickness,
    );
  }

  /// Calculate the customized price based on current selections
  double get _customizedPrice {
    final customization = _buildCustomization();
    return widget.product.calculateCustomizedPrice(customization);
  }

  /// Get the price modifier amount (difference from base price)
  double get _priceModifier {
    return _customizedPrice - widget.product.price;
  }

  /// Get product type name based on category/subcategory
  String _getProductTypeName() {
    final category = widget.product.category.toLowerCase();
    final subcategory = widget.product.subcategory.toLowerCase();

    // Check subcategory first for more specific names
    if (subcategory.contains('ring') || subcategory.contains('band')) {
      return 'Ring';
    } else if (subcategory.contains('necklace') || subcategory.contains('pendant') || subcategory.contains('chain')) {
      return 'Necklace';
    } else if (subcategory.contains('earring') || subcategory.contains('stud') || subcategory.contains('hoop')) {
      return 'Earring';
    } else if (subcategory.contains('bracelet') || subcategory.contains('bangle') || subcategory.contains('cuff')) {
      return 'Bracelet';
    } else if (subcategory.contains('anklet')) {
      return 'Anklet';
    } else if (subcategory.contains('nose')) {
      return 'Nose Pin';
    } else if (subcategory.contains('mangalsutra')) {
      return 'Mangalsutra';
    }

    // Fall back to category
    if (category.contains('ring')) {
      return 'Ring';
    } else if (category.contains('necklace') || category.contains('pendant')) {
      return 'Necklace';
    } else if (category.contains('earring')) {
      return 'Earring';
    } else if (category.contains('bracelet') || category.contains('bangle')) {
      return 'Bracelet';
    } else if (category.contains('anklet')) {
      return 'Anklet';
    }

    // Default
    return 'Jewelry';
  }

  /// Get size label based on product type
  String _getSizeLabelName() {
    final productType = _getProductTypeName().toLowerCase();

    switch (productType) {
      case 'ring':
        return 'Ring Size';
      case 'necklace':
      case 'mangalsutra':
        return 'Chain Length';
      case 'bracelet':
      case 'bangle':
        return 'Bracelet Size';
      case 'anklet':
        return 'Anklet Size';
      case 'earring':
        return 'Earring Size';
      default:
        return 'Size';
    }
  }

  /// Get delivery date range (7-10 days from now)
  String _getDeliveryDateRange() {
    final now = DateTime.now();
    final startDate = now.add(const Duration(days: 7));
    final endDate = now.add(const Duration(days: 10));

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return '${months[startDate.month - 1]} ${startDate.day}-${endDate.day}';
  }

  // ============ DIAMONDERE-STYLE CUSTOMIZATION UI ============

  Widget _buildDiamondereCustomizationSection() {
    return Column(
      children: [
        // Main "CUSTOMIZE YOUR RING" accordion
        _buildMainCustomizeAccordion(),

        const SizedBox(height: 12),

        // Customized Ring Details accordion
        if (widget.product.hasCustomization)
          _buildRingDetailsAccordion(),

        const SizedBox(height: 12),

        // Customized Ring Summary accordion
        _buildRingSummaryAccordion(),
      ],
    );
  }

  // Diamondere beige/cream color
  static const Color _diamondereBeige = Color(0xFFF5F0E8);
  static const Color _diamondereDarkBeige = Color(0xFFEDE5D8);

  Widget _buildMainCustomizeAccordion() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header - Diamondere beige style
          InkWell(
            onTap: () {
              setState(() {
                _isCustomizeExpanded = !_isCustomizeExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isCustomizeExpanded ? _diamondereBeige : const Color(0xFFFAF8F5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'CUSTOMIZE YOUR ${_getProductTypeName().toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isCustomizeExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (_isCustomizeExpanded) ...[
            const Divider(height: 1),

            // Stone selections
            ...widget.product.stones.asMap().entries.map((entry) {
              final index = entry.key;
              final stone = entry.value;
              return _buildStoneSelectionRow(stone, index);
            }),

            // Metal selection
            if (widget.product.availableMetals.isNotEmpty)
              _buildMetalSelectionRow(),

            // Plating color selection
            if (widget.product.availablePlatingColors.isNotEmpty)
              _buildPlatingColorSelectionRow(),

            // Ring size selection
            if (widget.product.availableSizes.isNotEmpty)
              _buildRingSizeSelectionRow(),

            // Engraving option
            if (widget.product.engravingEnabled)
              _buildEngravingRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildStoneSelectionRow(StoneConfig stone, int index) {
    final isExpanded = _stoneExpanded[stone.name] ?? false;
    final selectedColor = _selectedStoneColors[stone.name];

    // Format stone name for display (e.g., "Diamond" -> "Diamonds", "Ruby" -> "Rubies")
    String formatStonePlural(String? color) {
      if (color == null) return 'Select';
      // Handle special pluralization
      if (color.toLowerCase().endsWith('y') && !color.toLowerCase().endsWith('ey')) {
        return '${color.substring(0, color.length - 1)}ies';
      } else if (color.toLowerCase().endsWith('s') || color.toLowerCase().endsWith('x')) {
        return '${color}es';
      }
      return '${color}s';
    }

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _stoneExpanded[stone.name] = !isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      children: [
                        TextSpan(text: 'Selected Accent Stones ${index + 1} - '),
                        TextSpan(
                          text: formatStonePlural(selectedColor),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.remove : Icons.add,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        if (isExpanded) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group stones by category
                _buildStoneColorGrid(stone),

                // Quality Selection (New)
                if (selectedColor != null) ...[
                  const SizedBox(height: 16),
                  _buildQualitySelector(stone),
                ],

                // Shape Selection (Diamondere style)
                if (selectedColor != null && stone.availableShapes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  StoneShapeSelector(
                    availableShapes: stone.availableShapes,
                    selectedShape: _selectedStoneShapes[stone.name],
                    priceModifiers: stone.shapePriceModifiers,
                    showPriceModifiers: true,
                    onShapeSelected: (shape) {
                      setState(() {
                        _selectedStoneShapes[stone.name] = shape;
                      });
                    },
                  ),
                ],

                // Diamond 4Cs Grading (only for diamonds with grading enabled)
                if (selectedColor != null && stone.enableDiamondGrading) ...[
                  const SizedBox(height: 16),
                  Diamond4CsSelector(
                    currentGrading: _selectedDiamondGrading[stone.name],
                    availableColorGrades: stone.availableColorGrades ?? StoneConfig.defaultColorGrades,
                    availableClarityGrades: stone.availableClarityGrades ?? StoneConfig.defaultClarityGrades,
                    availableCutGrades: stone.availableCutGrades ?? StoneConfig.defaultCutGrades,
                    colorPriceModifiers: stone.colorGradePriceModifiers ?? GradingPriceTable.colorMultipliers,
                    clarityPriceModifiers: stone.clarityPriceModifiers ?? GradingPriceTable.clarityMultipliers,
                    cutPriceModifiers: stone.cutGradePriceModifiers ?? GradingPriceTable.cutMultipliers,
                    showPriceModifiers: true,
                    onGradingChanged: (grading) {
                      setState(() {
                        _selectedDiamondGrading[stone.name] = grading;
                      });
                    },
                  ),
                ],

                // Carat Weight Selection
                if (selectedColor != null &&
                    stone.availableCaratWeights != null &&
                    stone.availableCaratWeights!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  CaratWeightSelector(
                    availableWeights: stone.availableCaratWeights!,
                    selectedWeight: _selectedCaratWeights[stone.name],
                    pricePerCarat: stone.pricePerCarat,
                    caratPriceMultipliers: stone.caratPriceMultipliers,
                    showPriceImpact: true,
                    onWeightSelected: (weight) {
                      setState(() {
                        _selectedCaratWeights[stone.name] = weight;
                      });
                    },
                  ),
                ],

                // Stone description
                if (selectedColor != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                            children: [
                              TextSpan(
                                text: '$selectedColor: ',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              TextSpan(
                                text: _getStoneDescription(selectedColor),
                              ),
                            ],
                          ),
                        ),
                        if (stone.count != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _buildStoneDescriptionText(stone, selectedColor),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        const Divider(height: 1),
      ],
    );
  }

  String getSelectedQualityName(String stoneName) {
    return _selectedStoneQualities[stoneName] ?? 'Standard';
  }

  String _buildStoneDescriptionText(StoneConfig stone, String selectedColor) {
    final shape = _selectedStoneShapes[stone.name] ?? stone.shape;
    final quality = getSelectedQualityName(stone.name);
    final grading = _selectedDiamondGrading[stone.name];
    final caratWeight = _selectedCaratWeights[stone.name];

    StringBuffer text = StringBuffer();
    text.write('These ${stone.count} ${shape.toLowerCase()}-cut ${selectedColor}s');

    if (caratWeight != null) {
      text.write(' (${caratWeight.toStringAsFixed(2)} ct each)');
    }

    text.write(' are of $quality quality');

    if (grading != null) {
      text.write(' with ${grading.shortSummary} grading');
    }

    text.write('.');
    return text.toString();
  }

  Widget _buildQualitySelector(StoneConfig stone) {
    final selectedQualityName = _selectedStoneQualities[stone.name];
    List<StoneQuality> qualities = stone.availableQualities.isNotEmpty
        ? stone.availableQualities
        : StoneQuality.defaults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select The Quality Of Your ${stone.name}:',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: qualities.map((quality) {
            final isSelected = selectedQualityName == quality.name;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStoneQualities[stone.name] = quality.name;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.grey.shade50,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      // Placeholder for gem image
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _getColorFromName(_selectedStoneColors[stone.name] ?? 'Red'), 
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(4)
                        ),
                      ),
                      Text(
                        quality.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.black : Colors.grey.shade700,
                        ),
                      ),
                      if (quality.priceMultiplier > 1.0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${((quality.priceMultiplier - 1.0) * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStoneColorGrid(StoneConfig stone) {
    // strict categorization based on data model, falling back to all
    // For now, if we want to display distinct categories, we should ideally have them in the data model.
    // Since StoneConfig only has a single 'category' field for the slot itself (e.g. this slot is for Precious stones),
    // but the availableColors might be mixed? 
    // Actually, looking at the Diamondere screenshot, 'Diamonds', 'Precious', 'Semi-Precious' are HEADERS.
    // The user might want to pick a Diamond OR a Ruby for the SAME slot.
    // So we need to group the `availableColors` by their type.
    
    final diamonds = <String>[];
    final precious = <String>[];
    final semiPrecious = <String>[];
    final labCreated = <String>[];

    for (final color in stone.availableColors) {
      final lowerColor = color.toLowerCase();
      // Improved categorization logic
      if (lowerColor.contains('diamond') && !lowerColor.contains('lab')) {
        diamonds.add(color);
      } else if (lowerColor.contains('ruby') || lowerColor.contains('emerald') || lowerColor.contains('sapphire')) {
        precious.add(color);
      } else if (lowerColor.contains('lab') || lowerColor.contains('created') || lowerColor.contains('cz')) {
        labCreated.add(color);
      } else {
        semiPrecious.add(color);
      }
    }
    
    // ... continue strict rendering logic

    // If no categorization matches, show all in one grid
    if (diamonds.isEmpty && precious.isEmpty && semiPrecious.isEmpty && labCreated.isEmpty) {
      return _buildColorSwatchRow(null, stone.availableColors, stone.name);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (diamonds.isNotEmpty)
          _buildColorSwatchRow('Diamonds', diamonds, stone.name),
        if (precious.isNotEmpty)
          _buildColorSwatchRow('Precious', precious, stone.name),
        if (semiPrecious.isNotEmpty)
          _buildColorSwatchRow('Semi-Precious', semiPrecious, stone.name),
        if (labCreated.isNotEmpty)
          _buildColorSwatchRow('Lab-created', labCreated, stone.name),
      ],
    );
  }

  Widget _buildColorSwatchRow(String? category, List<String> colors, String stoneName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category != null) ...[
          const SizedBox(height: 8),
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final isSelected = _selectedStoneColors[stoneName] == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStoneColors[stoneName] = color;
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getColorFromName(color),
                    border: Border.all(color: Colors.grey.shade200, width: 0.5),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 16, color: _getContrastColor(color))
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetalSelectionRow() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isMetalExpanded = !_isMetalExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      children: [
                        const TextSpan(text: 'Selected Metal - '),
                        TextSpan(
                          text: _selectedMetal ?? 'Select',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  _isMetalExpanded ? Icons.remove : Icons.add,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        if (_isMetalExpanded) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metal type headers
                _buildMetalTypeHeaders(),
                const SizedBox(height: 12),
                // Metal grid
                _buildMetalGrid(),

                // Metal description
                if (_selectedMetal != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getMetalDescription(_selectedMetal!),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        const Divider(height: 1),
      ],
    );
  }

  Widget _buildPlatingColorSelectionRow() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isPlatingExpanded = !_isPlatingExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      children: [
                        const TextSpan(text: 'Selected Plating - '),
                        TextSpan(
                          text: _selectedPlatingColor ?? 'Select',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  _isPlatingExpanded ? Icons.remove : Icons.add,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        if (_isPlatingExpanded) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plating color chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.product.availablePlatingColors.map((plating) {
                    final isSelected = _selectedPlatingColor == plating;
                    final modifier = widget.product.platingPriceModifiers[plating] ?? 0;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlatingColor = plating;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryGold : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Color circle preview
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getPlatingColor(plating),
                                border: Border.all(color: Colors.grey.shade400, width: 0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              plating,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? Colors.white : Colors.grey.shade800,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            if (modifier > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '+₹${modifier.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white70 : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Plating description
                if (_selectedPlatingColor != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPlatingDescription(_selectedPlatingColor!),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        const Divider(height: 1),
      ],
    );
  }

  Color _getPlatingColor(String plating) {
    final lowerPlating = plating.toLowerCase();
    if (lowerPlating.contains('white')) {
      return const Color(0xFFF5F5F5);
    } else if (lowerPlating.contains('yellow') || lowerPlating.contains('gold')) {
      return const Color(0xFFFFD700);
    } else if (lowerPlating.contains('rose')) {
      return const Color(0xFFE8B4B8);
    } else if (lowerPlating.contains('rhodium')) {
      return const Color(0xFFE5E4E2);
    } else if (lowerPlating.contains('black')) {
      return const Color(0xFF2C2C2C);
    }
    return Colors.grey.shade300;
  }

  String _getPlatingDescription(String plating) {
    final lowerPlating = plating.toLowerCase();
    if (lowerPlating.contains('white')) {
      return 'White Gold plating offers a sleek, modern look with a silvery sheen that complements diamonds and cool-toned gemstones beautifully.';
    } else if (lowerPlating.contains('yellow')) {
      return 'Yellow Gold plating provides a classic, warm appearance that has been cherished for centuries. It pairs well with warm-toned gemstones.';
    } else if (lowerPlating.contains('rose')) {
      return 'Rose Gold plating features a romantic pinkish hue created by copper alloy. It offers a contemporary, feminine aesthetic.';
    } else if (lowerPlating.contains('rhodium')) {
      return 'Rhodium plating provides exceptional durability and a bright, reflective finish. It is hypoallergenic and resistant to tarnish.';
    } else if (lowerPlating.contains('black')) {
      return 'Black Gold plating creates a bold, contemporary look. It is achieved through specialized coating techniques for a unique appearance.';
    }
    return 'Premium quality plating for enhanced beauty and durability.';
  }

  Widget _buildMetalTypeHeaders() {
    return Row(
      children: [
        _buildMetalHeader('Platinum', 50),
        _buildMetalHeader('18k', 40),
        _buildMetalHeader('14k', 40),
        _buildMetalHeader('10k', 40),
        _buildMetalHeader('Silver', 50),
      ],
    );
  }

  Widget _buildMetalHeader(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetalGrid() {
    // Dynamically organize metals from admin data into Diamondere-style grid
    final availableMetals = widget.product.availableMetals;

    // Categorize metals by color type and karat
    final Map<String, Map<String, String>> metalMatrix = {
      'White': {},
      'Yellow': {},
      'Rose': {},
      'Black': {},
    };

    // Column order for display
    final columnOrder = ['Platinum', '18K', '14K', '10K', '9K', '22K', 'Silver', 'Vermeil'];

    for (final metal in availableMetals) {
      final metalLower = metal.toLowerCase();

      // Determine color type
      String colorType = 'White'; // default
      if (metalLower.contains('yellow')) {
        colorType = 'Yellow';
      } else if (metalLower.contains('rose') || metalLower.contains('pink')) {
        colorType = 'Rose';
      } else if (metalLower.contains('black')) {
        colorType = 'Black';
      }

      // Determine karat/type column
      String column = '';
      if (metalLower.contains('platinum') || metalLower.contains('pt')) {
        column = 'Platinum';
      } else if (metalLower.contains('22k')) {
        column = '22K';
      } else if (metalLower.contains('18k')) {
        column = '18K';
      } else if (metalLower.contains('14k')) {
        column = '14K';
      } else if (metalLower.contains('10k')) {
        column = '10K';
      } else if (metalLower.contains('9k')) {
        column = '9K';
      } else if (metalLower.contains('silver') || metalLower.contains('925')) {
        column = 'Silver';
      } else if (metalLower.contains('vermeil')) {
        column = 'Vermeil';
      } else {
        // For metals that don't fit the pattern, put them in their own column
        column = metal;
      }

      metalMatrix[colorType]![column] = metal;
    }

    // Find which columns have at least one metal
    final Set<String> activeColumns = {};
    for (final colorMetals in metalMatrix.values) {
      activeColumns.addAll(colorMetals.keys);
    }

    // Sort columns by preferred order
    final sortedColumns = columnOrder.where((c) => activeColumns.contains(c)).toList();
    // Add any columns not in the preferred order
    for (final col in activeColumns) {
      if (!sortedColumns.contains(col)) {
        sortedColumns.add(col);
      }
    }

    // Find which rows have at least one metal
    final activeRows = metalMatrix.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();

    if (sortedColumns.isEmpty || activeRows.isEmpty) {
      // Fallback: just show all metals as buttons in a wrap
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: availableMetals.map((metal) => _buildMetalButton(metal)).toList(),
      );
    }

    return Column(
      children: [
        // Column headers
        Row(
          children: sortedColumns.map((col) {
            return SizedBox(
              width: 44,
              child: Text(
                _getColumnLabel(col),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Metal rows
        ...activeRows.map((colorType) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: sortedColumns.map((col) {
                final metal = metalMatrix[colorType]![col];
                if (metal == null) {
                  return const SizedBox(width: 44);
                }
                return _buildMetalButton(metal);
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  String _getColumnLabel(String column) {
    switch (column) {
      case 'Platinum': return 'Platinum';
      case '22K': return '22k';
      case '18K': return '18k';
      case '14K': return '14k';
      case '10K': return '10k';
      case '9K': return '9k';
      case 'Silver': return 'Silver';
      case 'Vermeil': return 'Vermeil';
      default: return column;
    }
  }

  Widget _buildMetalButton(String metal) {
    final isSelected = _selectedMetal == metal;
    String label = '';
    Color bgColor = Colors.grey.shade200;

    if (metal.contains('Platinum')) {
      label = 'PT';
      bgColor = const Color(0xFFE5E4E2);
    } else if (metal.contains('Silver')) {
      label = 'SLV';
      bgColor = const Color(0xFFC0C0C0);
    } else if (metal.contains('Vermeil')) {
      label = 'VER';
      bgColor = const Color(0xFFFFD700); // Gold color for vermeil
    } else if (metal.contains('18K')) {
      label = '18k';
    } else if (metal.contains('14K')) {
      label = '14k';
    } else if (metal.contains('10K')) {
      label = '10k';
    }

    // Apply color based on metal type
    if (metal.contains('White')) {
      bgColor = const Color(0xFFF5F5F5);
    } else if (metal.contains('Yellow')) {
      bgColor = const Color(0xFFFFD700);
    } else if (metal.contains('Rose')) {
      bgColor = const Color(0xFFE8B4B8);
    } else if (metal.contains('Black')) {
      bgColor = const Color(0xFF2C2C2C); // Dark grey/black for black gold
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMetal = metal;
          });
        },
        child: Container(
          width: 40,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: metal.contains('Black')
                    ? Colors.white
                    : metal.contains('Yellow') || metal.contains('Vermeil')
                        ? Colors.brown.shade800
                        : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get parsed individual sizes from availableSizes (handles comma-separated strings)
  List<String> _getParsedSizes() {
    final List<String> parsedSizes = [];
    for (final size in widget.product.availableSizes) {
      // Split if comma-separated
      if (size.contains(',')) {
        parsedSizes.addAll(size.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
      } else {
        parsedSizes.add(size.trim());
      }
    }
    return parsedSizes;
  }

  Widget _buildRingSizeSelectionRow() {
    final parsedSizes = _getParsedSizes();

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isRingSizeExpanded = !_isRingSizeExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      children: [
                        TextSpan(text: 'Add ${_getSizeLabelName()} - '),
                        TextSpan(
                          text: _selectedRingSize ?? 'Please Select',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedRingSize == null ? Colors.grey.shade500 : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  _isRingSizeExpanded ? Icons.remove : Icons.add,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        if (_isRingSizeExpanded) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ring Size label and dropdown
                Row(
                  children: [
                    Text(
                      '${_getSizeLabelName()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    // View Size Guide link
                    GestureDetector(
                      onTap: () {
                        _showRingSizeGuide();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View ${_getSizeLabelName()} Guide',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Dropdown menu - Diamondere style
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRingSize,
                      isExpanded: true,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Select ${_getSizeLabelName()}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      icon: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                      ),
                      menuMaxHeight: 300,
                      items: parsedSizes.map((size) {
                        return DropdownMenuItem<String>(
                          value: size,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                if (_selectedRingSize == size)
                                  Icon(Icons.check, size: 16, color: Colors.grey.shade700),
                                if (_selectedRingSize == size)
                                  const SizedBox(width: 8),
                                Text(
                                  size,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRingSize = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const Divider(height: 1),
      ],
    );
  }

  Widget _buildEngravingRow() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isEngravingExpanded = !_isEngravingExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      children: [
                        const TextSpan(text: 'Add Engraving - '),
                        TextSpan(
                          text: _engravingText.isNotEmpty ? '"$_engravingText"' : 'Optional',
                          style: TextStyle(
                            fontWeight: _engravingText.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                            fontStyle: _engravingText.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  _isEngravingExpanded ? Icons.remove : Icons.add,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        if (_isEngravingExpanded) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _engravingController,
                  maxLength: widget.product.maxEngravingChars,
                  decoration: InputDecoration(
                    hintText: 'Enter engraving text (max ${widget.product.maxEngravingChars} characters)',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    counterText: '${_engravingText.length}/${widget.product.maxEngravingChars}',
                    suffixIcon: _engravingText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _engravingController.clear();
                                _engravingText = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _engravingText = value;
                    });
                  },
                ),
                if (widget.product.engravingPrice > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Engraving cost: ₹${widget.product.engravingPrice.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],

        const Divider(height: 1),
      ],
    );
  }

  Widget _buildRingDetailsAccordion() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isRingDetailsExpanded = !_isRingDetailsExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isRingDetailsExpanded ? _diamondereBeige : const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Customized ${_getProductTypeName()} Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isRingDetailsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          if (_isRingDetailsExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Metal Type', widget.product.metalType),
                  if (widget.product.stoneType != null)
                    _buildDetailRow('Stone Type', widget.product.stoneType!),
                  if (widget.product.weight != null)
                    _buildDetailRow('Weight', '${widget.product.weight}g'),
                  if (widget.product.minThickness != null || widget.product.maxThickness != null)
                    _buildDetailRow('Thickness', '${widget.product.minThickness ?? '-'}mm - ${widget.product.maxThickness ?? '-'}mm'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRingSummaryAccordion() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isRingSummaryExpanded = !_isRingSummaryExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isRingSummaryExpanded ? _diamondereBeige : const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Customized ${_getProductTypeName()} Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isRingSummaryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          if (_isRingSummaryExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stone summaries
                  ...widget.product.stones.map((stone) {
                    final selectedColor = _selectedStoneColors[stone.name];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryBullet('${stone.name}: ${stone.count ?? 1} ${stone.shape}-Cut ${selectedColor ?? "Not Selected"}'),
                        _buildSummaryBullet('${stone.name} Quality: Premium Grade'),
                        if (stone.count != null)
                          _buildSummaryBullet('${stone.name} Total: ${stone.count} stones'),
                      ],
                    );
                  }),

                  // Metal/Setting summary
                  _buildSummaryBullet('Setting: ${_selectedMetal ?? widget.product.metalType} ${_getProductTypeName()}'),

                  // Size
                  if (widget.product.availableSizes.isNotEmpty)
                    _buildSummaryBullet('${_getSizeLabelName()}: ${_selectedRingSize ?? "Not Selected"}'),

                  // Engraving
                  if (_engravingText.isNotEmpty)
                    _buildSummaryBullet('Engraving: "$_engravingText"'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.grey.shade600)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    final lower = colorName.toLowerCase();
    if (lower.contains('diamond') || lower.contains('white') || lower.contains('clear')) {
      return Colors.white;
    } else if (lower.contains('ruby') || lower.contains('red')) {
      return Colors.red.shade700;
    } else if (lower.contains('emerald') || lower.contains('green')) {
      return Colors.green.shade700;
    } else if (lower.contains('sapphire') || lower.contains('blue')) {
      return Colors.blue.shade700;
    } else if (lower.contains('amethyst') || lower.contains('purple')) {
      return Colors.purple.shade700;
    } else if (lower.contains('citrine') || lower.contains('yellow')) {
      return Colors.amber.shade600;
    } else if (lower.contains('pink') || lower.contains('rose')) {
      return Colors.pink.shade400;
    } else if (lower.contains('black') || lower.contains('onyx')) {
      return Colors.black;
    } else if (lower.contains('aquamarine') || lower.contains('aqua')) {
      return Colors.cyan.shade400;
    } else if (lower.contains('topaz')) {
      return Colors.orange.shade400;
    } else if (lower.contains('peridot')) {
      return Colors.lightGreen.shade500;
    } else if (lower.contains('garnet')) {
      return Colors.red.shade900;
    } else if (lower.contains('opal')) {
      return Colors.blueGrey.shade200;
    }
    return Colors.grey.shade400;
  }

  Color _getContrastColor(String colorName) {
    final color = _getColorFromName(colorName);
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  String _getStoneDescription(String colorName) {
    final lower = colorName.toLowerCase();
    if (lower.contains('diamond')) {
      return 'The eternal white Diamond offered in premium quality. Diamonds are of fine quality and a standard in the jewelry market.';
    } else if (lower.contains('amethyst')) {
      return 'Our Natural Amethyst gemstones have a deep purple color, the color of royalty and nobility. Amethyst is February\'s birthstone.';
    } else if (lower.contains('sapphire')) {
      return 'Natural Sapphires with rich blue color symbolizing wisdom, virtue, and good fortune. September\'s birthstone.';
    } else if (lower.contains('ruby')) {
      return 'The king of gemstones, Ruby symbolizes passion, protection, and prosperity. July\'s birthstone.';
    } else if (lower.contains('emerald')) {
      return 'Known for its rich green color, Emerald represents rebirth and love. May\'s birthstone.';
    }
    return 'A beautiful gemstone of exceptional quality and craftsmanship.';
  }

  String _getMetalDescription(String metal) {
    if (metal.contains('14K') && metal.contains('White')) {
      return '14K WHITE GOLD: The brightness makes our solid white gold jewelry very appealing. White gold is trendy and more popular with the youth. 14k white gold contains 58% pure gold. Our 14k jewelry is Rhodium finished and Nickel-safe.';
    } else if (metal.contains('18K') && metal.contains('White')) {
      return '18K WHITE GOLD: Premium white gold with 75% pure gold content. Luxurious and durable, perfect for everyday wear.';
    } else if (metal.contains('Yellow')) {
      return 'YELLOW GOLD: Classic and timeless, yellow gold has been cherished for centuries. Its warm tone complements all skin types.';
    } else if (metal.contains('Rose')) {
      return 'ROSE GOLD: A romantic pink hue created by alloying gold with copper. Modern and elegant, perfect for a contemporary look.';
    } else if (metal.contains('Platinum')) {
      return 'PLATINUM: The most precious metal, naturally white and hypoallergenic. Extremely durable and resistant to wear.';
    } else if (metal.contains('Silver')) {
      return '925 STERLING SILVER: High-quality silver alloy with 92.5% pure silver. Affordable luxury with beautiful shine.';
    }
    return 'High-quality metal crafted with precision and care.';
  }

  void _showRingSizeGuide() {
    final productType = _getProductTypeName().toLowerCase();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_getSizeLabelName()} Guide',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'How to Measure Your ${_getSizeLabelName()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getSizeMeasureInstructions(productType),
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Size Chart',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildSizeChartTable(productType),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSizeMeasureInstructions(String productType) {
    switch (productType) {
      case 'ring':
        return '1. Wrap a piece of string or paper around your finger\n'
            '2. Mark where the ends meet\n'
            '3. Measure the length in millimeters\n'
            '4. Use the chart below to find your size';
      case 'necklace':
      case 'mangalsutra':
        return '1. Use a soft measuring tape around your neck\n'
            '2. Add 2-4 inches for a comfortable fit\n'
            '3. Choose your preferred length from the chart below\n'
            '4. Consider the neckline of your outfit';
      case 'bracelet':
      case 'bangle':
        return '1. Measure your wrist with a soft measuring tape\n'
            '2. Add 0.5-1 inch for a comfortable fit\n'
            '3. For bangles, measure the widest part of your hand\n'
            '4. Use the chart below to find your size';
      case 'anklet':
        return '1. Measure around your ankle with a soft tape\n'
            '2. Add 0.5 inch for a comfortable fit\n'
            '3. Use the chart below to find your size';
      default:
        return '1. Measure the appropriate body part\n'
            '2. Add some extra for comfortable fit\n'
            '3. Use the chart below to find your size';
    }
  }

  Widget _buildSizeChartTable(String productType) {
    List<List<String>> sizes;
    List<String> headers;

    switch (productType) {
      case 'ring':
        headers = ['US Size', 'UK Size', 'Diameter'];
        sizes = [
          ['US 3', 'UK F', '14mm'],
          ['US 4', 'UK H', '14.9mm'],
          ['US 5', 'UK J', '15.7mm'],
          ['US 6', 'UK L', '16.5mm'],
          ['US 7', 'UK N', '17.3mm'],
          ['US 8', 'UK P', '18.1mm'],
          ['US 9', 'UK R', '19mm'],
          ['US 10', 'UK T', '19.8mm'],
        ];
        break;
      case 'necklace':
      case 'mangalsutra':
        headers = ['Length', 'Style', 'Best For'];
        sizes = [
          ['14"', 'Collar', 'Crew necklines'],
          ['16"', 'Choker', 'Most necklines'],
          ['18"', 'Princess', 'V-neck, Scoop'],
          ['20"', 'Matinee', 'Business wear'],
          ['24"', 'Opera', 'High necklines'],
          ['30"+', 'Rope', 'Layering'],
        ];
        break;
      case 'bracelet':
      case 'bangle':
        headers = ['Wrist Size', 'Bracelet Size', 'Fit'];
        sizes = [
          ['5.5"', '6.5"', 'Extra Small'],
          ['6"', '7"', 'Small'],
          ['6.5"', '7.5"', 'Medium'],
          ['7"', '8"', 'Large'],
          ['7.5"', '8.5"', 'Extra Large'],
        ];
        break;
      case 'anklet':
        headers = ['Ankle Size', 'Anklet Size', 'Fit'];
        sizes = [
          ['8"', '9"', 'Small'],
          ['9"', '10"', 'Medium'],
          ['10"', '11"', 'Large'],
        ];
        break;
      default:
        headers = ['Size', 'Measurement', 'Fit'];
        sizes = [
          ['S', 'Small', 'Snug fit'],
          ['M', 'Medium', 'Regular fit'],
          ['L', 'Large', 'Comfortable fit'],
        ];
    }

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: headers.map((header) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
          )).toList(),
        ),
        ...sizes.map((row) => TableRow(
          children: row.map((cell) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text(cell),
          )).toList(),
        )),
      ],
    );
  }
}