import 'package:flutter/material.dart';
import '../../../utils/theme.dart';
import '../../../services/api_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterCategories();
    });
  }

  void _filterCategories() {
    if (_searchQuery.isEmpty) {
      _filteredCategories = List.from(_categories);
    } else {
      _filteredCategories = _categories.where((category) {
        return category.name.toLowerCase().contains(_searchQuery) ||
            category.description.toLowerCase().contains(_searchQuery) ||
            category.subcategories.any((sub) => sub.toLowerCase().contains(_searchQuery));
      }).toList();
    }
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService.getAllCategories();
      final categoriesData = response['data'] as List;
      print('📂 Loaded ${categoriesData.length} categories from API');
      setState(() {
        _categories = categoriesData.map((data) {
          final subcats = List<String>.from(data['subcategories'] ?? []);
          print('📂 Category: ${data['name']}, Subcategories: $subcats');
          return Category(
            id: data['id'],
            name: data['name'],
            description: data['description'] ?? '',
            subcategories: subcats,
          );
        }).toList();
        _filterCategories();
        _isLoading = false;
      });
    } catch (e) {
      print('📂 Error loading categories: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading categories: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No categories yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _showAddCategoryDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Category'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGold,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredCategories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                                Text(
                                  'Try a different search term',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade500,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCategories,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = _filteredCategories[index];
                                final originalIndex = _categories.indexOf(category);
                                return _buildCategoryCard(category, originalIndex);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(category.name),
            color: AppTheme.primaryGold,
          ),
        ),
        title: Text(
          category.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          category.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryGold),
              onPressed: () => _showEditCategoryDialog(category, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorRed),
              onPressed: () => _showDeleteDialog(category, index),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subcategories',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddSubcategoryDialog(category, index),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (category.subcategories.isEmpty)
                  const Text(
                    'No subcategories added yet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: category.subcategories.map((subcategory) {
                      return Chip(
                        label: Text(subcategory),
                        backgroundColor: AppTheme.primaryGold.withOpacity(0.1),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () async {
                          try {
                            final newSubcategories = category.subcategories.where((s) => s != subcategory).toList();
                            await ApiService.updateCategory(
                              categoryId: category.id,
                              name: category.name,
                              description: category.description,
                              subcategories: newSubcategories,
                            );
                            _loadCategories();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: AppTheme.errorRed,
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'rings':
        return Icons.circle_outlined;
      case 'necklaces':
        return Icons.timeline;
      case 'earrings':
        return Icons.hearing;
      case 'bracelets':
        return Icons.watch;
      default:
        return Icons.category;
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final subcategoryController = TextEditingController();
    List<String> subcategories = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Subcategories',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subcategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Add Subcategory',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        if (subcategoryController.text.trim().isNotEmpty) {
                          setDialogState(() {
                            subcategories.add(subcategoryController.text.trim());
                            subcategoryController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle, color: AppTheme.primaryGold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (subcategories.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subcategories.map((sub) => Chip(
                      label: Text(sub),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setDialogState(() {
                          subcategories.remove(sub);
                        });
                      },
                      backgroundColor: AppTheme.primaryGold.withOpacity(0.1),
                    )).toList(),
                  )
                else
                  Text(
                    'No subcategories added',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    await ApiService.createCategory(
                      name: nameController.text,
                      description: descriptionController.text,
                      subcategories: subcategories,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category added successfully'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                    // Refresh categories
                    _loadCategories();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Category category, int index) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    final subcategoryController = TextEditingController();
    List<String> subcategories = List.from(category.subcategories);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Subcategories',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subcategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Add Subcategory',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        if (subcategoryController.text.trim().isNotEmpty) {
                          setDialogState(() {
                            subcategories.add(subcategoryController.text.trim());
                            subcategoryController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle, color: AppTheme.primaryGold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (subcategories.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subcategories.map((sub) => Chip(
                      label: Text(sub),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setDialogState(() {
                          subcategories.remove(sub);
                        });
                      },
                      backgroundColor: AppTheme.primaryGold.withOpacity(0.1),
                    )).toList(),
                  )
                else
                  Text(
                    'No subcategories added',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    await ApiService.updateCategory(
                      categoryId: category.id,
                      name: nameController.text,
                      description: descriptionController.text,
                      subcategories: subcategories,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category updated successfully'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                    _loadCategories();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubcategoryDialog(Category category, int index) {
    final subcategoryController = TextEditingController();
    print('📂 Opening add subcategory dialog for ${category.name}');
    print('📂 Current subcategories: ${category.subcategories}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Subcategory to ${category.name}'),
        content: TextField(
          controller: subcategoryController,
          decoration: const InputDecoration(
            labelText: 'Subcategory Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (subcategoryController.text.isNotEmpty) {
                try {
                  // Get the latest category from the list to ensure we have updated subcategories
                  final latestCategory = _categories.firstWhere((c) => c.id == category.id);
                  final newSubcategories = [...latestCategory.subcategories, subcategoryController.text];
                  print('📂 Adding subcategory: ${subcategoryController.text}');
                  print('📂 New subcategories list: $newSubcategories');
                  await ApiService.updateCategory(
                    categoryId: latestCategory.id,
                    name: latestCategory.name,
                    description: latestCategory.description,
                    subcategories: newSubcategories,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subcategory added successfully'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                  _loadCategories();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Category category, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteCategory(categoryId: category.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${category.name} deleted successfully'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
                _loadCategories();
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class Category {
  final String id;
  final String name;
  final String description;
  final List<String> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.subcategories,
  });
}