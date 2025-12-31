import 'ai_creation.dart';
import 'product.dart';

/// Represents a single message in a conversation
class ConversationMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Product>? products;
  final String? imageUrl;
  final String? imageDescription;
  final PriceEstimate? priceEstimate;
  final MessageType type;

  ConversationMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.products,
    this.imageUrl,
    this.imageDescription,
    this.priceEstimate,
    this.type = MessageType.text,
  });

  bool get hasProducts => products != null && products!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasPriceEstimate => priceEstimate != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'products': products?.map((p) => p.toJson()).toList(),
      'imageUrl': imageUrl,
      'imageDescription': imageDescription,
      'priceEstimate': priceEstimate?.toJson(),
      'type': type.name,
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      products: (json['products'] as List?)?.map((p) => Product.fromJson(p)).toList(),
      imageUrl: json['imageUrl'],
      imageDescription: json['imageDescription'],
      priceEstimate: json['priceEstimate'] != null
          ? PriceEstimate.fromJson(json['priceEstimate'])
          : null,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
}

/// Type of message in conversation
enum MessageType {
  text,        // Regular text message
  image,       // Generated image response
  products,    // Product recommendations
  error,       // Error message
  system,      // System message (e.g., welcome)
}

/// Represents a complete conversation session
class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationMessage> messages;
  final ConversationStatus status;
  final String? userId;
  final AICreation? linkedCreation;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    DateTime? updatedAt,
    List<ConversationMessage>? messages,
    this.status = ConversationStatus.active,
    this.userId,
    this.linkedCreation,
  }) : updatedAt = updatedAt ?? createdAt,
       messages = messages ?? [];

  /// Create a new conversation with initial welcome message
  factory Conversation.newConversation({String? userId}) {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();

    return Conversation(
      id: id,
      title: 'New Conversation',
      createdAt: now,
      updatedAt: now,
      userId: userId,
      messages: [
        ConversationMessage(
          id: '${id}_welcome',
          text: 'Hello! I\'m your AI jewelry assistant. Describe your dream jewelry and I\'ll design it, or ask me to find products from our collection.',
          isUser: false,
          timestamp: now,
          type: MessageType.system,
        ),
      ],
    );
  }

  /// Add a message to the conversation
  Conversation addMessage(ConversationMessage message) {
    final updatedMessages = List<ConversationMessage>.from(messages)..add(message);

    // Auto-generate title from first user message if still default
    String newTitle = title;
    if (title == 'New Conversation' && message.isUser) {
      newTitle = message.text.length > 40
          ? '${message.text.substring(0, 40)}...'
          : message.text;
    }

    return Conversation(
      id: id,
      title: newTitle,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      messages: updatedMessages,
      status: status,
      userId: userId,
      linkedCreation: message.hasImage ? linkedCreation : linkedCreation,
    );
  }

  /// Get the last message
  ConversationMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Get total message count (excluding system messages)
  int get messageCount => messages.where((m) => m.type != MessageType.system).length;

  /// Check if conversation has any generated images
  bool get hasGeneratedImages => messages.any((m) => m.hasImage);

  /// Get all generated images from this conversation
  List<ConversationMessage> get generatedImages =>
      messages.where((m) => m.hasImage).toList();

  /// Get preview text for conversation list
  String get previewText {
    final nonSystemMessages = messages.where((m) => m.type != MessageType.system).toList();
    if (nonSystemMessages.isEmpty) return 'Start a new design conversation';
    return nonSystemMessages.last.text.length > 60
        ? '${nonSystemMessages.last.text.substring(0, 60)}...'
        : nonSystemMessages.last.text;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'status': status.name,
      'userId': userId,
      'linkedCreation': linkedCreation?.toJson(),
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Conversation',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      messages: (json['messages'] as List?)
          ?.map((m) => ConversationMessage.fromJson(m))
          .toList() ?? [],
      status: ConversationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConversationStatus.active,
      ),
      userId: json['userId'],
      linkedCreation: json['linkedCreation'] != null
          ? AICreation.fromJson(json['linkedCreation'])
          : null,
    );
  }

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ConversationMessage>? messages,
    ConversationStatus? status,
    String? userId,
    AICreation? linkedCreation,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      linkedCreation: linkedCreation ?? this.linkedCreation,
    );
  }
}

/// Status of a conversation
enum ConversationStatus {
  active,     // Currently active conversation
  completed,  // Conversation ended
  archived,   // Archived by user
}

/// Extension for PriceEstimate to add toJson
extension PriceEstimateJson on PriceEstimate {
  Map<String, dynamic> toJson() {
    return {
      'jewelryType': jewelryType,
      'metalType': metalType,
      'estimatedWeight': estimatedWeight,
      'metalPrice': metalPrice,
      'basePrice': basePrice,
      'makingCharges': makingCharges,
      'customBuildFee': customBuildFee,
      'stoneEstimate': stoneEstimate,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'currency': currency,
      'priceBreakdown': priceBreakdown,
    };
  }
}
