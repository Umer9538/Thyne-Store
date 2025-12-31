import 'package:flutter/material.dart';
import '../../../models/banner.dart' as BannerModel;
import '../../../../data/services/api_service.dart';
import '../../../../utils/theme.dart';
import 'banner_form_screen.dart';

class HomepageManagerScreen extends StatefulWidget {
  const HomepageManagerScreen({super.key});

  @override
  State<HomepageManagerScreen> createState() => _HomepageManagerScreenState();
}

class _HomepageManagerScreenState extends State<HomepageManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BannerModel.Banner> _allBanners = [];
  List<BannerModel.Banner> _activeBanners = [];
  List<BannerModel.Banner> _scheduledBanners = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBanners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getBanners();
      if (response['success'] == true && response['data'] != null) {
        final bannersData = response['data'] as List;
        final banners = bannersData
            .map((json) => BannerModel.Banner.fromJson(json))
            .toList();

        setState(() {
          _allBanners = banners;
          _activeBanners = banners.where((b) => b.isLive).toList();
          _scheduledBanners = banners.where((b) => b.isScheduled).toList();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load banners: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBanner(String bannerId) async {
    try {
      await ApiService.deleteBanner(bannerId: bannerId);
      _showSuccessSnackBar('Banner deleted successfully');
      _loadBanners();
    } catch (e) {
      _showErrorSnackBar('Failed to delete banner: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage Manager'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGold,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryGold,
          tabs: const [
            Tab(text: 'All Banners'),
            Tab(text: 'Active'),
            Tab(text: 'Scheduled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBannerList(_allBanners, 'No banners created yet'),
                _buildBannerList(_activeBanners, 'No active banners'),
                _buildBannerList(_scheduledBanners, 'No scheduled banners'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BannerFormScreen(),
            ),
          );
          if (result == true) {
            _loadBanners();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Banner'),
        backgroundColor: AppTheme.primaryGold,
      ),
    );
  }

  Widget _buildBannerList(List<BannerModel.Banner> banners, String emptyMessage) {
    if (banners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBanners,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          return _buildBannerCard(banner);
        },
      ),
    );
  }

  Widget _buildBannerCard(BannerModel.Banner banner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            ),
          ),

          // Banner Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        banner.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(banner),
                  ],
                ),
                if (banner.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    banner.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Start: ${_formatDate(banner.startDate)}',
                ),
                if (banner.endDate != null)
                  _buildInfoRow(
                    Icons.event,
                    'End: ${_formatDate(banner.endDate!)}',
                  ),
                _buildInfoRow(
                  Icons.priority_high,
                  'Priority: ${banner.priority}',
                ),
                if (banner.festivalTag != null)
                  _buildInfoRow(
                    Icons.celebration,
                    'Festival: ${banner.festivalTag}',
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BannerFormScreen(
                                banner: banner,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadBanners();
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteDialog(banner),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          side: const BorderSide(color: AppTheme.errorRed),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BannerModel.Banner banner) {
    Color color;
    String label;

    if (banner.isLive) {
      color = AppTheme.successGreen;
      label = 'LIVE';
    } else if (banner.isScheduled) {
      color = AppTheme.warningAmber;
      label = 'SCHEDULED';
    } else if (banner.isExpired) {
      color = AppTheme.errorRed;
      label = 'EXPIRED';
    } else {
      color = Colors.grey;
      label = 'INACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BannerModel.Banner banner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: Text('Are you sure you want to delete "${banner.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBanner(banner.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
