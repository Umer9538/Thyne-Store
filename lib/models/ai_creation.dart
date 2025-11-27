class AICreation {
  final String id;
  final String prompt;
  final String imageUrl;
  final DateTime createdAt;
  final bool isSuccessful;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  AICreation({
    required this.id,
    required this.prompt,
    required this.imageUrl,
    required this.createdAt,
    this.isSuccessful = true,
    this.errorMessage,
    this.metadata,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isSuccessful': isSuccessful,
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  // Create from JSON
  factory AICreation.fromJson(Map<String, dynamic> json) {
    return AICreation(
      id: json['id'],
      prompt: json['prompt'],
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      isSuccessful: json['isSuccessful'] ?? true,
      errorMessage: json['errorMessage'],
      metadata: json['metadata'],
    );
  }

  // Create a copy with modified fields
  AICreation copyWith({
    String? id,
    String? prompt,
    String? imageUrl,
    DateTime? createdAt,
    bool? isSuccessful,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return AICreation(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }
}