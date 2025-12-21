import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/filter_params.dart';
import '../../config/filter_config.dart';
import '../../utils/theme.dart';

/// Refactored FilterBottomSheet using generic models
/// Easy to extend with new filter types from backend
class FilterBottomSheet extends StatefulWidget {
  /// Optional initial filter params
  final FilterParams? initialParams;

  /// Optional filter configuration (can be loaded from backend)
  final FilterConfig? config;

  const FilterBottomSheet({
    super.key,
    this.initialParams,
    this.config,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterConfig _config;
  late RangeValues _priceRange;
  final Set<GenderType> _selectedGenders = {};
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedMetalTypes = {};
  final Set<String> _selectedStoneTypes = {};
  bool _inStockOnly = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? FilterConfig.defaultConfig;
    _priceRange = RangeValues(_config.minPriceLimit, _config.maxPriceLimit);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeFromProvider();
      _initialized = true;
    }
  }

  void _initializeFromProvider() {
    final provider = Provider.of<ProductProvider>(context, listen: false);

    // Initialize from widget params first, then fall back to provider
    if (widget.initialParams != null) {
      _initializeFromParams(widget.initialParams!);
      return;
    }

    // Pre-select gender from provider using GenderType
    if (provider.selectedGender != null) {
      final gender = GenderType.fromString(provider.selectedGender);
      if (!gender.isAll) {
        _selectedGenders.add(gender);
      }
    }

    // Pre-select category from provider
    if (provider.selectedCategory != 'All') {
      final providerCategory = provider.selectedCategory.toLowerCase();
      for (var cat in _config.categories) {
        if (cat.displayName.toLowerCase() == providerCategory) {
          _selectedCategories.add(cat.displayName);
          break;
        }
      }
    }

    // Pre-select price range from provider
    if (provider.minPrice != null || provider.maxPrice != null) {
      _priceRange = RangeValues(
        provider.minPrice ?? _config.minPriceLimit,
        provider.maxPrice ?? _config.maxPriceLimit,
      );
    }
  }

  void _initializeFromParams(FilterParams params) {
    if (!params.gender.isAll) {
      _selectedGenders.add(params.gender);
    }

    if (params.category != null) {
      _selectedCategories.add(params.category!);
    }

    if (params.minPrice != null || params.maxPrice != null) {
      _priceRange = RangeValues(
        params.minPrice ?? _config.minPriceLimit,
        params.maxPrice ?? _config.maxPriceLimit,
      );
    }

    _selectedMetalTypes.addAll(params.metalTypes);
    _selectedStoneTypes.addAll(params.stoneTypes);
    _inStockOnly = params.inStockOnly;
  }

  void _clearAll() {
    setState(() {
      _priceRange = RangeValues(_config.minPriceLimit, _config.maxPriceLimit);
      _selectedGenders.clear();
      _selectedCategories.clear();
      _selectedMetalTypes.clear();
      _selectedStoneTypes.clear();
      _inStockOnly = false;
    });
  }

  void _applyFilters() {
    final filters = {
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
      'gender': _selectedGenders.map((g) => g.value).toList(),
      'category': _selectedCategories.toList(),
      'metalType': _selectedMetalTypes.toList(),
      'stoneType': _selectedStoneTypes.toList(),
      'inStock': _inStockOnly,
    };
    Provider.of<ProductProvider>(context, listen: false).applyFilters(filters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRangeSection(),
                  const SizedBox(height: 24),
                  _buildGenderSection(),
                  const SizedBox(height: 24),
                  _buildCategorySection(),
                  const SizedBox(height: 24),
                  _buildMetalTypeSection(),
                  const SizedBox(height: 24),
                  _buildStoneTypeSection(),
                  const SizedBox(height: 24),
                  _buildAvailabilitySection(),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          TextButton(
            onPressed: _clearAll,
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Price Range'),
        const SizedBox(height: 16),
        RangeSlider(
          values: _priceRange,
          min: _config.minPriceLimit,
          max: _config.maxPriceLimit,
          divisions: _config.priceDivisions,
          activeColor: AppTheme.primaryGold,
          labels: RangeLabels(
            '₹${_priceRange.start.round()}',
            '₹${_priceRange.end.round()}',
          ),
          onChanged: (values) => setState(() => _priceRange = values),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₹${_priceRange.start.round()}'),
            Text('₹${_priceRange.end.round()}'),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Gender'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _config.genders.map((gender) {
            final isSelected = _selectedGenders.contains(gender);
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (gender.icon != null) ...[
                    Icon(
                      gender.icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppTheme.primaryGold,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(gender.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedGenders.add(gender);
                  } else {
                    _selectedGenders.remove(gender);
                  }
                });
              },
              selectedColor: AppTheme.primaryGold,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Category'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _config.categories.map((category) {
            final isSelected = _selectedCategories.contains(category.displayName);
            return FilterChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category.displayName);
                  } else {
                    _selectedCategories.remove(category.displayName);
                  }
                });
              },
              selectedColor: AppTheme.primaryGold.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryGold,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetalTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Metal Type'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _config.metalTypes.map((metal) {
            final isSelected = _selectedMetalTypes.contains(metal.displayName);
            return FilterChip(
              label: Text(metal.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedMetalTypes.add(metal.displayName);
                  } else {
                    _selectedMetalTypes.remove(metal.displayName);
                  }
                });
              },
              selectedColor: AppTheme.primaryGold.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryGold,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStoneTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Stone Type'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _config.stoneTypes.map((stone) {
            final isSelected = _selectedStoneTypes.contains(stone.displayName);
            return FilterChip(
              label: Text(stone.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedStoneTypes.add(stone.displayName);
                  } else {
                    _selectedStoneTypes.remove(stone.displayName);
                  }
                });
              },
              selectedColor: AppTheme.secondaryRoseGold.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.secondaryRoseGold,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: const Text('In Stock Only'),
        subtitle: const Text('Show only available products'),
        value: _inStockOnly,
        activeColor: AppTheme.primaryGold,
        onChanged: (value) => setState(() => _inStockOnly = value),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
