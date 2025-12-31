import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badges/badges.dart' as badges;
import '../../viewmodels/cart_provider.dart';
import '../../viewmodels/wishlist_provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/product_provider.dart';
import '../../../utils/theme.dart';
import '../../../utils/product_navigation.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/homepage.dart';
import '../../../data/models/product.dart';
import '../../../data/models/storefront.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';
import '../product/product_list_screen.dart';

class RedesignedHomeScreen extends StatefulWidget {
  const RedesignedHomeScreen({super.key});

  @override
  State<RedesignedHomeScreen> createState() => _RedesignedHomeScreenState();
}

class _RedesignedHomeScreenState extends State<RedesignedHomeScreen> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  HomepageData? _homepageData;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _banners = [];
  String _selectedGenderFilter = 'all';

  // Flash sale countdown
  Duration _flashSaleTimeLeft = const Duration(hours: 3, minutes: 53, seconds: 32);
  Timer? _countdownTimer;

  // Storefront data
  List<Map<String, dynamic>> _occasions = [];
  List<Map<String, dynamic>> _budgetRanges = [];
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, bool> _expandedCategories = {}; // Track which categories are expanded

  @override
  void initState() {
    super.initState();
    _loadHomepageData();
    _loadStorefrontData();
    _startBannerAutoSlide();
    _startFlashSaleCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (productProvider.products.isEmpty) {
        await productProvider.loadProducts();
      }
      // Load categories after products are loaded
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _countdownTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerAutoSlide() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients && _banners.isNotEmpty) {
        final nextPage = (_currentBannerIndex + 1) % _banners.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startFlashSaleCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_flashSaleTimeLeft.inSeconds > 0) {
            _flashSaleTimeLeft = _flashSaleTimeLeft - const Duration(seconds: 1);
          }
        });
      }
    });
  }

  Future<void> _loadHomepageData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final response = await ApiService.getHomepage();

      if (response['success'] == true && response['data'] != null) {
        _homepageData = HomepageData.fromJson(response['data']);

        // Extract banners from sections
        final bannerSection = _homepageData!.sections.where((s) => s.type == SectionType.bannerCarousel).firstOrNull;
        if (bannerSection != null && bannerSection.config['banners'] != null) {
          final bannersList = bannerSection.config['banners'] as List;
          _banners = bannersList.map((banner) {
            return {
              'image': banner['imageUrl'] ?? '',
              'title': banner['title'] ?? 'Welcome to Thyne',
              'subtitle': banner['subtitle'] ?? '',
              'action': banner['actionText'] ?? 'Explore',
            };
          }).toList();
        } else {
          // No banners configured - show empty
          _banners = [];
        }

        setState(() {
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Failed to load homepage data';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadStorefrontData() async {
    try {
      // Load all storefront data in parallel
      final results = await Future.wait([
        ApiService.getOccasions(),
        ApiService.getBudgetRanges(),
        ApiService.getCollections(),
      ]);

      setState(() {
        if (results[0]['success'] == true && results[0]['data'] != null) {
          _occasions = List<Map<String, dynamic>>.from(results[0]['data']);
        }
        if (results[1]['success'] == true && results[1]['data'] != null) {
          _budgetRanges = List<Map<String, dynamic>>.from(results[1]['data']);
        }
        if (results[2]['success'] == true && results[2]['data'] != null) {
          _collections = List<Map<String, dynamic>>.from(results[2]['data']);
        }
      });
    } catch (e) {
      debugPrint('Error loading storefront data: $e');
      // Use empty lists on error
    }
  }

  Future<void> _loadCategories() async {
    try {
      // Load categories from backend API
      final response = await ApiService.getVisibleCategories();

      if (response['success'] == true && response['data'] != null) {
        final categoriesData = response['data'] as List;
        final categoriesList = categoriesData.map((cat) {
          return {
            'id': cat['id'] ?? cat['_id'] ?? '',
            'name': cat['name'] ?? '',
            'slug': cat['slug'] ?? '',
            'description': cat['description'] ?? '',
            'image': cat['image'] ?? '',
            'subcategories': cat['subcategories'] ?? [],
            'gender': cat['gender'] ?? ['all'],
            'sortOrder': cat['sortOrder'] ?? 0,
          };
        }).toList();

        // Sort by sortOrder
        categoriesList.sort((a, b) => (a['sortOrder'] as int).compareTo(b['sortOrder'] as int));

        if (mounted) {
          setState(() {
            _categories = categoriesList;
          });
        }
        debugPrint('✅ Loaded ${categoriesList.length} categories from API');
      } else {
        debugPrint('⚠️ No categories from API, falling back to products');
        _loadCategoriesFromProducts();
      }
    } catch (e) {
      debugPrint('❌ Error loading categories from API: $e');
      _loadCategoriesFromProducts();
    }
  }

  // Fallback: Extract categories from products if API fails
  void _loadCategoriesFromProducts() {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final Set<String> uniqueCategories = {};

      for (var product in productProvider.allProducts) {
        if (product.category.isNotEmpty) {
          uniqueCategories.add(product.category);
        }
      }

      final categoriesList = uniqueCategories.map((categoryName) {
        return {
          'id': categoryName.toLowerCase().replaceAll(' ', '-'),
          'name': categoryName,
          'image': '',
          'subcategories': <String>[],
          'gender': ['all'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _categories = categoriesList;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories from products: $e');
    }
  }

  // Helper method to filter categories by selected gender
  List<Map<String, dynamic>> _filterCategoriesByGender() {
    return _categories.where((category) {
      final List<dynamic> genderList = category['gender'] ?? [];
      // If category has no gender specified, show it for all filters
      if (genderList.isEmpty) return true;

      // Check if category's gender list contains the selected filter
      return genderList.contains(_selectedGenderFilter);
    }).toList();
  }

  // Helper method to filter products by selected gender
  List<Product> _filterProductsByGender(List<Product> products) {
    return products.where((product) {
      // If product has no gender specified or gender list is empty, show it for all filters
      if (product.gender.isEmpty) return true;

      // Check if product's gender list contains the selected filter
      return product.gender.contains(_selectedGenderFilter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom Header
            _buildCustomHeader(authProvider, cartProvider, wishlistProvider),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadHomepageData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100), // Space for FAB + search bar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gender Filter Pills
                      _buildGenderFilterPills(),

                      // Conditional rendering based on filter selection
                      if (_selectedGenderFilter == 'all') ...[
                        // Show all sections for "all" filter
                        const SizedBox(height: 16),

                        // Hero Banner
                        _buildHeroBanner(),

                        const SizedBox(height: 24),

                        // Shop by Occasion
                        _buildShopByOccasion(),

                        const SizedBox(height: 24),

                        // Shop by Budget
                        _buildShopByBudget(),

                        const SizedBox(height: 24),

                        // Flash Deals Banner
                        _buildFlashDealsBanner(),

                        const SizedBox(height: 24),

                        // Complete Your Look
                        _buildCompleteYourLook(),

                        const SizedBox(height: 24),

                        // Curated Collections
                        _buildCuratedCollections(),

                        const SizedBox(height: 24),

                        // Handpicked For You
                        _buildHandpickedForYou(),

                        const SizedBox(height: 24),

                        // Trending Now
                        _buildTrendingNow(),

                        const SizedBox(height: 24),

                        // Recently Viewed
                        _buildRecentlyViewed(),

                        const SizedBox(height: 24),

                        // New Arrivals
                        _buildNewArrivals(),
                      ] else ...[
                        // Show only Top Categories for specific gender filters
                        _buildTopCategories(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(AuthProvider authProvider, CartProvider cartProvider, WishlistProvider wishlistProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          // Top row: Logo and User Avatar
          Row(
            children: [
              // Globe icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.language, size: 20, color: Colors.grey),
              ),
              const SizedBox(width: 12),

              // THYNE Logo
              const Text(
                'THYNE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const Spacer(),

              // User Avatar
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 20,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Delivery Location + Icons
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              const Text(
                'deliver to ',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const Text(
                'Sector 2',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),

              const Spacer(),

              // Gift Icon
              IconButton(
                icon: const Icon(Icons.card_giftcard_outlined, size: 22),
                onPressed: () {
                  // TODO: Navigate to gifts
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
              ),

              // Wishlist Icon
              IconButton(
                icon: badges.Badge(
                  badgeContent: Text(
                    wishlistProvider.wishlistCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                  showBadge: wishlistProvider.wishlistCount > 0,
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: AppTheme.errorRed,
                  ),
                  child: const Icon(Icons.favorite_outline, size: 22),
                ),
                onPressed: () => Navigator.pushNamed(context, '/wishlist'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
              ),

              // Cart Icon
              IconButton(
                icon: badges.Badge(
                  badgeContent: Text(
                    cartProvider.itemCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                  showBadge: cartProvider.itemCount > 0,
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: AppTheme.primaryGold,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 22),
                ),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderFilterPills() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterPill('all', 'all'),
            const SizedBox(width: 12),
            _buildFilterPill('women', 'women'),
            const SizedBox(width: 12),
            _buildFilterPill('men', 'men'),
            const SizedBox(width: 12),
            _buildFilterPill('inclusive', 'inclusive'),
            const SizedBox(width: 12),
            _buildFilterPill('kids', 'kids'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _selectedGenderFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGenderFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.primaryGold : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCategories() {
    // Show all categories, but filter products within them by gender
    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final categoryId = category['id'] ?? '';
              final categoryName = category['name'] ?? '';
              final isExpanded = _expandedCategories[categoryId] ?? false;

              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedCategories[categoryId] = !isExpanded;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: isExpanded ? AppTheme.primaryGold : Colors.grey.shade300,
                          width: isExpanded ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          if (category['image'] != null && category['image'].toString().isNotEmpty)
                            Image.network(
                              category['image'],
                              width: 32,
                              height: 32,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.category,
                                size: 32,
                                color: AppTheme.primaryGold,
                              ),
                            )
                          else
                            Icon(
                              Icons.category,
                              size: 32,
                              color: AppTheme.primaryGold,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isExpanded ? FontWeight.w600 : FontWeight.normal,
                                color: isExpanded ? AppTheme.primaryGold : AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.chevron_right,
                            color: isExpanded ? AppTheme.primaryGold : Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expanded content
                  if (isExpanded) _buildExpandedCategoryContent(categoryName),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCategoryContent(String categoryName) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    // Get the category data to access subcategories
    final categoryData = _categories.firstWhere(
      (cat) => cat['name'].toString().toLowerCase() == categoryName.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );

    // Get subcategories from category data (from API)
    final List<dynamic> subcategoriesRaw = categoryData['subcategories'] ?? [];
    final List<String> subcategories = subcategoriesRaw.map((s) => s.toString()).toList();

    // Get all products (not filtered)
    final allProducts = productProvider.allProducts;

    // Filter products by category
    final categoryProducts = allProducts.where((product) {
      final productCategory = product.category.toLowerCase();
      final filterCategory = categoryName.toLowerCase();
      return productCategory == filterCategory ||
          productCategory.contains(filterCategory) ||
          filterCategory.contains(productCategory);
    }).toList();

    // Extract unique style tags from category products
    final Set<String> styleTags = {};
    for (var product in categoryProducts) {
      for (var tag in product.tags) {
        // Only include style-related tags (not gender tags)
        final lowerTag = tag.toLowerCase();
        if (!['men', 'women', 'male', 'female', 'unisex', 'kids'].contains(lowerTag)) {
          styleTags.add(tag);
        }
      }
    }

    // Get trending products (first 4) filtered by gender
    final trendingProducts = categoryProducts.where((product) {
      if (_selectedGenderFilter == 'all' || product.gender.isEmpty) return true;
      return product.gender.any((g) => g.toLowerCase() == _selectedGenderFilter.toLowerCase());
    }).take(4).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending Section with horizontal scroll
          if (trendingProducts.isNotEmpty) ...[
            const Text(
              'Trending',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trendingProducts.length,
                itemBuilder: (context, index) {
                  final product = trendingProducts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.images.isNotEmpty ? product.images.first : '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Subcategories Section (from backend API)
          if (subcategories.isNotEmpty) ...[
            const Text(
              'Subcategories',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subcategories.map((subcategory) => ActionChip(
                label: Text(subcategory),
                backgroundColor: Colors.grey.shade100,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(
                        category: categoryName,
                        subcategory: subcategory,
                        gender: _selectedGenderFilter == 'all' ? null : _selectedGenderFilter,
                      ),
                    ),
                  );
                },
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Shop By Style / Shop By Price toggle buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Show style tags if available
                    if (styleTags.isNotEmpty) {
                      _showStyleTagsBottomSheet(categoryName, styleTags.toList());
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Shop By Style'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5016),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Shop By Price ( ₹ )'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price Range Buttons
          _buildPriceRangeGrid(categoryName),

          const SizedBox(height: 16),

          // View All Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductListScreen(
                      category: categoryName,
                      gender: _selectedGenderFilter == 'all' ? null : _selectedGenderFilter,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGold,
                side: const BorderSide(color: AppTheme.primaryGold),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('View All $categoryName'),
            ),
          ),
        ],
      ),
    );
  }

  void _showStyleTagsBottomSheet(String categoryName, List<String> styleTags) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shop $categoryName by Style',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: styleTags.map((tag) => ActionChip(
                label: Text(tag),
                backgroundColor: Colors.grey.shade100,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(
                        category: categoryName,
                        styleTag: tag,
                        gender: _selectedGenderFilter == 'all' ? null : _selectedGenderFilter,
                      ),
                    ),
                  );
                },
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeGrid(String categoryName) {
    // Use budget ranges from API with fallback
    final priceRanges = _budgetRanges.isNotEmpty
        ? _budgetRanges.map((range) => {
            'label': range['label'] ?? '',
            'min': (range['minPrice'] ?? 0).toInt(),
            'max': (range['maxPrice'] ?? 0).toInt(),
          }).toList()
        : [
            {'label': 'Under 10K', 'min': 0, 'max': 10000},
            {'label': '10K - 20K', 'min': 10000, 'max': 20000},
            {'label': '20K - 30K', 'min': 20000, 'max': 30000},
            {'label': '30K - 50K', 'min': 30000, 'max': 50000},
            {'label': '50K - 75K', 'min': 50000, 'max': 75000},
            {'label': '75K & Above', 'min': 75000, 'max': 10000000},
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: priceRanges.length,
      itemBuilder: (context, index) {
        final range = priceRanges[index];
        return OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListScreen(
                  category: categoryName,
                  minPrice: range['min'] as int,
                  maxPrice: range['max'] as int,
                  gender: _selectedGenderFilter,
                ),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          child: Text(
            range['label'] as String,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner() {
    if (_banners.isEmpty) {
      return Container(
        height: 400,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.only(right: 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: banner['image']!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Text content
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              banner['subtitle']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.textPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(banner['action']!.toUpperCase()),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Page indicators
          Positioned(
            right: 24,
            top: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentBannerIndex + 1} / ${_banners.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopByOccasion() {
    // Use backend data if available, otherwise show empty state
    final occasions = _occasions.isNotEmpty ? _occasions : [];

    if (occasions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Shop by Occasion',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: occasions.length,
          itemBuilder: (context, index) {
            final occasion = occasions[index];
            return GestureDetector(
              onTap: () {
                // Navigate using ProductNavigation helper
                final occasionModel = Occasion.fromJson(occasion);
                ProductNavigation.toOccasion(context, occasionModel);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      occasion['icon'] as String? ?? '',
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            occasion['name'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${occasion['itemCount'] ?? 0} items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShopByBudget() {
    // Use backend data if available, otherwise show empty state
    final budgets = _budgetRanges.isNotEmpty ? _budgetRanges : [];

    if (budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Shop by Budget',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            final isPopular = budget['isPopular'] as bool? ?? false;

            return GestureDetector(
              onTap: () {
                // Navigate using ProductNavigation helper
                final budgetRange = BudgetRange.fromJson(budget);
                ProductNavigation.toBudgetRange(context, budgetRange);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPopular ? AppTheme.primaryGold.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isPopular
                      ? Border.all(color: AppTheme.primaryGold.withOpacity(0.3))
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          budget['label'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPopular ? AppTheme.primaryGold : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${budget['itemCount'] ?? 0} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (isPopular)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Popular',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFlashDealsBanner() {
    // Use real flash sale data from backend if available
    if (_homepageData?.activeFlashSales.isNotEmpty == true) {
      final flashSale = _homepageData!.activeFlashSales.first;
      final endTime = flashSale.endTime;
      final now = DateTime.now();
      final timeLeft = endTime.difference(now);

      if (timeLeft.isNegative) {
        return const SizedBox.shrink(); // Hide if expired
      }

      final hours = timeLeft.inHours.toString().padLeft(2, '0');
      final minutes = (timeLeft.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (timeLeft.inSeconds % 60).toString().padLeft(2, '0');

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department, color: AppTheme.errorRed, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                flashSale.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ends in',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            _buildTimeBox(hours),
            const Text(' : ', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildTimeBox(minutes),
            const Text(' : ', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildTimeBox(seconds),
          ],
        ),
      );
    }

    // No flash sale available - return empty
    return const SizedBox.shrink();
  }

  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompleteYourLook() {
    // Use real bundle deals from backend if available
    if (_homepageData?.bundleDeals.isNotEmpty == true) {
      final bundle = _homepageData!.bundleDeals.first;
      final savings = bundle.originalPrice - bundle.bundlePrice;
      final discountPercent = ((savings / bundle.originalPrice) * 100).round();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Complete Your Look',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all bundles
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                // TODO: Navigate to bundle detail
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bundle.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Save ₹${savings.toStringAsFixed(0)} ($discountPercent% off)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Bundle Deal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bundle items preview (first 3 products)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        bundle.items.length > 3 ? 3 : bundle.items.length,
                        (index) => [
                          if (index > 0) const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.add, size: 20),
                          ),
                          _buildBundleItemPreview(),
                        ],
                      ).expand((e) => e).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No bundle deals available - return empty
    return const SizedBox.shrink();
  }

  Widget _buildBundleItemPreview() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCuratedCollections() {
    // Use backend data if available, otherwise show empty state
    final collections = _collections.isNotEmpty ? _collections : [];

    if (collections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Curated Collections',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Collection images grid (2x2)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: GridView.count(
                                crossAxisCount: 2,
                                physics: const NeverScrollableScrollPhysics(),
                                children: List.generate(4, (i) {
                                  final imageUrls = collection['imageUrls'] as List?;
                                  final imageUrl = (imageUrls != null && i < imageUrls.length)
                                      ? imageUrls[i] as String
                                      : null;

                                  if (imageUrl != null && imageUrl.isNotEmpty) {
                                    return CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
                                    );
                                  }
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  );
                                }),
                              ),
                            ),
                          ),
                          // Collection info
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  collection['title'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  collection['subtitle'] as String? ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'Explore Collection',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.primaryGold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: AppTheme.primaryGold,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Item count badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${collection['count']} items',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
      ],
    );
  }

  Widget _buildHandpickedForYou() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = productProvider.products.take(4).toList();

        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Handpicked For You',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Based on your preferences',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length > 4 ? 4 : products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: products[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          product: products[index],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrendingNow() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = productProvider.products.take(3).toList();

        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trending Now',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Most viewed this week',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length > 3 ? 3 : products.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    child: ProductCard(
                      product: products[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: products[index],
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
        );
      },
    );
  }

  Widget _buildRecentlyViewed() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = productProvider.products.take(3).toList();

        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recently Viewed',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pick up where you left off',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length > 3 ? 3 : products.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    child: ProductCard(
                      product: products[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: products[index],
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
        );
      },
    );
  }

  Widget _buildNewArrivals() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = productProvider.products.take(3).toList();

        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Arrivals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Fresh additions to our catalog',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length > 3 ? 3 : products.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    child: ProductCard(
                      product: products[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: products[index],
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
        );
      },
    );
  }
}
