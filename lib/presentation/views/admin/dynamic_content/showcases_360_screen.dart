import 'package:flutter/material.dart';
import 'package:thyne_jewls/utils/theme.dart';
import 'package:thyne_jewls/data/services/api_service.dart';
import 'package:thyne_jewls/data/models/homepage.dart';

class Showcases360Screen extends StatefulWidget {
  const Showcases360Screen({super.key});

  @override
  State<Showcases360Screen> createState() => _Showcases360ScreenState();
}

class _Showcases360ScreenState extends State<Showcases360Screen> {
  bool _loading = true;
  List<Showcase360> _showcases = [];
  List<Showcase360> _filteredShowcases = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadShowcases();
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
      _filterShowcases();
    });
  }

  void _filterShowcases() {
    if (_searchQuery.isEmpty) {
      _filteredShowcases = List.from(_showcases);
    } else {
      _filteredShowcases = _showcases.where((showcase) {
        return showcase.title.toLowerCase().contains(_searchQuery) ||
            showcase.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadShowcases() async {
    setState(() => _loading = true);

    try {
      // Use admin endpoint to get all showcases (including inactive)
      final response = await ApiService.getAllShowcases();
      if (response['success'] == true && response['data'] != null) {
        _showcases = (response['data'] as List)
            .map((s) => Showcase360.fromJson(s))
            .toList();
        _filterShowcases();
        setState(() => _loading = false);
        return;
      }
    } catch (e) {
      print('Error loading showcases: $e');
      // Fallback to homepage endpoint
      try {
        final response = await ApiService.getHomepage();
        if (response['success'] == true && response['data'] != null) {
          final homepage = response['data'] as Map<String, dynamic>;
          if (homepage['showcases360'] != null) {
            _showcases = (homepage['showcases360'] as List)
                .map((s) => Showcase360.fromJson(s))
                .toList();
          }
        }
      } catch (_) {}
    }

    _filterShowcases();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('360° Showcases'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
            tooltip: 'Add Showcase',
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
                hintText: 'Search showcases...',
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _showcases.isEmpty
                    ? _buildEmptyState()
                    : _filteredShowcases.isEmpty
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
                            onRefresh: _loadShowcases,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredShowcases.length,
                              itemBuilder: (context, index) => _buildShowcaseCard(_filteredShowcases[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rotate_right, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No 360° Showcases',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add interactive product views',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Showcase'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseCard(Showcase360 showcase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: showcase.isLive ? Colors.purple.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        showcase.isLive ? Icons.visibility : Icons.visibility_off,
                        size: 14,
                        color: showcase.isLive ? Colors.purple.shade700 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        showcase.isLive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: showcase.isLive ? Colors.purple.shade700 : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'toggle', child: Text('Toggle Active')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') _editShowcase(showcase);
                    if (value == 'toggle') _toggleShowcase(showcase);
                    if (value == 'delete') _deleteShowcase(showcase);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              showcase.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              showcase.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.image,
                  label: '${showcase.images360.length} Images',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                if (showcase.videoUrl.isNotEmpty)
                  _buildStatChip(
                    icon: Icons.videocam,
                    label: 'Video',
                    color: Colors.purple,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() async {
    final result = await Navigator.pushNamed(context, '/admin/showcases-360/create');
    if (result == true && mounted) {
      _loadShowcases();
    }
  }

  void _editShowcase(Showcase360 showcase) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditShowcaseForm(showcase: showcase),
      ),
    );
    if (result == true && mounted) {
      _loadShowcases();
    }
  }

  void _toggleShowcase(Showcase360 showcase) async {
    try {
      final response = await ApiService.updateShowcase360(
        id: showcase.id,
        productId: showcase.productId,
        title: showcase.title,
        description: showcase.description,
        images: showcase.images360,
        videoUrl: showcase.videoUrl,
        priority: showcase.priority,
        isActive: !showcase.isActive,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${showcase.title} ${showcase.isActive ? "deactivated" : "activated"}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadShowcases();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['error'] ?? 'Failed to update'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteShowcase(Showcase360 showcase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Showcase?'),
        content: Text('Are you sure you want to delete "${showcase.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.deleteShowcase360(showcase.id);
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${showcase.title} deleted'),
              backgroundColor: Colors.green,
            ),
          );
          _loadShowcases();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response['error'] ?? 'Failed to delete'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Edit Showcase Form
class EditShowcaseForm extends StatefulWidget {
  final Showcase360 showcase;

  const EditShowcaseForm({super.key, required this.showcase});

  @override
  State<EditShowcaseForm> createState() => _EditShowcaseFormState();
}

class _EditShowcaseFormState extends State<EditShowcaseForm> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _videoUrlController;
  late List<TextEditingController> _imageControllers;
  late int _priority;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.showcase.title);
    _descriptionController = TextEditingController(text: widget.showcase.description);
    _videoUrlController = TextEditingController(text: widget.showcase.videoUrl);
    _imageControllers = widget.showcase.images360.isNotEmpty
        ? widget.showcase.images360.map((url) => TextEditingController(text: url)).toList()
        : [
            TextEditingController(),
            TextEditingController(),
            TextEditingController(),
            TextEditingController(),
          ];
    // Ensure at least 4 image fields
    while (_imageControllers.length < 4) {
      _imageControllers.add(TextEditingController());
    }
    _priority = widget.showcase.priority;
    _isActive = widget.showcase.isActive;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    for (var controller in _imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveShowcase() async {
    if (!_formKey.currentState!.validate()) return;

    final images360 = _imageControllers
        .map((c) => c.text.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    if (images360.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least 4 images for 360° rotation')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await ApiService.updateShowcase360(
        id: widget.showcase.id,
        productId: widget.showcase.productId,
        title: _titleController.text,
        description: _descriptionController.text,
        images: images360,
        videoUrl: _videoUrlController.text.trim().isNotEmpty
            ? _videoUrlController.text.trim()
            : null,
        priority: _priority,
        isActive: _isActive,
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('360° Showcase updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response['error'] ?? 'Failed to update showcase'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating showcase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  void _addImageField() {
    setState(() {
      _imageControllers.add(TextEditingController());
    });
  }

  void _removeImageField(int index) {
    if (_imageControllers.length > 4) {
      setState(() {
        _imageControllers[index].dispose();
        _imageControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit 360° Showcase'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveShowcase,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Toggle
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Show this showcase on homepage'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: AppTheme.primaryGold,
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Basic Info
              Text(
                'Showcase Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Stunning Diamond Ring 360° View',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the showcase',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // 360° Images
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '360° Images',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addImageField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Image'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'At least 4 images taken from different angles',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              ...List.generate(_imageControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imageControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Image ${index + 1} URL',
                            hintText: 'https://example.com/image${index + 1}.jpg',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.image),
                          ),
                          validator: (value) {
                            if (index < 4 && (value == null || value.isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_imageControllers.length > 4)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeImageField(index),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Video
              Text(
                'Additional Media',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL (Optional)',
                  hintText: 'https://example.com/video.mp4',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.videocam),
                ),
              ),

              const SizedBox(height: 32),

              // Priority
              Text(
                'Display Priority',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Higher priority showcases appear first',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _priority.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _priority.toString(),
                      activeColor: AppTheme.primaryGold,
                      onChanged: (value) {
                        setState(() => _priority = value.toInt());
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _priority.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
