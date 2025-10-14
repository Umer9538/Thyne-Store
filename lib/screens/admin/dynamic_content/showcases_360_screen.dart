import 'package:flutter/material.dart';
import 'package:thyne_jewls/utils/theme.dart';
import 'package:thyne_jewls/services/api_service.dart';
import 'package:thyne_jewls/models/homepage.dart';

class Showcases360Screen extends StatefulWidget {
  const Showcases360Screen({super.key});

  @override
  State<Showcases360Screen> createState() => _Showcases360ScreenState();
}

class _Showcases360ScreenState extends State<Showcases360Screen> {
  bool _loading = true;
  List<Showcase360> _showcases = [];

  @override
  void initState() {
    super.initState();
    _loadShowcases();
  }

  Future<void> _loadShowcases() async {
    setState(() => _loading = true);

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
    } catch (e) {
      print('Error loading showcases: $e');
    }

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _showcases.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadShowcases,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _showcases.length,
                    itemBuilder: (context, index) => _buildShowcaseCard(_showcases[index]),
                  ),
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

  void _editShowcase(Showcase360 showcase) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${showcase.title} - Coming Soon')),
    );
  }

  void _toggleShowcase(Showcase360 showcase) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${showcase.title} ${showcase.isActive ? "deactivated" : "activated"}'),
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${showcase.title} deleted')),
      );
      _loadShowcases();
    }
  }
}
