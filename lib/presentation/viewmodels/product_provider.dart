import 'package:flutter/foundation.dart';
import '../../data/models/product.dart';
import '../../utils/search_utils.dart';
import '../../data/services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String? _selectedGender;
  String _sortBy = 'popularity';
  Map<String, dynamic> _filters = {};
  double? _minPrice;
  double? _maxPrice;
  bool _isFilterActive = false;  // Track if any filter is applied

  // Return filtered products when filter is active, even if empty (shows "no results")
  List<Product> get products => _isFilterActive ? _filteredProducts : _products;
  // Always return all products (unfiltered) - useful for local filtering in widgets
  List<Product> get allProducts => _products;
  List<Product> get featuredProducts => _products.where((p) => p.isFeatured).toList();
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String? get selectedGender => _selectedGender;
  String get sortBy => _sortBy;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  ProductProvider() {
    loadProducts();
  }

  Future<void> loadProducts() async {
    _setLoading(true);

    try {
      final response = await ApiService.getProducts();
      if (response['success'] == true && response['data'] != null) {
        final productsData = response['data']['products'] as List?;
        if (productsData != null) {
          _products = productsData.map<Product>((json) => Product.fromJson(json)).toList();
          _filteredProducts = _products;
          notifyListeners();
          return;
        }
      }
      
      // API failed - show empty state (no mock data)
      debugPrint('⚠️ API failed to load products');
      _products = [];
      _filteredProducts = [];
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      // Show empty state on error (no mock data)
      _products = [];
      _filteredProducts = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }


  void filterByCategory(String category) {
    debugPrint('📂 filterByCategory: "$category"');
    debugPrint('📂 Total products available: ${_products.length}');

    _selectedCategory = category;
    _selectedTag = null;  // Clear tag filter when switching categories
    _isFilterActive = category != 'All';
    _applyFiltersAndSort();

    debugPrint('📂 Filtered products count: ${_filteredProducts.length}');
    if (_filteredProducts.isEmpty && _products.isNotEmpty) {
      // Debug: show what categories exist in products
      final existingCategories = _products.map((p) => p.category).toSet();
      debugPrint('📂 Available categories in products: $existingCategories');
    }
  }

  void filterByGender(String gender) {
    debugPrint('👤 filterByGender: "$gender"');
    _selectedGender = gender;
    _applyFiltersAndSort();
    debugPrint('👤 Filtered products count: ${_filteredProducts.length}');
  }

  void clearGenderFilter() {
    _selectedGender = null;
    _applyFiltersAndSort();
  }

  void filterByPriceRange({double? minPrice, double? maxPrice}) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _isFilterActive = minPrice != null || maxPrice != null;

    debugPrint('💰 filterByPriceRange: min=$minPrice, max=$maxPrice');
    debugPrint('💰 Total products before filter: ${_products.length}');

    _applyFiltersAndSort();

    debugPrint('💰 Filtered products count: ${_filteredProducts.length}');
  }

  void clearPriceFilter() {
    _minPrice = null;
    _maxPrice = null;
    _applyFiltersAndSort();
  }

  String? _selectedTag;
  String? get selectedTag => _selectedTag;

  String? _selectedSubcategory;
  String? get selectedSubcategory => _selectedSubcategory;

  /// Filter products by a tag (e.g., style tags like 'traditional', 'contemporary')
  void filterByTag(String tag) {
    _selectedTag = tag.toLowerCase();
    _selectedCategory = 'All';  // Clear category filter when filtering by tag
    _isFilterActive = true;  // Mark filter as active

    debugPrint('🏷️ filterByTag called with: $tag');
    debugPrint('🏷️ Total products: ${_products.length}');

    // Debug: Print all product tags to see what's available
    for (var product in _products.take(5)) {
      debugPrint('🏷️ Product "${product.name}" tags: ${product.tags}');
    }

    _filteredProducts = _products.where((product) {
      // Check if product has the tag
      final hasTag = product.tags.any((t) => t.toLowerCase() == _selectedTag);
      return hasTag;
    }).toList();

    debugPrint('🏷️ Filtered products count: ${_filteredProducts.length}');

    // Apply other active filters
    if (_selectedGender != null) {
      _filteredProducts = _filteredProducts.where((product) {
        final productGenders = product.gender.map((g) => g.toLowerCase()).toList();
        final genderFilter = _selectedGender!.toLowerCase();

        // Check product's gender field
        if (productGenders.isNotEmpty) {
          return productGenders.contains(genderFilter) ||
                 productGenders.contains('unisex');
        }
        return true; // If no gender specified, include product
      }).toList();
    }

    if (_minPrice != null || _maxPrice != null) {
      _filteredProducts = _filteredProducts.where((product) {
        if (_minPrice != null && product.price < _minPrice!) return false;
        if (_maxPrice != null && product.price > _maxPrice!) return false;
        return true;
      }).toList();
    }

    _applySorting();
    notifyListeners();
  }

  void clearTagFilter() {
    _selectedTag = null;
    // Check if any other filters are still active
    _isFilterActive = _selectedCategory != 'All' ||
                      _selectedSubcategory != null ||
                      _selectedGender != null ||
                      _minPrice != null ||
                      _maxPrice != null;
    _applyFiltersAndSort();
  }

  /// Filter products by subcategory (e.g., 'Stud Earrings', 'Hoop Earrings')
  void filterBySubcategory(String subcategory) {
    _selectedSubcategory = subcategory.toLowerCase();
    _isFilterActive = true;

    debugPrint('📦 filterBySubcategory: "$subcategory"');
    _applyFiltersAndSort();
    debugPrint('📦 Filtered products count: ${_filteredProducts.length}');
  }

  void clearSubcategoryFilter() {
    _selectedSubcategory = null;
    // Check if any other filters are still active
    _isFilterActive = _selectedCategory != 'All' ||
                      _selectedTag != null ||
                      _selectedGender != null ||
                      _minPrice != null ||
                      _maxPrice != null;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    // Update _isFilterActive based on current filter state
    _isFilterActive = _selectedCategory != 'All' ||
                      _selectedSubcategory != null ||
                      _selectedGender != null ||
                      _selectedTag != null ||
                      _minPrice != null ||
                      _maxPrice != null;

    _filteredProducts = _products.where((product) {
      // Category filter (case-insensitive comparison)
      if (_selectedCategory != 'All' &&
          product.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

      // Subcategory filter (case-insensitive comparison)
      if (_selectedSubcategory != null &&
          product.subcategory.toLowerCase() != _selectedSubcategory!.toLowerCase()) {
        return false;
      }

      // Gender filter - check product's gender field and tags
      if (_selectedGender != null && _selectedGender!.toLowerCase() != 'all') {
        final genderFilter = _selectedGender!.toLowerCase();

        // First check product's gender field if it exists
        if (product.gender.isNotEmpty) {
          final productGenders = product.gender.map((g) => g.toLowerCase()).toList();
          // Include product if it matches the filter or is unisex/all
          final matchesGender = productGenders.contains(genderFilter) ||
                                productGenders.contains('all') ||
                                productGenders.contains('unisex');
          if (!matchesGender) {
            // Also check for common variations
            final isWomen = genderFilter == 'women' || genderFilter == 'female' || genderFilter == 'woman';
            final isMen = genderFilter == 'men' || genderFilter == 'male' || genderFilter == 'man';

            if (isWomen && !productGenders.any((g) =>
                g == 'women' || g == 'female' || g == 'woman' || g == 'all' || g == 'unisex')) {
              return false;
            }
            if (isMen && !productGenders.any((g) =>
                g == 'men' || g == 'male' || g == 'man' || g == 'all' || g == 'unisex')) {
              return false;
            }
          }
        }
        // If product has no gender field, include it (don't filter out)
      }

      // Price range filter
      if (_minPrice != null && product.price < _minPrice!) {
        return false;
      }
      if (_maxPrice != null && product.price > _maxPrice!) {
        return false;
      }

      return true;
    }).toList();

    _applySorting();
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _isFilterActive = false;
      _filteredProducts = _products;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _isFilterActive = true;  // Mark filter active for search

    try {
      // Try backend search first
      try {
        final response = await ApiService.searchProducts(query: query);
        if (response['success'] == true && response['data'] != null) {
          final searchResults = (response['data'] as List)
              .map<Product>((json) => Product.fromJson(json))
              .toList();
          _filteredProducts = searchResults;
          notifyListeners();
          return;
        }
      } catch (apiError) {
        debugPrint('API search error, falling back to local search: $apiError');
      }

      // Fallback to local search
      _filteredProducts = _products.where((p) {
        return p.name.toLowerCase().contains(query.toLowerCase()) ||
               p.description.toLowerCase().contains(query.toLowerCase()) ||
               p.category.toLowerCase().contains(query.toLowerCase()) ||
               p.metalType.toLowerCase().contains(query.toLowerCase()) ||
               (p.stoneType?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
               p.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Search error: $e');
      // On error, show all products
      _isFilterActive = false;
      _filteredProducts = _products;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> enhancedSearch(String query) async {
    if (query.isEmpty) {
      _isFilterActive = false;
      _filteredProducts = _products;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _isFilterActive = true;  // Mark filter active for search

    try {
      // Try backend search first
      try {
        final response = await ApiService.searchProducts(query: query);
        if (response['success'] == true && response['data'] != null) {
          final searchResults = (response['data'] as List)
              .map<Product>((json) => Product.fromJson(json))
              .toList();
          _filteredProducts = searchResults;
          notifyListeners();
          return;
        }
      } catch (apiError) {
        debugPrint('API enhanced search error, falling back to local search: $apiError');
      }

      // Fallback to local enhanced search with scoring
      final queryLower = query.toLowerCase();
      final List<MapEntry<Product, double>> scoredProducts = [];

    for (Product product in _products) {
      double score = 0.0;

      // Exact name match gets highest score
      if (product.name.toLowerCase() == queryLower) {
        score = 100.0;
      }
      // Name starts with query gets high score
      else if (product.name.toLowerCase().startsWith(queryLower)) {
        score = 90.0;
      }
      // Name contains query gets good score
      else if (product.name.toLowerCase().contains(queryLower)) {
        score = 80.0;
      }
      // Check category and subcategory
      else if (product.category.toLowerCase().contains(queryLower) ||
               product.subcategory.toLowerCase().contains(queryLower)) {
        score = 70.0;
      }
      // Check metal type and stone type
      else if (product.metalType.toLowerCase().contains(queryLower) ||
               (product.stoneType?.toLowerCase().contains(queryLower) ?? false)) {
        score = 60.0;
      }
      // Check tags
      else if (product.tags.any((tag) => tag.toLowerCase().contains(queryLower))) {
        score = 50.0;
      }
      // Check description
      else if (product.description.toLowerCase().contains(queryLower)) {
        score = 40.0;
      }
      // Fuzzy matching for name
      else if (SearchUtils.isSimilar(query, product.name, threshold: 0.6)) {
        score = 30.0;
      }
      // Fuzzy matching for category
      else if (SearchUtils.isSimilar(query, product.category, threshold: 0.7)) {
        score = 25.0;
      }
      // Fuzzy matching for metal type
      else if (SearchUtils.isSimilar(query, product.metalType, threshold: 0.7)) {
        score = 20.0;
      }
      // Fuzzy matching for stone type
      else if (product.stoneType != null &&
               SearchUtils.isSimilar(query, product.stoneType!, threshold: 0.7)) {
        score = 20.0;
      }

      // Boost score for featured products
      if (score > 0 && product.isFeatured) {
        score += 5.0;
      }

      // Boost score for available products
      if (score > 0 && product.isAvailable) {
        score += 2.0;
      }

      if (score > 0) {
        scoredProducts.add(MapEntry(product, score));
      }
    }

      // Sort by score descending
      scoredProducts.sort((a, b) => b.value.compareTo(a.value));

      _filteredProducts = scoredProducts.map((entry) => entry.key).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Enhanced search error: $e');
      // On error, show all products
      _filteredProducts = _products;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void clearSearch() {
    _isFilterActive = false;
    _filteredProducts = _products;
    notifyListeners();
  }

  void applyFilters(Map<String, dynamic> filters) {
    _filters = filters;
    _isFilterActive = filters.isNotEmpty;  // Mark filter active when filters are applied
    _filteredProducts = _products.where((product) {
      // Category filter (from quick filters or advanced filters)
      if (_selectedCategory != 'All' && product.category != _selectedCategory) {
        return false;
      }

      // Advanced category filter from filter sheet
      if (filters['category'] != null &&
          filters['category'].isNotEmpty &&
          !filters['category'].contains(product.category)) {
        return false;
      }

      // Gender filter
      if (filters['gender'] != null && filters['gender'].isNotEmpty) {
        final productTags = product.tags.map((tag) => tag.toLowerCase());
        bool matchesGender = false;

        for (String gender in filters['gender']) {
          final genderTag = gender.toLowerCase();
          if (genderTag == 'male' && productTags.any((tag) =>
              tag.contains('men') || tag.contains('male') || tag.contains('groom'))) {
            matchesGender = true;
            break;
          }
          if (genderTag == 'female' && productTags.any((tag) =>
              tag.contains('women') || tag.contains('female') || tag.contains('bride'))) {
            matchesGender = true;
            break;
          }
          if (genderTag == 'unisex' && productTags.any((tag) =>
              tag.contains('unisex') || tag.contains('neutral'))) {
            matchesGender = true;
            break;
          }
        }

        if (!matchesGender) return false;
      }

      // Current gender filter from quick selection
      if (_selectedGender != null) {
        final productTags = product.tags.map((tag) => tag.toLowerCase());
        final genderTag = _selectedGender!.toLowerCase();

        if (genderTag == 'male' && !productTags.any((tag) =>
            tag.contains('men') || tag.contains('male') || tag.contains('groom'))) {
          return false;
        }
        if (genderTag == 'female' && !productTags.any((tag) =>
            tag.contains('women') || tag.contains('female') || tag.contains('bride'))) {
          return false;
        }
        if (genderTag == 'unisex' && !productTags.any((tag) =>
            tag.contains('unisex') || tag.contains('neutral'))) {
          return false;
        }
      }

      // Price range filter
      if (filters['minPrice'] != null && product.price < filters['minPrice']) {
        return false;
      }
      if (filters['maxPrice'] != null && product.price > filters['maxPrice']) {
        return false;
      }

      // Metal type filter
      if (filters['metalType'] != null &&
          filters['metalType'].isNotEmpty &&
          !filters['metalType'].contains(product.metalType)) {
        return false;
      }

      // Stone type filter
      if (filters['stoneType'] != null &&
          filters['stoneType'].isNotEmpty &&
          product.stoneType != null &&
          !filters['stoneType'].contains(product.stoneType)) {
        return false;
      }

      // Availability filter
      if (filters['inStock'] == true && !product.isAvailable) {
        return false;
      }

      return true;
    }).toList();

    _applySorting();
    notifyListeners();
  }

  void sortProducts(String sortBy) {
    _sortBy = sortBy;
    _applySorting();
    notifyListeners();
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'price_low':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        _filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
        _filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'name_asc':
        _filteredProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        _filteredProducts.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'discount':
        _filteredProducts.sort((a, b) {
          final discountA = a.originalPrice != null ?
              ((a.originalPrice! - a.price) / a.originalPrice! * 100) : 0.0;
          final discountB = b.originalPrice != null ?
              ((b.originalPrice! - b.price) / b.originalPrice! * 100) : 0.0;
          return discountB.compareTo(discountA);
        });
        break;
      case 'popularity':
      default:
        _filteredProducts.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }
  }



  List<Product> getRelatedProducts(Product product) {
    return _products
        .where((p) =>
            p.id != product.id &&
            (p.category == product.category || p.subcategory == product.subcategory))
        .take(6)
        .toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearFilters() {
    _filters = {};
    _selectedCategory = 'All';
    _selectedSubcategory = null;
    _selectedGender = null;
    _selectedTag = null;
    _minPrice = null;
    _maxPrice = null;
    _isFilterActive = false;  // Reset filter active flag
    _filteredProducts = _products;
    _applySorting();
    notifyListeners();
  }

  Future<List<Product>> loadFeaturedProducts() async {
    try {
      final response = await ApiService.getFeaturedProducts();
      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List)
            .map<Product>((json) => Product.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading featured products from API: $e');
    }
    
    // Fallback to local featured products
    return featuredProducts;
  }

  Future<List<String>> loadCategories() async {
    try {
      final response = await ApiService.getCategories();
      if (response['success'] == true && response['data'] != null) {
        final categories = (response['data'] as List)
            .map<String>((item) => item['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        return ['All', ...categories];
      }
    } catch (e) {
      debugPrint('❌ Error loading categories from API: $e');
    }

    // Return empty list if API fails (no mock data)
    return [];
  }

  Future<Product?> getProductById(String id) async {
    // First check local products
    try {
      final localProduct = _products.firstWhere((p) => p.id == id);
      return localProduct;
    } catch (e) {
      // Not found locally, try API
      try {
        final response = await ApiService.getProduct(productId: id);
        if (response['success'] == true && response['data'] != null) {
          return Product.fromJson(response['data']);
        }
      } catch (apiError) {
        debugPrint('Error loading product from API: $apiError');
      }
    }
    
    return null;
  }
}