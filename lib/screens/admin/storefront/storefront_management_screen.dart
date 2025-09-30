import 'package:flutter/material.dart';
import '../../../models/storefront_config.dart';
import '../../../services/api_service.dart';
import '../../../utils/theme.dart';

class StorefrontManagementScreen extends StatefulWidget {
  const StorefrontManagementScreen({super.key});

  @override
  State<StorefrontManagementScreen> createState() => _StorefrontManagementScreenState();
}

class _StorefrontManagementScreenState extends State<StorefrontManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  StorefrontConfig _config = StorefrontConfig.defaultConfig;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadConfig() {
    () async {
      try {
        final resp = await ApiService.getStorefrontConfig();
        if (resp['success'] == true && resp['data'] != null) {
          setState(() {
            _config = StorefrontConfig.fromJson(resp['data']);
          });
        } else {
          setState(() { _config = StorefrontConfig.defaultConfig; });
        }
      } catch (_) {
        setState(() { _config = StorefrontConfig.defaultConfig; });
      }
    }();
  }

  void _saveConfig() {
    () async {
      try {
        final body = _config.toJson();
        await ApiService.updateStorefrontConfig(config: body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storefront configuration saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storefront Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Homepage'),
            Tab(text: 'Categories'),
            Tab(text: 'Banners'),
            Tab(text: 'Features'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomepageTab(),
          _buildCategoriesTab(),
          _buildBannersTab(),
          _buildFeaturesTab(),
        ],
      ),
    );
  }

  Widget _buildHomepageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Announcement Bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Announcement Bar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Announcement Message',
                      hintText: 'Free shipping on orders over \$50!',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Update config
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Welcome Message
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Message',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Welcome Message',
                      hintText: 'Welcome to Thyne Jewels!',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Update config
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section Visibility
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Homepage Sections',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildSectionToggle(
                    'New Arrivals',
                    _config.homePage.showNewArrivals,
                    (value) {
                      setState(() {
                        _config = StorefrontConfig(
                          id: _config.id,
                          homePage: HomePageConfig(
                            heroBanners: _config.homePage.heroBanners,
                            carousels: _config.homePage.carousels,
                            featuredProductIds: _config.homePage.featuredProductIds,
                            featuredCategoryIds: _config.homePage.featuredCategoryIds,
                            showNewArrivals: value,
                            showBestSellers: _config.homePage.showBestSellers,
                            showRecommended: _config.homePage.showRecommended,
                            showDeals: _config.homePage.showDeals,
                            welcomeMessage: _config.homePage.welcomeMessage,
                            announcementBar: _config.homePage.announcementBar,
                          ),
                          categoryVisibility: _config.categoryVisibility,
                          promotionalBanners: _config.promotionalBanners,
                          themeConfig: _config.themeConfig,
                          featureFlags: _config.featureFlags,
                          lastUpdated: DateTime.now(),
                        );
                      });
                    },
                  ),
                  _buildSectionToggle(
                    'Best Sellers',
                    _config.homePage.showBestSellers,
                    (value) {
                      // Update config
                    },
                  ),
                  _buildSectionToggle(
                    'Recommended',
                    _config.homePage.showRecommended,
                    (value) {
                      // Update config
                    },
                  ),
                  _buildSectionToggle(
                    'Deals & Offers',
                    _config.homePage.showDeals,
                    (value) {
                      // Update config
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hero Banners
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hero Banners',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton.icon(
                        onPressed: _addHeroBanner,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Banner'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_config.homePage.heroBanners.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.image, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No hero banners configured'),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._config.homePage.heroBanners.map((banner) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.image),
                        title: Text(banner.title ?? 'Untitled Banner'),
                        subtitle: Text(banner.subtitle ?? 'No subtitle'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: banner.isActive,
                              onChanged: (value) {
                                setState(() {
                                  final idx = _config.homePage.heroBanners.indexWhere((h) => h.id == banner.id);
                                  if (idx >= 0) {
                                    final updated = HeroBanner(
                                      id: banner.id,
                                      imageUrl: banner.imageUrl,
                                      title: banner.title,
                                      subtitle: banner.subtitle,
                                      ctaText: banner.ctaText,
                                      ctaLink: banner.ctaLink,
                                      order: banner.order,
                                      isActive: value,
                                      startDate: banner.startDate,
                                      endDate: banner.endDate,
                                    );
                                    final list = [..._config.homePage.heroBanners];
                                    list[idx] = updated;
                                    _config = StorefrontConfig(
                                      id: _config.id,
                                      homePage: HomePageConfig(
                                        heroBanners: list,
                                        carousels: _config.homePage.carousels,
                                        featuredProductIds: _config.homePage.featuredProductIds,
                                        featuredCategoryIds: _config.homePage.featuredCategoryIds,
                                        showNewArrivals: _config.homePage.showNewArrivals,
                                        showBestSellers: _config.homePage.showBestSellers,
                                        showRecommended: _config.homePage.showRecommended,
                                        showDeals: _config.homePage.showDeals,
                                        welcomeMessage: _config.homePage.welcomeMessage,
                                        announcementBar: _config.homePage.announcementBar,
                                      ),
                                      categoryVisibility: _config.categoryVisibility,
                                      promotionalBanners: _config.promotionalBanners,
                                      themeConfig: _config.themeConfig,
                                      featureFlags: _config.featureFlags,
                                      lastUpdated: DateTime.now(),
                                    );
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editHeroBanner(banner),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteHeroBanner(banner.id),
                            ),
                          ],
                        ),
                      ),
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Visibility & Order',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: _config.categoryVisibility.map((category) => Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${category.order}'),
                  ),
                  title: Text(category.categoryId.toUpperCase()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: category.isVisible,
                        onChanged: (value) {
                          setState(() {
                            final updated = _config.categoryVisibility.map((c) {
                              if (c.categoryId == category.categoryId) {
                                return CategoryVisibility(
                                  categoryId: c.categoryId,
                                  isVisible: value,
                                  order: c.order,
                                );
                              }
                              return c;
                            }).toList();
                            _config = StorefrontConfig(
                              id: _config.id,
                              homePage: _config.homePage,
                              categoryVisibility: updated,
                              promotionalBanners: _config.promotionalBanners,
                              themeConfig: _config.themeConfig,
                              featureFlags: _config.featureFlags,
                              lastUpdated: DateTime.now(),
                            );
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: category.order > 1 ? () {
                          // Move category up
                        } : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: category.order < _config.categoryVisibility.length ? () {
                          // Move category down
                        } : null,
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Promotional Banners
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promotional Banners',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionToggle(
                    'Show Top Banner',
                    _config.promotionalBanners.showTopBanner,
                    (value) {
                      // Update config
                    },
                  ),
                  if (_config.promotionalBanners.showTopBanner) ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Top Banner Image URL',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Update banner URL
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildSectionToggle(
                    'Show Bottom Banner',
                    _config.promotionalBanners.showBottomBanner,
                    (value) {
                      // Update config
                    },
                  ),
                  if (_config.promotionalBanners.showBottomBanner) ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Bottom Banner Image URL',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Update banner URL
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildSectionToggle(
                    'Show Popup Banners',
                    _config.promotionalBanners.showPopups,
                    (value) {
                      // Update config
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feature Flags',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFeatureToggle(
                    'Loyalty Program',
                    'Enable points and rewards system',
                    _config.featureFlags.enableLoyaltyProgram,
                    (value) {
                      // Update feature flag
                    },
                  ),
                  _buildFeatureToggle(
                    'Wishlist',
                    'Allow users to save favorite items',
                    _config.featureFlags.enableWishlist,
                    (value) {
                      // Update feature flag
                    },
                  ),
                  _buildFeatureToggle(
                    'Product Reviews',
                    'Enable customer reviews and ratings',
                    _config.featureFlags.enableReviews,
                    (value) {
                      // Update feature flag
                    },
                  ),
                  _buildFeatureToggle(
                    'Live Chat',
                    'Enable customer support chat',
                    _config.featureFlags.enableChat,
                    (value) {
                      // Update feature flag
                    },
                  ),
                  _buildFeatureToggle(
                    'AR Try-On',
                    'Enable augmented reality features',
                    _config.featureFlags.enableAR,
                    (value) {
                      // Update feature flag
                    },
                  ),
                  _buildFeatureToggle(
                    'Social Login',
                    'Enable Google/Facebook login',
                    _config.featureFlags.enableSocialLogin,
                    (value) {
                      // Update feature flag
                    },
                  ),
                  _buildFeatureToggle(
                    'Guest Checkout',
                    'Allow checkout without account',
                    _config.featureFlags.enableGuestCheckout,
                    (value) {
                      // Update feature flag
                    },
                  ),
                  _buildFeatureToggle(
                    'Referral Program',
                    'Enable friend referral rewards',
                    _config.featureFlags.enableReferrals,
                    (value) {
                      // Update feature flag
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionToggle(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFeatureToggle(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _addHeroBanner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Hero Banner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Subtitle',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'CTA Text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'CTA Link',
                  border: OutlineInputBorder(),
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
            onPressed: () {
              // Add banner to config
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editHeroBanner(HeroBanner banner) {
    // Show edit dialog
  }

  void _deleteHeroBanner(String bannerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to delete this banner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Remove banner from config
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}