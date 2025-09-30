class StorefrontConfig {
  final String id;
  final HomePageConfig homePage;
  final List<CategoryVisibility> categoryVisibility;
  final PromotionalBanners promotionalBanners;
  final ThemeConfig themeConfig;
  final FeatureFlags featureFlags;
  final DateTime lastUpdated;

  StorefrontConfig({
    required this.id,
    required this.homePage,
    required this.categoryVisibility,
    required this.promotionalBanners,
    required this.themeConfig,
    required this.featureFlags,
    required this.lastUpdated,
  });

  factory StorefrontConfig.fromJson(Map<String, dynamic> json) {
    return StorefrontConfig(
      id: json['id'],
      homePage: HomePageConfig.fromJson(json['homePage']),
      categoryVisibility: (json['categoryVisibility'] as List)
          .map((c) => CategoryVisibility.fromJson(c))
          .toList(),
      promotionalBanners: PromotionalBanners.fromJson(json['promotionalBanners']),
      themeConfig: ThemeConfig.fromJson(json['themeConfig']),
      featureFlags: FeatureFlags.fromJson(json['featureFlags']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homePage': homePage.toJson(),
      'categoryVisibility': categoryVisibility.map((c) => c.toJson()).toList(),
      'promotionalBanners': promotionalBanners.toJson(),
      'themeConfig': themeConfig.toJson(),
      'featureFlags': featureFlags.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Default configuration
  static StorefrontConfig get defaultConfig {
    return StorefrontConfig(
      id: 'default',
      homePage: HomePageConfig.defaultConfig,
      categoryVisibility: [
        CategoryVisibility(categoryId: 'rings', isVisible: true, order: 1),
        CategoryVisibility(categoryId: 'necklaces', isVisible: true, order: 2),
        CategoryVisibility(categoryId: 'bracelets', isVisible: true, order: 3),
        CategoryVisibility(categoryId: 'earrings', isVisible: true, order: 4),
      ],
      promotionalBanners: PromotionalBanners.defaultConfig,
      themeConfig: ThemeConfig.defaultConfig,
      featureFlags: FeatureFlags.defaultFlags,
      lastUpdated: DateTime.now(),
    );
  }
}

class HomePageConfig {
  final List<HeroBanner> heroBanners;
  final List<CarouselSection> carousels;
  final List<String> featuredProductIds;
  final List<String> featuredCategoryIds;
  final bool showNewArrivals;
  final bool showBestSellers;
  final bool showRecommended;
  final bool showDeals;
  final String? welcomeMessage;
  final String? announcementBar;

  HomePageConfig({
    required this.heroBanners,
    required this.carousels,
    required this.featuredProductIds,
    required this.featuredCategoryIds,
    this.showNewArrivals = true,
    this.showBestSellers = true,
    this.showRecommended = true,
    this.showDeals = true,
    this.welcomeMessage,
    this.announcementBar,
  });

  factory HomePageConfig.fromJson(Map<String, dynamic> json) {
    return HomePageConfig(
      heroBanners: (json['heroBanners'] as List)
          .map((h) => HeroBanner.fromJson(h))
          .toList(),
      carousels: (json['carousels'] as List)
          .map((c) => CarouselSection.fromJson(c))
          .toList(),
      featuredProductIds: List<String>.from(json['featuredProductIds']),
      featuredCategoryIds: List<String>.from(json['featuredCategoryIds']),
      showNewArrivals: json['showNewArrivals'] ?? true,
      showBestSellers: json['showBestSellers'] ?? true,
      showRecommended: json['showRecommended'] ?? true,
      showDeals: json['showDeals'] ?? true,
      welcomeMessage: json['welcomeMessage'],
      announcementBar: json['announcementBar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heroBanners': heroBanners.map((h) => h.toJson()).toList(),
      'carousels': carousels.map((c) => c.toJson()).toList(),
      'featuredProductIds': featuredProductIds,
      'featuredCategoryIds': featuredCategoryIds,
      'showNewArrivals': showNewArrivals,
      'showBestSellers': showBestSellers,
      'showRecommended': showRecommended,
      'showDeals': showDeals,
      'welcomeMessage': welcomeMessage,
      'announcementBar': announcementBar,
    };
  }

  static HomePageConfig get defaultConfig {
    return HomePageConfig(
      heroBanners: [],
      carousels: [],
      featuredProductIds: [],
      featuredCategoryIds: [],
    );
  }
}

class HeroBanner {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? ctaText;
  final String? ctaLink;
  final int order;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  HeroBanner({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.ctaText,
    this.ctaLink,
    required this.order,
    this.isActive = true,
    this.startDate,
    this.endDate,
  });

  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  factory HeroBanner.fromJson(Map<String, dynamic> json) {
    return HeroBanner(
      id: json['id'],
      imageUrl: json['imageUrl'],
      title: json['title'],
      subtitle: json['subtitle'],
      ctaText: json['ctaText'],
      ctaLink: json['ctaLink'],
      order: json['order'],
      isActive: json['isActive'] ?? true,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'ctaText': ctaText,
      'ctaLink': ctaLink,
      'order': order,
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}

class CarouselSection {
  final String id;
  final String title;
  final CarouselType type;
  final List<String> itemIds;
  final int order;
  final bool isVisible;

  CarouselSection({
    required this.id,
    required this.title,
    required this.type,
    required this.itemIds,
    required this.order,
    this.isVisible = true,
  });

  factory CarouselSection.fromJson(Map<String, dynamic> json) {
    return CarouselSection(
      id: json['id'],
      title: json['title'],
      type: CarouselType.values.firstWhere(
        (t) => t.toString() == 'CarouselType.${json['type']}',
      ),
      itemIds: List<String>.from(json['itemIds']),
      order: json['order'],
      isVisible: json['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'itemIds': itemIds,
      'order': order,
      'isVisible': isVisible,
    };
  }
}

enum CarouselType {
  products,
  categories,
  brands,
  custom,
}

class CategoryVisibility {
  final String categoryId;
  final bool isVisible;
  final int order;

  CategoryVisibility({
    required this.categoryId,
    required this.isVisible,
    required this.order,
  });

  factory CategoryVisibility.fromJson(Map<String, dynamic> json) {
    return CategoryVisibility(
      categoryId: json['categoryId'],
      isVisible: json['isVisible'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'isVisible': isVisible,
      'order': order,
    };
  }
}

class PromotionalBanners {
  final String? topBanner;
  final String? bottomBanner;
  final List<String> popupBanners;
  final bool showTopBanner;
  final bool showBottomBanner;
  final bool showPopups;

  PromotionalBanners({
    this.topBanner,
    this.bottomBanner,
    this.popupBanners = const [],
    this.showTopBanner = false,
    this.showBottomBanner = false,
    this.showPopups = false,
  });

  factory PromotionalBanners.fromJson(Map<String, dynamic> json) {
    return PromotionalBanners(
      topBanner: json['topBanner'],
      bottomBanner: json['bottomBanner'],
      popupBanners: List<String>.from(json['popupBanners'] ?? []),
      showTopBanner: json['showTopBanner'] ?? false,
      showBottomBanner: json['showBottomBanner'] ?? false,
      showPopups: json['showPopups'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topBanner': topBanner,
      'bottomBanner': bottomBanner,
      'popupBanners': popupBanners,
      'showTopBanner': showTopBanner,
      'showBottomBanner': showBottomBanner,
      'showPopups': showPopups,
    };
  }

  static PromotionalBanners get defaultConfig {
    return PromotionalBanners();
  }
}

class ThemeConfig {
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String fontFamily;
  final bool isDarkMode;

  ThemeConfig({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.fontFamily,
    this.isDarkMode = false,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      primaryColor: json['primaryColor'],
      secondaryColor: json['secondaryColor'],
      accentColor: json['accentColor'],
      fontFamily: json['fontFamily'],
      isDarkMode: json['isDarkMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'fontFamily': fontFamily,
      'isDarkMode': isDarkMode,
    };
  }

  static ThemeConfig get defaultConfig {
    return ThemeConfig(
      primaryColor: '#FFD700',
      secondaryColor: '#E5B7B7',
      accentColor: '#B76E79',
      fontFamily: 'Poppins',
    );
  }
}

class FeatureFlags {
  final bool enableLoyaltyProgram;
  final bool enableWishlist;
  final bool enableReviews;
  final bool enableChat;
  final bool enableAR;
  final bool enableSocialLogin;
  final bool enableGuestCheckout;
  final bool enableReferrals;

  FeatureFlags({
    this.enableLoyaltyProgram = true,
    this.enableWishlist = true,
    this.enableReviews = true,
    this.enableChat = false,
    this.enableAR = false,
    this.enableSocialLogin = false,
    this.enableGuestCheckout = true,
    this.enableReferrals = false,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      enableLoyaltyProgram: json['enableLoyaltyProgram'] ?? true,
      enableWishlist: json['enableWishlist'] ?? true,
      enableReviews: json['enableReviews'] ?? true,
      enableChat: json['enableChat'] ?? false,
      enableAR: json['enableAR'] ?? false,
      enableSocialLogin: json['enableSocialLogin'] ?? false,
      enableGuestCheckout: json['enableGuestCheckout'] ?? true,
      enableReferrals: json['enableReferrals'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableLoyaltyProgram': enableLoyaltyProgram,
      'enableWishlist': enableWishlist,
      'enableReviews': enableReviews,
      'enableChat': enableChat,
      'enableAR': enableAR,
      'enableSocialLogin': enableSocialLogin,
      'enableGuestCheckout': enableGuestCheckout,
      'enableReferrals': enableReferrals,
    };
  }

  static FeatureFlags get defaultFlags {
    return FeatureFlags();
  }
}