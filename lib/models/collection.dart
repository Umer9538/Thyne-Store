/// Collection model representing curated product collections
class Collection {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final List<String> imageUrls;
  final int itemCount;
  final List<String> tags;
  final bool isFeatured;
  final int priority;

  Collection({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.imageUrls = const [],
    this.itemCount = 0,
    this.tags = const [],
    this.isFeatured = false,
    this.priority = 0,
  });

  /// Create Collection from JSON (API response)
  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      itemCount: json['itemCount'] as int? ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isFeatured: json['isFeatured'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
    );
  }

  /// Convert Collection to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrls': imageUrls,
      'itemCount': itemCount,
      'tags': tags,
      'isFeatured': isFeatured,
      'priority': priority,
    };
  }

  /// Get the primary image URL (first image or placeholder)
  String get primaryImageUrl {
    if (imageUrls.isNotEmpty) {
      return imageUrls.first;
    }
    // Return a placeholder image
    return 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800';
  }

  /// Get formatted item count string
  String get itemCountLabel {
    if (itemCount == 1) {
      return '1 Item';
    }
    return '$itemCount Items';
  }

  @override
  String toString() {
    return 'Collection(id: $id, title: $title, itemCount: $itemCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Collection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
