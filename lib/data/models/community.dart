// Moderation status enum for community posts
enum ModerationStatus {
  pending,
  approved,
  rejected;

  static ModerationStatus fromString(String? status) {
    switch (status) {
      case 'approved':
        return ModerationStatus.approved;
      case 'rejected':
        return ModerationStatus.rejected;
      case 'pending':
      default:
        return ModerationStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case ModerationStatus.pending:
        return 'Pending';
      case ModerationStatus.approved:
        return 'Approved';
      case ModerationStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Customization options selected for a tagged product
class ProductCustomizationTag {
  final String? selectedMetal;           // e.g., "14K Gold"
  final String? selectedPlating;         // e.g., "Rose Gold"
  final Map<String, String>? stoneColors; // e.g., {"center": "Blue", "side": "White"}
  final String? selectedSize;            // e.g., "7" for ring size
  final String? engravingText;           // e.g., "Forever Yours"
  final double? thickness;               // e.g., 2.5mm

  ProductCustomizationTag({
    this.selectedMetal,
    this.selectedPlating,
    this.stoneColors,
    this.selectedSize,
    this.engravingText,
    this.thickness,
  });

  factory ProductCustomizationTag.fromJson(Map<String, dynamic> json) {
    return ProductCustomizationTag(
      selectedMetal: json['selectedMetal']?.toString(),
      selectedPlating: json['selectedPlating']?.toString(),
      stoneColors: json['stoneColors'] != null
          ? Map<String, String>.from(json['stoneColors'])
          : null,
      selectedSize: json['selectedSize']?.toString(),
      engravingText: json['engravingText']?.toString(),
      thickness: (json['thickness'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (selectedMetal != null) 'selectedMetal': selectedMetal,
    if (selectedPlating != null) 'selectedPlating': selectedPlating,
    if (stoneColors != null) 'stoneColors': stoneColors,
    if (selectedSize != null) 'selectedSize': selectedSize,
    if (engravingText != null) 'engravingText': engravingText,
    if (thickness != null) 'thickness': thickness,
  };

  bool get hasCustomizations =>
      selectedMetal != null ||
      selectedPlating != null ||
      (stoneColors != null && stoneColors!.isNotEmpty) ||
      selectedSize != null ||
      engravingText != null ||
      thickness != null;

  /// Get a summary string of customizations for display
  String get summary {
    final parts = <String>[];
    if (selectedMetal != null) parts.add(selectedMetal!);
    if (selectedPlating != null) parts.add('$selectedPlating plating');
    if (selectedSize != null) parts.add('Size $selectedSize');
    if (engravingText != null) parts.add('Engraved');
    return parts.join(' • ');
  }
}

// Product tag for posts - enhanced with customization support
class ProductTag {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final ProductCustomizationTag? customization; // Customization details
  final String? orderId; // If tagged from an order
  final String? orderNumber; // Order number for display

  ProductTag({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.customization,
    this.orderId,
    this.orderNumber,
  });

  factory ProductTag.fromJson(Map<String, dynamic> json) {
    return ProductTag(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      customization: json['customization'] != null
          ? ProductCustomizationTag.fromJson(json['customization'])
          : null,
      orderId: json['orderId']?.toString(),
      orderNumber: json['orderNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'imageUrl': imageUrl,
    if (customization != null) 'customization': customization!.toJson(),
    if (orderId != null) 'orderId': orderId,
    if (orderNumber != null) 'orderNumber': orderNumber,
  };

  /// Whether this product was tagged from an order (has customizations)
  bool get isFromOrder => orderId != null;
}

/// Order tag for community posts - references an entire order
class OrderTag {
  final String orderId;
  final String orderNumber;
  final DateTime orderDate;
  final double orderTotal;
  final List<ProductTag> products; // Individual products from the order

  OrderTag({
    required this.orderId,
    required this.orderNumber,
    required this.orderDate,
    required this.orderTotal,
    required this.products,
  });

  factory OrderTag.fromJson(Map<String, dynamic> json) {
    return OrderTag(
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      orderDate: json['orderDate'] != null
          ? DateTime.parse(json['orderDate'])
          : DateTime.now(),
      orderTotal: (json['orderTotal'] ?? 0.0).toDouble(),
      products: (json['products'] as List<dynamic>?)
              ?.map((p) => ProductTag.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'orderNumber': orderNumber,
    'orderDate': orderDate.toIso8601String(),
    'orderTotal': orderTotal,
    'products': products.map((p) => p.toJson()).toList(),
  };
}

/// Type of source for tagged products in a post
enum PostTagSource {
  product,  // Direct product selection from catalog
  order,    // Product selected from user's order history
}

extension PostTagSourceExtension on PostTagSource {
  String get displayName {
    switch (this) {
      case PostTagSource.product:
        return 'Product';
      case PostTagSource.order:
        return 'My Order';
    }
  }
}

class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final List<String> images;
  final List<String> videos;
  final int likeCount;
  final int voteCount;
  final int commentCount;
  final List<String> tags;
  final List<ProductTag>? products;
  final OrderTag? order; // Order tag (if post is about an order)
  final PostTagSource? tagSource; // Source of the tagged product/order
  final bool isAdminPost;
  final bool isFeatured;
  final bool isPinned;
  // Moderation fields
  final ModerationStatus moderationStatus;
  final String? rejectionReason;
  final String? moderatedBy;
  final DateTime? moderatedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.images = const [],
    this.videos = const [],
    this.likeCount = 0,
    this.voteCount = 0,
    this.commentCount = 0,
    this.tags = const [],
    this.products,
    this.order,
    this.tagSource,
    this.isAdminPost = false,
    this.isFeatured = false,
    this.isPinned = false,
    this.moderationStatus = ModerationStatus.pending,
    this.rejectionReason,
    this.moderatedBy,
    this.moderatedAt,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if this post has a product or order tagged
  bool get hasTaggedItem => (products != null && products!.isNotEmpty) || order != null;

  /// Get all tagged products (either direct products or from order)
  List<ProductTag> get allTaggedProducts {
    if (order != null) {
      return order!.products;
    }
    return products ?? [];
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    PostTagSource? tagSource;
    if (json['tagSource'] != null) {
      final sourceStr = json['tagSource'].toString().toLowerCase();
      tagSource = sourceStr == 'order' ? PostTagSource.order : PostTagSource.product;
    }

    return CommunityPost(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userAvatar: json['userAvatar']?.toString(),
      content: json['content']?.toString() ?? '',
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      likeCount: json['likeCount'] ?? 0,
      voteCount: json['voteCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      products: (json['products'] as List<dynamic>?)
          ?.map((p) => ProductTag.fromJson(p as Map<String, dynamic>))
          .toList(),
      order: json['order'] != null
          ? OrderTag.fromJson(json['order'] as Map<String, dynamic>)
          : null,
      tagSource: tagSource,
      isAdminPost: json['isAdminPost'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      isPinned: json['isPinned'] ?? false,
      moderationStatus: ModerationStatus.fromString(json['moderationStatus']?.toString()),
      rejectionReason: json['rejectionReason']?.toString(),
      moderatedBy: json['moderatedBy']?.toString(),
      moderatedAt: json['moderatedAt'] != null
          ? DateTime.parse(json['moderatedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'images': images,
      'videos': videos,
      'likeCount': likeCount,
      'voteCount': voteCount,
      'commentCount': commentCount,
      'tags': tags,
      if (products != null) 'products': products!.map((p) => p.toJson()).toList(),
      if (order != null) 'order': order!.toJson(),
      if (tagSource != null) 'tagSource': tagSource!.name,
      'isAdminPost': isAdminPost,
      'isFeatured': isFeatured,
      'isPinned': isPinned,
      'moderationStatus': moderationStatus.name,
      'rejectionReason': rejectionReason,
      'moderatedBy': moderatedBy,
      'moderatedAt': moderatedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.likeCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userAvatar: json['userAvatar']?.toString(),
      content: json['content']?.toString() ?? '',
      likeCount: json['likeCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'likeCount': likeCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PostEngagement {
  final String postId;
  final int likeCount;
  final int voteCount;
  final int commentCount;
  final bool userLiked;
  final String userVoted; // "up", "down", or ""

  PostEngagement({
    required this.postId,
    this.likeCount = 0,
    this.voteCount = 0,
    this.commentCount = 0,
    this.userLiked = false,
    this.userVoted = '',
  });

  factory PostEngagement.fromJson(Map<String, dynamic> json) {
    return PostEngagement(
      postId: json['postId']?.toString() ?? '',
      likeCount: json['likeCount'] ?? 0,
      voteCount: json['voteCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      userLiked: json['userLiked'] ?? false,
      userVoted: json['userVoted']?.toString() ?? '',
    );
  }
}

class InstagramProfile {
  final String id;
  final String userId;
  final String instagramId;
  final String username;
  final String? displayName;
  final String? profilePicUrl;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final bool isVerified;
  final bool isActive;
  final DateTime linkedAt;
  final DateTime updatedAt;

  InstagramProfile({
    required this.id,
    required this.userId,
    required this.instagramId,
    required this.username,
    this.displayName,
    this.profilePicUrl,
    this.bio,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.isVerified = false,
    this.isActive = true,
    required this.linkedAt,
    required this.updatedAt,
  });

  factory InstagramProfile.fromJson(Map<String, dynamic> json) {
    return InstagramProfile(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      instagramId: json['instagramId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      profilePicUrl: json['profilePicUrl']?.toString(),
      bio: json['bio']?.toString(),
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postCount: json['postCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      linkedAt: json['linkedAt'] != null
          ? DateTime.parse(json['linkedAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'instagramId': instagramId,
      'username': username,
      'displayName': displayName,
      'profilePicUrl': profilePicUrl,
      'bio': bio,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'postCount': postCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'linkedAt': linkedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CommunityFeedResponse {
  final List<CommunityPost> posts;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  CommunityFeedResponse({
    required this.posts,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory CommunityFeedResponse.fromJson(Map<String, dynamic> json) {
    return CommunityFeedResponse(
      posts: (json['posts'] as List<dynamic>?)
              ?.map((post) => CommunityPost.fromJson(post as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

// Moderation statistics for admin dashboard
class ModerationStats {
  final int pending;
  final int approved;
  final int rejected;
  final int total;

  ModerationStats({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.total,
  });

  factory ModerationStats.fromJson(Map<String, dynamic> json) {
    return ModerationStats(
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}
