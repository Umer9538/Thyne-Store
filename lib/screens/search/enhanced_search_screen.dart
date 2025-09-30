import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../utils/search_utils.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';

class EnhancedSearchScreen extends StatefulWidget {
  const EnhancedSearchScreen({super.key});

  @override
  State<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends State<EnhancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _suggestions = [];
  List<String> _recentSearches = [];
  List<String> _searchTerms = [];
  bool _showSuggestions = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus;
    });
  }

  void _loadRecentSearches() {
    // In a real app, this would load from SharedPreferences
    _recentSearches = [
      'Diamond rings',
      'Gold necklace',
      'Pearl earrings',
      'Silver bracelet',
    ];
  }

  void _generateSearchTerms(List<dynamic> products) {
    _searchTerms = SearchUtils.generateSearchTerms(products);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentQuery = query;
      if (query.isEmpty) {
        _suggestions = [];
      } else {
        // Combine search terms with common jewelry terms
        final allTerms = [..._searchTerms, ...SearchUtils.commonJewelryTerms];
        _suggestions = SearchUtils.getSearchSuggestions(
          query,
          allTerms,
          maxSuggestions: 8,
          fuzzyThreshold: 0.5,
        );
      }
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    // Add to recent searches
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }
      _showSuggestions = false;
    });

    // Unfocus search field
    _searchFocusNode.unfocus();

    // Perform search with fuzzy matching
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.enhancedSearch(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _suggestions = [];
    });
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search jewelry, diamonds, gold...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _currentQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : const Icon(Icons.mic),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _performSearch,
            ),
          ),

          // Search Suggestions or Results
          Expanded(
            child: _showSuggestions ? _buildSuggestions() : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Generate search terms if not already done
        if (_searchTerms.isEmpty && productProvider.products.isNotEmpty) {
          _generateSearchTerms(productProvider.products);
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Searches
              if (_currentQuery.isEmpty && _recentSearches.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...(_recentSearches.take(5)).map((search) => ListTile(
                      leading: const Icon(Icons.history, color: Colors.grey),
                      title: Text(search),
                      trailing: IconButton(
                        icon: const Icon(Icons.north_west, size: 16),
                        onPressed: () {
                          _searchController.text = search;
                          _onSearchChanged(search);
                        },
                      ),
                      onTap: () => _performSearch(search),
                    )).toList(),
              ],

              // Popular Searches
              if (_currentQuery.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Popular Searches',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SearchUtils.commonJewelryTerms.take(10).map((term) {
                      return ActionChip(
                        label: Text(term),
                        onPressed: () => _performSearch(term),
                        backgroundColor: AppTheme.primaryGold.withOpacity(0.1),
                        labelStyle: const TextStyle(color: AppTheme.primaryGold),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Search Suggestions
              if (_suggestions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Suggestions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ..._suggestions.map((suggestion) => ListTile(
                      leading: const Icon(Icons.search, color: AppTheme.primaryGold),
                      title: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: _highlightQuery(suggestion, _currentQuery),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.north_west, size: 16),
                        onPressed: () {
                          _searchController.text = suggestion;
                          _onSearchChanged(suggestion);
                        },
                      ),
                      onTap: () => _performSearch(suggestion),
                    )).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (_currentQuery.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Start searching for jewelry',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final products = productProvider.products;

        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Try different keywords or check spelling',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Search Results Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Text(
                    '${products.length} results for "$_currentQuery"',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () {
                      // Show filter bottom sheet
                    },
                  ),
                ],
              ),
            ),

            // Results Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    showDiscount: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: product,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<TextSpan> _highlightQuery(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final int index = textLower.indexOf(queryLower);

    if (index == -1) {
      return [TextSpan(text: text)];
    }

    return [
      if (index > 0) TextSpan(text: text.substring(0, index)),
      TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGold,
        ),
      ),
      if (index + query.length < text.length)
        TextSpan(text: text.substring(index + query.length)),
    ];
  }
}