import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(0, 100000);
  final Set<String> _selectedMetalTypes = {};
  final Set<String> _selectedStoneTypes = {};
  final Set<String> _selectedGenders = {};
  final Set<String> _selectedCategories = {};
  bool _inStockOnly = false;

  final List<String> _metalTypes = [
    '18K White Gold',
    '18K Yellow Gold',
    '14K Rose Gold',
    '14K White Gold',
    '22K Yellow Gold',
    'Platinum',
    'Silver',
  ];

  final List<String> _stoneTypes = [
    'Diamond',
    'Lab Diamond',
    'Emerald',
    'Ruby',
    'Pearl',
    'Sapphire',
  ];

  final List<String> _genders = [
    'Male',
    'Female',
    'Unisex',
  ];

  final List<String> _categories = [
    'Rings',
    'Necklaces',
    'Earrings',
    'Bracelets',
    'Pendants',
    'Bangles',
    'Chains',
    'Watches',
    'Cufflinks',
    'Brooches',
  ];

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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _priceRange = const RangeValues(0, 100000);
                      _selectedMetalTypes.clear();
                      _selectedStoneTypes.clear();
                      _selectedGenders.clear();
                      _selectedCategories.clear();
                      _inStockOnly = false;
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Filter Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range
                  Text(
                    'Price Range',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 100000,
                    divisions: 20,
                    activeColor: AppTheme.primaryGold,
                    labels: RangeLabels(
                      '₹${_priceRange.start.round()}',
                      '₹${_priceRange.end.round()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${_priceRange.start.round()}'),
                      Text('₹${_priceRange.end.round()}'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Gender Filter
                  Text(
                    'Gender',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _genders.map((gender) {
                      final isSelected = _selectedGenders.contains(gender);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  gender == 'Male'
                                      ? Icons.man
                                      : gender == 'Female'
                                          ? Icons.woman
                                          : Icons.people,
                                  size: 16,
                                  color: isSelected ? Colors.white : AppTheme.primaryGold,
                                ),
                                const SizedBox(width: 4),
                                Flexible(child: Text(gender)),
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
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Category Filter
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        selectedColor: AppTheme.primaryGold.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryGold,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Metal Type
                  Text(
                    'Metal Type',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _metalTypes.map((metal) {
                      final isSelected = _selectedMetalTypes.contains(metal);
                      return FilterChip(
                        label: Text(metal),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedMetalTypes.add(metal);
                            } else {
                              _selectedMetalTypes.remove(metal);
                            }
                          });
                        },
                        selectedColor: AppTheme.primaryGold.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryGold,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Stone Type
                  Text(
                    'Stone Type',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _stoneTypes.map((stone) {
                      final isSelected = _selectedStoneTypes.contains(stone);
                      return FilterChip(
                        label: Text(stone),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStoneTypes.add(stone);
                            } else {
                              _selectedStoneTypes.remove(stone);
                            }
                          });
                        },
                        selectedColor: AppTheme.secondaryRoseGold.withOpacity(0.2),
                        checkmarkColor: AppTheme.secondaryRoseGold,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Availability
                  Card(
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
                      onChanged: (value) {
                        setState(() {
                          _inStockOnly = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final filters = {
                        'minPrice': _priceRange.start,
                        'maxPrice': _priceRange.end,
                        'gender': _selectedGenders.toList(),
                        'category': _selectedCategories.toList(),
                        'metalType': _selectedMetalTypes.toList(),
                        'stoneType': _selectedStoneTypes.toList(),
                        'inStock': _inStockOnly,
                      };
                      Provider.of<ProductProvider>(context, listen: false)
                          .applyFilters(filters);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}