import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../models/homepage.dart';
import '../../../../data/services/api_service.dart';
import '../../../../utils/theme.dart';

class LayoutManagerScreen extends StatefulWidget {
  const LayoutManagerScreen({super.key});

  @override
  State<LayoutManagerScreen> createState() => _LayoutManagerScreenState();
}

class _LayoutManagerScreenState extends State<LayoutManagerScreen> {
  List<SectionLayoutItem> _layoutItems = [];
  String? _layoutId; // Store the layout document ID
  bool _isLoading = false;
  bool _isSaving = false;

  final Map<SectionType, String> _sectionNames = {
    SectionType.bannerCarousel: 'Hero Carousel',
    SectionType.dealOfDay: 'Deal of the Day',
    SectionType.flashSale: 'Flash Sales',
    SectionType.categories: 'Categories',
    SectionType.showcase360: '360° Showcases',
    SectionType.bundleDeals: 'Bundle Deals',
    SectionType.featured: 'Featured Products',
    SectionType.recentlyViewed: 'Recently Viewed',
    SectionType.newArrivals: 'New Arrivals',
  };

  final Map<SectionType, IconData> _sectionIcons = {
    SectionType.bannerCarousel: Icons.view_carousel,
    SectionType.dealOfDay: Icons.local_offer,
    SectionType.flashSale: Icons.flash_on,
    SectionType.categories: Icons.category,
    SectionType.showcase360: Icons.threed_rotation,
    SectionType.bundleDeals: Icons.card_giftcard,
    SectionType.featured: Icons.star,
    SectionType.recentlyViewed: Icons.history,
    SectionType.newArrivals: Icons.fiber_new,
  };

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getHomepageLayout();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final layoutData = data['layout'] as List?;
        if (layoutData != null) {
          setState(() {
            _layoutId = data['id']; // Store the layout document ID
            _layoutItems = layoutData
                .map((item) => SectionLayoutItem.fromJson(item))
                .toList();
            _layoutItems.sort((a, b) => a.order.compareTo(b.order));
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error loading layout: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLayout() async {
    setState(() => _isSaving = true);
    try {
      // Update order values based on current list position
      for (int i = 0; i < _layoutItems.length; i++) {
        _layoutItems[i] = SectionLayoutItem(
          sectionType: _layoutItems[i].sectionType,
          order: i,
          isVisible: _layoutItems[i].isVisible,
          title: _layoutItems[i].title,
        );
      }

      final requestBody = <String, dynamic>{
        'layout': _layoutItems.map((item) => item.toJson()).toList(),
      };

      // Include the layout ID if we have it
      if (_layoutId != null) {
        requestBody['id'] = _layoutId!;
      }

      final response = await ApiService.updateHomepageLayout(requestBody);

      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Layout saved successfully!',
          backgroundColor: AppTheme.primaryGold,
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to save layout');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error saving layout: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _layoutItems.removeAt(oldIndex);
      _layoutItems.insert(newIndex, item);
    });
  }

  void _toggleVisibility(int index) {
    setState(() {
      _layoutItems[index] = SectionLayoutItem(
        sectionType: _layoutItems[index].sectionType,
        order: _layoutItems[index].order,
        isVisible: !_layoutItems[index].isVisible,
        title: _layoutItems[index].title,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage Layout Manager'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveLayout,
              tooltip: 'Save Layout',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLayout,
            tooltip: 'Reload Layout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            )
          : _layoutItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.dashboard_customize,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No layout configuration found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadLayout,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Instructions Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryGold,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Manage Homepage Layout',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Drag sections to reorder, tap the eye icon to show/hide sections. Changes apply immediately to the customer homepage.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Section List
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _layoutItems.length,
                        onReorder: _reorderItems,
                        itemBuilder: (context, index) {
                          final item = _layoutItems[index];
                          final sectionName = _sectionNames[item.sectionType] ??
                              item.sectionType.value;
                          final icon =
                              _sectionIcons[item.sectionType] ?? Icons.widgets;

                          return Card(
                            key: ValueKey(item.sectionType.value),
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: item.isVisible
                                    ? AppTheme.primaryGold.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: item.isVisible
                                      ? AppTheme.primaryGold.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  color: item.isVisible
                                      ? AppTheme.primaryGold
                                      : Colors.grey,
                                ),
                              ),
                              title: Text(
                                sectionName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item.isVisible
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              subtitle: Text(
                                'Order: ${index + 1} • ${item.isVisible ? "Visible" : "Hidden"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.isVisible
                                      ? Colors.black54
                                      : Colors.grey,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      item.isVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: item.isVisible
                                          ? AppTheme.primaryGold
                                          : Colors.grey,
                                    ),
                                    onPressed: () => _toggleVisibility(index),
                                    tooltip: item.isVisible
                                        ? 'Hide Section'
                                        : 'Show Section',
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Save Button
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
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveLayout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Layout Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
