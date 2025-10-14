class Banner {
  final String id;
  final String title;
  final String imageUrl;
  final String? description;
  final String type; // 'main', 'promotional', 'festival', 'flash_sale'
  final String? targetUrl;
  final String? targetProductId;
  final String? targetCategory;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final int priority; // Higher number = higher priority
  final String? festivalTag; // 'diwali', 'christmas', 'valentine', etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  Banner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description,
    required this.type,
    this.targetUrl,
    this.targetProductId,
    this.targetCategory,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.priority = 0,
    this.festivalTag,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'main',
      targetUrl: json['targetUrl'],
      targetProductId: json['targetProductId'],
      targetCategory: json['targetCategory'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      isActive: json['isActive'] ?? true,
      priority: json['priority'] ?? 0,
      festivalTag: json['festivalTag'],
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
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'type': type,
      'targetUrl': targetUrl,
      'targetProductId': targetProductId,
      'targetCategory': targetCategory,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'priority': priority,
      'festivalTag': festivalTag,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isScheduled {
    final now = DateTime.now();
    return startDate.isAfter(now);
  }

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  bool get isLive {
    final now = DateTime.now();
    return isActive &&
           now.isAfter(startDate) &&
           (endDate == null || now.isBefore(endDate!));
  }
}
