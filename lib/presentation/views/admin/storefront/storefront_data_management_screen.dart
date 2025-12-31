import 'package:flutter/material.dart';
import '../../../../data/services/api_service.dart';
import '../../../../utils/theme.dart';

class StorefrontDataManagementScreen extends StatefulWidget {
  const StorefrontDataManagementScreen({super.key});

  @override
  State<StorefrontDataManagementScreen> createState() => _StorefrontDataManagementScreenState();
}

class _StorefrontDataManagementScreenState extends State<StorefrontDataManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storefront Data Management'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Occasions'),
            Tab(text: 'Budget Ranges'),
            Tab(text: 'Collections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OccasionsTab(),
          BudgetRangesTab(),
          CollectionsTab(),
        ],
      ),
    );
  }
}

// ==================== Occasions Tab ====================

class OccasionsTab extends StatefulWidget {
  const OccasionsTab({super.key});

  @override
  State<OccasionsTab> createState() => _OccasionsTabState();
}

class _OccasionsTabState extends State<OccasionsTab> {
  List<Map<String, dynamic>> _occasions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOccasions();
  }

  Future<void> _loadOccasions() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.adminGetAllOccasions();
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _occasions = List<Map<String, dynamic>>.from(response['data']);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading occasions: $e')),
        );
      }
    }
  }

  Future<void> _deleteOccasion(String id) async {
    try {
      final response = await ApiService.adminDeleteOccasion(id);
      if (response['success'] == true) {
        _loadOccasions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Occasion deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting occasion: $e')),
        );
      }
    }
  }

  void _showOccasionForm([Map<String, dynamic>? occasion]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OccasionFormScreen(
          occasion: occasion,
          onSaved: _loadOccasions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showOccasionForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add New Occasion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: _occasions.isEmpty
              ? const Center(child: Text('No occasions yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _occasions.length,
                  itemBuilder: (context, index) {
                    final occasion = _occasions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Text(
                          occasion['icon'] ?? '',
                          style: const TextStyle(fontSize: 32),
                        ),
                        title: Text(occasion['name'] ?? ''),
                        subtitle: Text(
                          '${occasion['itemCount'] ?? 0} items • Priority: ${occasion['priority'] ?? 0}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                occasion['isActive'] == true ? 'Active' : 'Inactive',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: occasion['isActive'] == true
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showOccasionForm(occasion),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteOccasion(occasion['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==================== Budget Ranges Tab ====================

class BudgetRangesTab extends StatefulWidget {
  const BudgetRangesTab({super.key});

  @override
  State<BudgetRangesTab> createState() => _BudgetRangesTabState();
}

class _BudgetRangesTabState extends State<BudgetRangesTab> {
  List<Map<String, dynamic>> _budgetRanges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgetRanges();
  }

  Future<void> _loadBudgetRanges() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.adminGetAllBudgetRanges();
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _budgetRanges = List<Map<String, dynamic>>.from(response['data']);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budget ranges: $e')),
        );
      }
    }
  }

  Future<void> _deleteBudgetRange(String id) async {
    try {
      final response = await ApiService.adminDeleteBudgetRange(id);
      if (response['success'] == true) {
        _loadBudgetRanges();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget range deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting budget range: $e')),
        );
      }
    }
  }

  void _showBudgetRangeForm([Map<String, dynamic>? budgetRange]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetRangeFormScreen(
          budgetRange: budgetRange,
          onSaved: _loadBudgetRanges,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showBudgetRangeForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add New Budget Range'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: _budgetRanges.isEmpty
              ? const Center(child: Text('No budget ranges yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _budgetRanges.length,
                  itemBuilder: (context, index) {
                    final budgetRange = _budgetRanges[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.currency_rupee, size: 32),
                        title: Text(budgetRange['label'] ?? ''),
                        subtitle: Text(
                          'Min: ₹${budgetRange['minPrice']} • Max: ₹${budgetRange['maxPrice']} • ${budgetRange['itemCount'] ?? 0} items',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (budgetRange['isPopular'] == true)
                              const Chip(
                                label: Text('Popular', style: TextStyle(fontSize: 12)),
                                backgroundColor: Colors.orange,
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showBudgetRangeForm(budgetRange),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBudgetRange(budgetRange['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==================== Collections Tab ====================

class CollectionsTab extends StatefulWidget {
  const CollectionsTab({super.key});

  @override
  State<CollectionsTab> createState() => _CollectionsTabState();
}

class _CollectionsTabState extends State<CollectionsTab> {
  List<Map<String, dynamic>> _collections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.adminGetAllCollections();
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _collections = List<Map<String, dynamic>>.from(response['data']);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collections: $e')),
        );
      }
    }
  }

  Future<void> _deleteCollection(String id) async {
    try {
      final response = await ApiService.adminDeleteCollection(id);
      if (response['success'] == true) {
        _loadCollections();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Collection deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting collection: $e')),
        );
      }
    }
  }

  void _showCollectionForm([Map<String, dynamic>? collection]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionFormScreen(
          collection: collection,
          onSaved: _loadCollections,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showCollectionForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add New Collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: _collections.isEmpty
              ? const Center(child: Text('No collections yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _collections.length,
                  itemBuilder: (context, index) {
                    final collection = _collections[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.collections, size: 32),
                        title: Text(collection['title'] ?? ''),
                        subtitle: Text(
                          '${collection['subtitle'] ?? ''} • ${collection['itemCount'] ?? 0} items',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (collection['isFeatured'] == true)
                              const Chip(
                                label: Text('Featured', style: TextStyle(fontSize: 12)),
                                backgroundColor: Colors.purple,
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showCollectionForm(collection),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCollection(collection['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==================== Form Screens (Stubs - will create detailed versions) ====================

class OccasionFormScreen extends StatefulWidget {
  final Map<String, dynamic>? occasion;
  final VoidCallback onSaved;

  const OccasionFormScreen({
    super.key,
    this.occasion,
    required this.onSaved,
  });

  @override
  State<OccasionFormScreen> createState() => _OccasionFormScreenState();
}

class _OccasionFormScreenState extends State<OccasionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _iconController;
  late TextEditingController _descriptionController;
  late TextEditingController _itemCountController;
  late TextEditingController _priorityController;
  late TextEditingController _tagsController;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.occasion?['name'] ?? '');
    _iconController = TextEditingController(text: widget.occasion?['icon'] ?? '');
    _descriptionController = TextEditingController(text: widget.occasion?['description'] ?? '');
    _itemCountController = TextEditingController(text: (widget.occasion?['itemCount'] ?? 0).toString());
    _priorityController = TextEditingController(text: (widget.occasion?['priority'] ?? 1).toString());
    _tagsController = TextEditingController(
      text: widget.occasion?['tags'] != null
        ? (widget.occasion!['tags'] as List).join(', ')
        : '',
    );
    _isActive = widget.occasion?['isActive'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _descriptionController.dispose();
    _itemCountController.dispose();
    _priorityController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'name': _nameController.text,
      'icon': _iconController.text,
      'description': _descriptionController.text,
      'itemCount': int.tryParse(_itemCountController.text) ?? 0,
      'priority': int.tryParse(_priorityController.text) ?? 1,
      'tags': _tagsController.text.split(',').map((e) => e.trim()).toList(),
      'isActive': _isActive,
    };

    try {
      final response = widget.occasion == null
          ? await ApiService.adminCreateOccasion(data)
          : await ApiService.adminUpdateOccasion(widget.occasion!['id'], data);

      if (response['success'] == true) {
        widget.onSaved();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Occasion ${widget.occasion == null ? 'created' : 'updated'} successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving occasion: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.occasion == null ? 'Add Occasion' : 'Edit Occasion'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _iconController,
              decoration: const InputDecoration(
                labelText: 'Icon (Emoji) *',
                border: OutlineInputBorder(),
                hintText: '💍',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _itemCountController,
              decoration: const InputDecoration(
                labelText: 'Item Count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priorityController,
              decoration: const InputDecoration(
                labelText: 'Priority (lower = higher priority)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
                hintText: 'engagement, rings, proposal',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.occasion == null ? 'Create Occasion' : 'Update Occasion'),
            ),
          ],
        ),
      ),
    );
  }
}

// Similar form screens for Budget Ranges and Collections (abbreviated for space)
class BudgetRangeFormScreen extends StatefulWidget {
  final Map<String, dynamic>? budgetRange;
  final VoidCallback onSaved;

  const BudgetRangeFormScreen({super.key, this.budgetRange, required this.onSaved});

  @override
  State<BudgetRangeFormScreen> createState() => _BudgetRangeFormScreenState();
}

class _BudgetRangeFormScreenState extends State<BudgetRangeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _itemCountController;
  late TextEditingController _priorityController;
  bool _isPopular = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.budgetRange?['label'] ?? '');
    _minPriceController = TextEditingController(text: (widget.budgetRange?['minPrice'] ?? 0).toString());
    _maxPriceController = TextEditingController(text: (widget.budgetRange?['maxPrice'] ?? 0).toString());
    _itemCountController = TextEditingController(text: (widget.budgetRange?['itemCount'] ?? 0).toString());
    _priorityController = TextEditingController(text: (widget.budgetRange?['priority'] ?? 1).toString());
    _isPopular = widget.budgetRange?['isPopular'] ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _itemCountController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'label': _labelController.text,
      'minPrice': double.tryParse(_minPriceController.text) ?? 0,
      'maxPrice': double.tryParse(_maxPriceController.text) ?? 0,
      'itemCount': int.tryParse(_itemCountController.text) ?? 0,
      'priority': int.tryParse(_priorityController.text) ?? 1,
      'isPopular': _isPopular,
    };

    try {
      final response = widget.budgetRange == null
          ? await ApiService.adminCreateBudgetRange(data)
          : await ApiService.adminUpdateBudgetRange(widget.budgetRange!['id'], data);

      if (response['success'] == true) {
        widget.onSaved();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Budget range ${widget.budgetRange == null ? 'created' : 'updated'} successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving budget range: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budgetRange == null ? 'Add Budget Range' : 'Edit Budget Range'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label *',
                border: OutlineInputBorder(),
                hintText: '₹ 0k-10k',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minPriceController,
              decoration: const InputDecoration(
                labelText: 'Min Price *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxPriceController,
              decoration: const InputDecoration(
                labelText: 'Max Price *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _itemCountController,
              decoration: const InputDecoration(
                labelText: 'Item Count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priorityController,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Mark as Popular'),
              value: _isPopular,
              onChanged: (value) => setState(() => _isPopular = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.budgetRange == null ? 'Create Budget Range' : 'Update Budget Range'),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionFormScreen extends StatefulWidget {
  final Map<String, dynamic>? collection;
  final VoidCallback onSaved;

  const CollectionFormScreen({super.key, this.collection, required this.onSaved});

  @override
  State<CollectionFormScreen> createState() => _CollectionFormScreenState();
}

class _CollectionFormScreenState extends State<CollectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _descriptionController;
  late TextEditingController _itemCountController;
  late TextEditingController _priorityController;
  late TextEditingController _tagsController;
  late TextEditingController _imageUrlsController;
  bool _isActive = true;
  bool _isFeatured = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.collection?['title'] ?? '');
    _subtitleController = TextEditingController(text: widget.collection?['subtitle'] ?? '');
    _descriptionController = TextEditingController(text: widget.collection?['description'] ?? '');
    _itemCountController = TextEditingController(text: (widget.collection?['itemCount'] ?? 0).toString());
    _priorityController = TextEditingController(text: (widget.collection?['priority'] ?? 1).toString());
    _tagsController = TextEditingController(
      text: widget.collection?['tags'] != null
        ? (widget.collection!['tags'] as List).join(', ')
        : '',
    );
    _imageUrlsController = TextEditingController(
      text: widget.collection?['imageUrls'] != null
        ? (widget.collection!['imageUrls'] as List).join('\n')
        : '',
    );
    _isActive = widget.collection?['isActive'] ?? true;
    _isFeatured = widget.collection?['isFeatured'] ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _itemCountController.dispose();
    _priorityController.dispose();
    _tagsController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'title': _titleController.text,
      'subtitle': _subtitleController.text,
      'description': _descriptionController.text,
      'itemCount': int.tryParse(_itemCountController.text) ?? 0,
      'priority': int.tryParse(_priorityController.text) ?? 1,
      'tags': _tagsController.text.split(',').map((e) => e.trim()).toList(),
      'imageUrls': _imageUrlsController.text.split('\n').where((e) => e.trim().isNotEmpty).toList(),
      'productIds': [], // Empty for now
      'isActive': _isActive,
      'isFeatured': _isFeatured,
    };

    try {
      final response = widget.collection == null
          ? await ApiService.adminCreateCollection(data)
          : await ApiService.adminUpdateCollection(widget.collection!['id'], data);

      if (response['success'] == true) {
        widget.onSaved();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Collection ${widget.collection == null ? 'created' : 'updated'} successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving collection: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection == null ? 'Add Collection' : 'Edit Collection'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'Subtitle *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlsController,
              decoration: const InputDecoration(
                labelText: 'Image URLs (one per line)',
                border: OutlineInputBorder(),
                hintText: 'https://example.com/image1.jpg\nhttps://example.com/image2.jpg',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _itemCountController,
              decoration: const InputDecoration(
                labelText: 'Item Count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priorityController,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            SwitchListTile(
              title: const Text('Featured'),
              value: _isFeatured,
              onChanged: (value) => setState(() => _isFeatured = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.collection == null ? 'Create Collection' : 'Update Collection'),
            ),
          ],
        ),
      ),
    );
  }
}
