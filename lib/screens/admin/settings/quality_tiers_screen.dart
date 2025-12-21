import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/store_settings.dart';

/// Admin screen for managing quality tiers (Standard, Premium, Exclusive, etc.)
class QualityTiersScreen extends StatefulWidget {
  final List<StoneQuality> initialQualities;
  final ValueChanged<List<StoneQuality>>? onQualitiesChanged;

  const QualityTiersScreen({
    super.key,
    required this.initialQualities,
    this.onQualitiesChanged,
  });

  @override
  State<QualityTiersScreen> createState() => _QualityTiersScreenState();
}

class _QualityTiersScreenState extends State<QualityTiersScreen> {
  late List<StoneQuality> _qualities;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _qualities = List.from(widget.initialQualities);
    if (_qualities.isEmpty) {
      _qualities = List.from(StoneQuality.defaults);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _qualities.removeAt(oldIndex);
      _qualities.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  void _addQuality() async {
    final result = await showDialog<StoneQuality>(
      context: context,
      builder: (context) => const _QualityEditDialog(
        title: 'Add Quality Tier',
      ),
    );

    if (result != null) {
      setState(() {
        _qualities.add(result);
        _hasChanges = true;
      });
    }
  }

  void _editQuality(int index) async {
    final result = await showDialog<StoneQuality>(
      context: context,
      builder: (context) => _QualityEditDialog(
        title: 'Edit Quality Tier',
        quality: _qualities[index],
      ),
    );

    if (result != null) {
      setState(() {
        _qualities[index] = result;
        _hasChanges = true;
      });
    }
  }

  void _deleteQuality(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quality Tier'),
        content: Text(
          'Are you sure you want to delete "${_qualities[index].name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _qualities.removeAt(index);
        _hasChanges = true;
      });
    }
  }

  void _saveChanges() {
    widget.onQualitiesChanged?.call(_qualities);
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quality tiers saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will replace all current quality tiers with the default set. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _qualities = List.from(StoneQuality.defaults);
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Tiers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
            onPressed: _resetToDefaults,
          ),
          if (_hasChanges)
            TextButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Drag to reorder tiers. The order affects how they appear to customers.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quality tiers list
          Expanded(
            child: _qualities.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _qualities.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final quality = _qualities[index];
                      return _QualityTierCard(
                        key: ValueKey(quality.name + index.toString()),
                        quality: quality,
                        index: index,
                        onEdit: () => _editQuality(index),
                        onDelete: () => _deleteQuality(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQuality,
        icon: const Icon(Icons.add),
        label: const Text('Add Tier'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No quality tiers defined',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add quality tiers to offer different stone grades',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
            label: const Text('Load Defaults'),
          ),
        ],
      ),
    );
  }
}

class _QualityTierCard extends StatelessWidget {
  final StoneQuality quality;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QualityTierCard({
    super.key,
    required this.quality,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.drag_handle, color: Colors.grey[400]),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getQualityColor(quality.name),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              quality.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              quality.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: quality.priceMultiplier > 1.0
                    ? Colors.orange.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                quality.priceMultiplier == 1.0
                    ? 'Base Price'
                    : '+${((quality.priceMultiplier - 1) * 100).toInt()}% price',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: quality.priceMultiplier > 1.0
                      ? Colors.orange.shade700
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: 'Delete',
              color: Colors.red.shade400,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getQualityColor(String name) {
    switch (name.toLowerCase()) {
      case 'standard':
        return Colors.grey;
      case 'premium':
        return Colors.blue;
      case 'exclusive':
      case 'excellent':
        return const Color(0xFFD4AF37);
      case 'elite':
      case 'exceptional':
        return Colors.purple;
      case 'signature':
        return Colors.deepPurple;
      default:
        return Colors.teal;
    }
  }
}

class _QualityEditDialog extends StatefulWidget {
  final String title;
  final StoneQuality? quality;

  const _QualityEditDialog({
    required this.title,
    this.quality,
  });

  @override
  State<_QualityEditDialog> createState() => _QualityEditDialogState();
}

class _QualityEditDialogState extends State<_QualityEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _multiplierController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.quality?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.quality?.description ?? '',
    );
    _multiplierController = TextEditingController(
      text: widget.quality?.priceMultiplier.toString() ?? '1.0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _multiplierController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final quality = StoneQuality(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        priceMultiplier:
            double.tryParse(_multiplierController.text) ?? 1.0,
      );
      Navigator.pop(context, quality);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Premium, Exclusive',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of this quality tier',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _multiplierController,
              decoration: const InputDecoration(
                labelText: 'Price Multiplier',
                hintText: 'e.g., 1.0 (no change), 1.5 (+50%)',
                border: OutlineInputBorder(),
                suffixText: 'x',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Multiplier is required';
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed < 0.1 || parsed > 10) {
                  return 'Enter a value between 0.1 and 10';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '1.0 = base price, 1.5 = +50%, 2.0 = +100%',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
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
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
          ),
          child: Text(widget.quality == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
