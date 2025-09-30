class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final List<String> images;
  final String? videoUrl;
  final String category;
  final String subcategory;
  final String metalType;
  final String? stoneType;
  final double? weight;
  final String? size;
  final int stockQuantity;
  final int stock;
  final double rating;
  final int reviewCount;
  final int ratingCount;
  final List<String> tags;
  final bool isAvailable;
  final bool isFeatured;
  final bool isNewArrival;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.images,
    this.videoUrl,
    required this.category,
    required this.subcategory,
    required this.metalType,
    this.stoneType,
    this.weight,
    this.size,
    required this.stockQuantity,
    int? stock,
    this.rating = 0.0,
    this.reviewCount = 0,
    int? ratingCount,
    this.tags = const [],
    this.isAvailable = true,
    this.isFeatured = false,
    DateTime? createdAt,
    bool? isNewArrival,
  }) : stock = stock ?? stockQuantity,
       ratingCount = ratingCount ?? reviewCount,
       createdAt = createdAt ?? DateTime.now(),
       isNewArrival = isNewArrival ?? false;

  double get discount {
    if (originalPrice != null && originalPrice! > price) {
      return ((originalPrice! - price) / originalPrice! * 100);
    }
    return 0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      images: List<String>.from(json['images']),
      videoUrl: json['videoUrl'],
      category: json['category'],
      subcategory: json['subcategory'],
      metalType: json['metalType'],
      stoneType: json['stoneType'],
      weight: json['weight']?.toDouble(),
      size: json['size'],
      stockQuantity: json['stockQuantity'],
      rating: json['rating']?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'images': images,
      'videoUrl': videoUrl,
      'category': category,
      'subcategory': subcategory,
      'metalType': metalType,
      'stoneType': stoneType,
      'weight': weight,
      'size': size,
      'stockQuantity': stockQuantity,
      'rating': rating,
      'reviewCount': reviewCount,
      'tags': tags,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Review {
  final String id;
  final String userId;
  final String userName;
  final String productId;
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.productId,
    required this.rating,
    required this.comment,
    this.images = const [],
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      productId: json['productId'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}