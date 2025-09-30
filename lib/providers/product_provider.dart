import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../utils/mock_data.dart';
import '../utils/search_utils.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Product> _wishlist = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String? _selectedGender;
  String _sortBy = 'popularity';
  Map<String, dynamic> _filters = {};

  List<Product> get products => _filteredProducts.isEmpty ? _products : _filteredProducts;
  List<Product> get featuredProducts => _products.where((p) => p.isFeatured).toList();
  List<Product> get wishlist => _wishlist;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String? get selectedGender => _selectedGender;
  String get sortBy => _sortBy;

  ProductProvider() {
    loadProducts();
  }

  Future<void> loadProducts() async {
    _setLoading(true);

    try {
      // First try to load from backend API
      try {
        final response = await ApiService.getProducts();
        if (response['success'] == true && response['data'] != null) {
          final productsData = response['data']['products'] as List?;
          if (productsData != null) {
            _products = productsData.map<Product>((json) => Product.fromJson(json)).toList();
            
            // Cache products in SQLite for offline use
            await _cacheProductsLocally(_products);
            
            _filteredProducts = _products;
            notifyListeners();
            return;
          }
        }
      } catch (apiError) {
        debugPrint('API error, falling back to local data: $apiError');
      }

      // Fallback to local storage
      final List<Map<String, dynamic>> productMaps = await StorageService.getProducts();

      if (productMaps.isNotEmpty) {
        _products = productMaps.map<Product>((map) {
          return Product(
            id: map['id'].toString(),
            name: map['name'] as String,
            description: map['description'] as String,
            price: (map['price'] as num).toDouble(),
            originalPrice: map['price'] != null ? (map['price'] as num).toDouble() * 1.2 : null,
            category: map['category'] as String,
            subcategory: map['subcategory'] as String? ?? '',
            images: (map['images'] as String).split(','),
            metalType: map['metalType'] as String? ?? '',
            stoneType: map['stoneType'] as String? ?? '',
            weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
            tags: map['tags'] != null ? (map['tags'] as String).split(',') : [],
            rating: (map['rating'] as num).toDouble(),
            reviewCount: map['ratingCount'] as int,
            stockQuantity: map['stock'] as int,
            videoUrl: map['videoUrl'] as String?,
            isFeatured: (map['stock'] as int) > 3,
            isAvailable: (map['stock'] as int) > 0,
            createdAt: DateTime.parse(map['createdAt'] as String),
          );
        }).toList();
      } else {
        // Last resort: use mock data and save to database
        _products = MockData.products;
        await _cacheProductsLocally(_products);
      }

      _filteredProducts = _products;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading products: $e');
      // Final fallback to mock data
      _products = MockData.products;
      _filteredProducts = _products;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _cacheProductsLocally(List<Product> products) async {
    try {
      await StorageService.saveProducts(products);
    } catch (e) {
      debugPrint('Error caching products locally: $e');
    }
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
  }

  void filterByGender(String gender) {
    _selectedGender = gender;
    _applyFiltersAndSort();
  }

  void clearGenderFilter() {
    _selectedGender = null;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredProducts = _products.where((product) {
      // Category filter
      if (_selectedCategory != 'All' && product.category != _selectedCategory) {
        return false;
      }

      // Gender filter - this would require adding gender field to Product model
      // For now, we'll use tags to determine gender targeting
      if (_selectedGender != null) {
        final productTags = product.tags.map((tag) => tag.toLowerCase());
        final genderTag = _selectedGender!.toLowerCase();

        // Check if product has gender-specific tags
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

      return true;
    }).toList();

    _applySorting();
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _filteredProducts = _products;
      notifyListeners();
      return;
    }

    _setLoading(true);

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
      _filteredProducts = _products;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> enhancedSearch(String query) async {
    if (query.isEmpty) {
      _filteredProducts = _products;
      notifyListeners();
      return;
    }

    _setLoading(true);

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
    _filteredProducts = _products;
    notifyListeners();
  }

  void applyFilters(Map<String, dynamic> filters) {
    _filters = filters;
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

  void toggleWishlist(Product product) {
    if (_wishlist.any((p) => p.id == product.id)) {
      _wishlist.removeWhere((p) => p.id == product.id);
    } else {
      _wishlist.add(product);
    }
    notifyListeners();
  }

  bool isInWishlist(String productId) {
    return _wishlist.any((p) => p.id == productId);
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
    _selectedGender = null;
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
      debugPrint('Error loading categories from API: $e');
    }
    
    // Fallback to mock categories
    return MockData.categories;
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