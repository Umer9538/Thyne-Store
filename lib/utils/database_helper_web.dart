import '../models/ai_creation.dart';

/// Web implementation of DatabaseHelper using in-memory storage
/// Since sqflite doesn't work on web, we use a simple in-memory storage
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // In-memory storage for web
  final List<AICreation> _creations = [];
  final List<String> _searchHistory = [];
  final List<Map<String, dynamic>> _chatHistory = [];

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // Fake database getter for compatibility
  Future<dynamic> get database async => null;

  // AI Creations operations
  Future<int> insertCreation(AICreation creation) async {
    _creations.insert(0, creation);
    return 1;
  }

  Future<List<AICreation>> getAllCreations({int? limit, int? offset}) async {
    var result = _creations;
    if (offset != null && offset > 0) {
      result = result.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      result = result.take(limit).toList();
    }
    return result;
  }

  Future<List<AICreation>> getSuccessfulCreations({int? limit}) async {
    var result = _creations.where((c) => c.isSuccessful).toList();
    if (limit != null && limit > 0) {
      result = result.take(limit).toList();
    }
    return result;
  }

  Future<AICreation?> getCreation(String id) async {
    try {
      return _creations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> deleteCreation(String id) async {
    _creations.removeWhere((c) => c.id == id);
    return 1;
  }

  Future<int> clearAllCreations() async {
    _creations.clear();
    return 1;
  }

  // Search history operations
  Future<int> addSearchHistory(String prompt) async {
    if (!_searchHistory.contains(prompt)) {
      _searchHistory.insert(0, prompt);
      if (_searchHistory.length > 20) {
        _searchHistory.removeLast();
      }
    }
    return 1;
  }

  Future<List<String>> getRecentSearches({int limit = 10}) async {
    return _searchHistory.take(limit).toList();
  }

  Future<int> clearSearchHistory() async {
    _searchHistory.clear();
    return 1;
  }

  // Chat history operations
  Future<int> addChatMessage({
    required String message,
    required bool isUser,
  }) async {
    _chatHistory.add({
      'message': message,
      'isUser': isUser ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    });
    return 1;
  }

  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    var result = _chatHistory.reversed.toList();
    if (limit > 0 && result.length > limit) {
      result = result.take(limit).toList();
    }
    return result;
  }

  Future<int> clearChatHistory() async {
    _chatHistory.clear();
    return 1;
  }

  // Statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final totalCreations = _creations.length;
    final successfulCreations = _creations.where((c) => c.isSuccessful).length;
    final totalSearches = _searchHistory.length;

    return {
      'totalCreations': totalCreations,
      'successfulCreations': successfulCreations,
      'failedCreations': totalCreations - successfulCreations,
      'totalSearches': totalSearches,
      'successRate': totalCreations > 0
          ? (successfulCreations / totalCreations * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  // Close database (no-op for web)
  Future<void> close() async {
    // No-op for web
  }
}