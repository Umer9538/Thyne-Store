import 'package:thyne_jewls/models/product.dart';

enum SectionType {
  bannerCarousel('banner_carousel'),
  categories('categories'),
  dealOfDay('deal_of_day'),
  flashSale('flash_sale'),
  bestSellers('best_sellers'),
  featured('featured'),
  newArrivals('new_arrivals'),
  specialOffers('special_offers'),
  brands('brands'),
  recentlyViewed('recently_viewed'),
  upcomingEvents('upcoming_events'),
  customBanner('custom_banner'),
  showcase360('showcase_360'),
  bundleDeals('bundle_deals');

  final String value;
  const SectionType(this.value);

  static SectionType fromString(String value) {
    return SectionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SectionType.customBanner,
    );
  }
}

class HomepageSection {
  final String id;
  final SectionType type;
  final String title;
  final String subtitle;
  final int priority;
  final bool isActive;
  final Map<String, dynamic> config;
  final DateTime? startDate;
  final DateTime? endDate;

  HomepageSection({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle = '',
    required this.priority,
    required this.isActive,
    required this.config,
    this.startDate,
    this.endDate,
  });

  factory HomepageSection.fromJson(Map<String, dynamic> json) {
    return HomepageSection(
      id: json['id'] ?? '',
      type: SectionType.fromString(json['type'] ?? ''),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      priority: json['priority'] ?? 0,
      isActive: json['isActive'] ?? false,
      config: json['config'] ?? {},
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
    );
  }
}

class DealOfDay {
  final String id;
  final String productId;
  final double originalPrice;
  final double dealPrice;
  final int discountPercent;
  final DateTime startTime;
  final DateTime endTime;
  final int stock;
  final int soldCount;
  final bool isActive;

  DealOfDay({
    required this.id,
    required this.productId,
    required this.originalPrice,
    required this.dealPrice,
    required this.discountPercent,
    required this.startTime,
    required this.endTime,
    required this.stock,
    required this.soldCount,
    required this.isActive,
  });

  Duration get timeRemaining => endTime.difference(DateTime.now());

  bool get isLive {
    final now = DateTime.now();
    return isActive &&
           now.isAfter(startTime) &&
           now.isBefore(endTime) &&
           stock > soldCount;
  }

  int get availableStock => stock - soldCount;

  factory DealOfDay.fromJson(Map<String, dynamic> json) {
    return DealOfDay(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      dealPrice: (json['dealPrice'] ?? 0).toDouble(),
      discountPercent: json['discountPercent'] ?? 0,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      stock: json['stock'] ?? 0,
      soldCount: json['soldCount'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}

class FlashSale {
  final String id;
  final String title;
  final String description;
  final String bannerImage;
  final List<String> productIds;
  final DateTime startTime;
  final DateTime endTime;
  final int discount;
  final bool isActive;

  FlashSale({
    required this.id,
    required this.title,
    required this.description,
    required this.bannerImage,
    required this.productIds,
    required this.startTime,
    required this.endTime,
    required this.discount,
    required this.isActive,
  });

  Duration get timeRemaining => endTime.difference(DateTime.now());

  bool get isLive {
    final now = DateTime.now();
    return isActive && now.isAfter(startTime) && now.isBefore(endTime);
  }

  factory FlashSale.fromJson(Map<String, dynamic> json) {
    // Debug: Check what ID is being parsed
    final parsedId = json['id']?.toString() ?? '';
    if (parsedId.isEmpty) {
      print('⚠️ FlashSale.fromJson: ID is empty! JSON keys: ${json.keys.toList()}');
      print('⚠️ FlashSale.fromJson: Raw JSON: $json');
    } else {
      print('✅ FlashSale.fromJson: Parsed ID=$parsedId for title=${json['title']}');
    }

    return FlashSale(
      id: parsedId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      bannerImage: json['bannerImage'] ?? '',
      productIds: List<String>.from(json['productIds'] ?? []),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      discount: json['discount'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}

class Brand {
  final String id;
  final String name;
  final String logo;
  final String description;
  final bool isActive;
  final int priority;

  Brand({
    required this.id,
    required this.name,
    required this.logo,
    required this.description,
    required this.isActive,
    required this.priority,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? false,
      priority: json['priority'] ?? 0,
    );
  }
}

class Showcase360 {
  final String id;
  final String productId;
  final String title;
  final String description;
  final List<String> images360;
  final String videoUrl;
  final String thumbnailUrl;
  final int priority;
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;

  Showcase360({
    required this.id,
    required this.productId,
    required this.title,
    required this.description,
    required this.images360,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.priority,
    required this.isActive,
    this.startTime,
    this.endTime,
  });

  bool get isLive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    return true;
  }

  factory Showcase360.fromJson(Map<String, dynamic> json) {
    return Showcase360(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images360: List<String>.from(json['images360'] ?? []),
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      priority: json['priority'] ?? 0,
      isActive: json['isActive'] ?? false,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
    );
  }
}

class BundleItem {
  final String productId;
  final int quantity;

  BundleItem({
    required this.productId,
    required this.quantity,
  });

  factory BundleItem.fromJson(Map<String, dynamic> json) {
    return BundleItem(
      productId: json['productId'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}

class BundleDeal {
  final String id;
  final String title;
  final String description;
  final String bannerImage;
  final List<BundleItem> items;
  final double originalPrice;
  final double bundlePrice;
  final int discountPercent;
  final String category;
  final int priority;
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;
  final int stock;
  final int soldCount;

  BundleDeal({
    required this.id,
    required this.title,
    required this.description,
    required this.bannerImage,
    required this.items,
    required this.originalPrice,
    required this.bundlePrice,
    required this.discountPercent,
    required this.category,
    required this.priority,
    required this.isActive,
    this.startTime,
    this.endTime,
    required this.stock,
    required this.soldCount,
  });

  bool get isLive {
    if (!isActive) return false;
    if (stock <= soldCount) return false;
    final now = DateTime.now();
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    return true;
  }

  int get availableStock => stock - soldCount;
  double get savings => originalPrice - bundlePrice;

  factory BundleDeal.fromJson(Map<String, dynamic> json) {
    return BundleDeal(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      bannerImage: json['bannerImage'] ?? '',
      items: (json['items'] as List?)
          ?.map((item) => BundleItem.fromJson(item))
          .toList() ?? [],
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      bundlePrice: (json['bundlePrice'] ?? 0).toDouble(),
      discountPercent: json['discountPercent'] ?? 0,
      category: json['category'] ?? '',
      priority: json['priority'] ?? 0,
      isActive: json['isActive'] ?? false,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
      stock: json['stock'] ?? 0,
      soldCount: json['soldCount'] ?? 0,
    );
  }
}

class SectionLayoutItem {
  final SectionType sectionType;
  final int order;
  final bool isVisible;
  final String? title; // Optional custom title override

  SectionLayoutItem({
    required this.sectionType,
    required this.order,
    required this.isVisible,
    this.title,
  });

  factory SectionLayoutItem.fromJson(Map<String, dynamic> json) {
    return SectionLayoutItem(
      sectionType: SectionType.fromString(json['sectionType'] ?? ''),
      order: json['order'] ?? 0,
      isVisible: json['isVisible'] ?? true,
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionType': sectionType.value,
      'order': order,
      'isVisible': isVisible,
      if (title != null) 'title': title,
    };
  }
}

class HomepageData {
  final List<SectionLayoutItem> layout;
  final List<HomepageSection> sections;
  final DealOfDay? dealOfDay;
  final List<FlashSale> activeFlashSales;
  final List<Brand> brands;
  final List<Product> recentlyViewed;
  final List<Showcase360> showcases360;
  final List<BundleDeal> bundleDeals;

  HomepageData({
    this.layout = const [],
    required this.sections,
    this.dealOfDay,
    this.activeFlashSales = const [],
    this.brands = const [],
    this.recentlyViewed = const [],
    this.showcases360 = const [],
    this.bundleDeals = const [],
  });

  factory HomepageData.fromJson(Map<String, dynamic> json) {
    return HomepageData(
      layout: (json['layout'] as List?)
          ?.map((item) => SectionLayoutItem.fromJson(item))
          .toList() ?? [],
      sections: (json['sections'] as List?)
          ?.map((section) => HomepageSection.fromJson(section))
          .toList() ?? [],
      dealOfDay: json['dealOfDay'] != null
          ? DealOfDay.fromJson(json['dealOfDay'])
          : null,
      activeFlashSales: (json['activeFlashSales'] as List?)
          ?.map((sale) => FlashSale.fromJson(sale))
          .toList() ?? [],
      brands: (json['brands'] as List?)
          ?.map((brand) => Brand.fromJson(brand))
          .toList() ?? [],
      recentlyViewed: (json['recentlyViewed'] as List?)
          ?.map((product) => Product.fromJson(product))
          .toList() ?? [],
      showcases360: (json['showcases360'] as List?)
          ?.map((showcase) => Showcase360.fromJson(showcase))
          .toList() ?? [],
      bundleDeals: (json['bundleDeals'] as List?)
          ?.map((bundle) => BundleDeal.fromJson(bundle))
          .toList() ?? [],
    );
  }
}
