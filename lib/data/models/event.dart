class Event {
  final String id;
  final String name;
  final String type; // 'festival', 'sale', 'promotion', 'holiday'
  final DateTime date;
  final String? description;
  final String? themeColor;
  final String? iconUrl;
  final bool isRecurring; // Annual events like Diwali
  final List<String> suggestedCategories;
  final String? bannerTemplate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    this.description,
    this.themeColor,
    this.iconUrl,
    this.isRecurring = false,
    this.suggestedCategories = const [],
    this.bannerTemplate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'festival',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      description: json['description'],
      themeColor: json['themeColor'],
      iconUrl: json['iconUrl'],
      isRecurring: json['isRecurring'] ?? false,
      suggestedCategories: json['suggestedCategories'] != null
          ? List<String>.from(json['suggestedCategories'])
          : [],
      bannerTemplate: json['bannerTemplate'],
      isActive: json['isActive'] ?? true,
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
      'name': name,
      'type': type,
      'date': date.toIso8601String(),
      'description': description,
      'themeColor': themeColor,
      'iconUrl': iconUrl,
      'isRecurring': isRecurring,
      'suggestedCategories': suggestedCategories,
      'bannerTemplate': bannerTemplate,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isUpcoming {
    return DateTime.now().isBefore(date);
  }

  bool get isToday {
    final now = DateTime.now();
    return now.year == date.year &&
           now.month == date.month &&
           now.day == date.day;
  }

  int get daysUntil {
    return date.difference(DateTime.now()).inDays;
  }
}
