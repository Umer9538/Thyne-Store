import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_creation.dart';

/// Simple storage service for web using SharedPreferences
class StorageServiceWeb {
  static final StorageServiceWeb _instance = StorageServiceWeb._internal();
  factory StorageServiceWeb() => _instance;
  StorageServiceWeb._internal();

  static const String _creationsKey = 'ai_creations';
  static const String _searchHistoryKey = 'search_history';
  static const String _chatHistoryKey = 'chat_history';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // AI Creations operations
  Future<int> insertCreation(AICreation creation) async {
    final p = await prefs;
    final creationsJson = p.getString(_creationsKey) ?? '[]';
    final creations = (jsonDecode(creationsJson) as List).cast<Map<String, dynamic>>();

    creations.insert(0, creation.toJson());

    await p.setString(_creationsKey, jsonEncode(creations));
    return 1;
  }

  Future<List<AICreation>> getAllCreations({int? limit, int? offset}) async {
    final p = await prefs;
    final creationsJson = p.getString(_creationsKey) ?? '[]';
    final creations = (jsonDecode(creationsJson) as List).cast<Map<String, dynamic>>();

    var result = creations.map((json) => AICreation.fromJson(json)).toList();

    if (offset != null && offset > 0) {
      result = result.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      result = result.take(limit).toList();
    }

    return result;
  }

  Future<List<AICreation>> getSuccessfulCreations({int? limit}) async {
    final allCreations = await getAllCreations();
    var result = allCreations.where((c) => c.isSuccessful).toList();

    if (limit != null && limit > 0) {
      result = result.take(limit).toList();
    }

    return result;
  }

  Future<AICreation?> getCreation(String id) async {
    final creations = await getAllCreations();
    try {
      return creations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> deleteCreation(String id) async {
    final p = await prefs;
    final creations = await getAllCreations();
    creations.removeWhere((c) => c.id == id);

    final creationsJson = creations.map((c) => c.toJson()).toList();
    await p.setString(_creationsKey, jsonEncode(creationsJson));
    return 1;
  }

  Future<int> clearAllCreations() async {
    final p = await prefs;
    await p.remove(_creationsKey);
    return 1;
  }

  // Search history operations
  Future<int> addSearchHistory(String prompt) async {
    final p = await prefs;
    final historyJson = p.getString(_searchHistoryKey) ?? '[]';
    final history = (jsonDecode(historyJson) as List).cast<String>();

    if (!history.contains(prompt)) {
      history.insert(0, prompt);
      if (history.length > 20) {
        history.removeLast();
      }
      await p.setString(_searchHistoryKey, jsonEncode(history));
    }
    return 1;
  }

  Future<List<String>> getRecentSearches({int limit = 10}) async {
    final p = await prefs;
    final historyJson = p.getString(_searchHistoryKey) ?? '[]';
    final history = (jsonDecode(historyJson) as List).cast<String>();

    return history.take(limit).toList();
  }

  Future<int> clearSearchHistory() async {
    final p = await prefs;
    await p.remove(_searchHistoryKey);
    return 1;
  }

  // Chat history operations
  Future<int> addChatMessage({
    required String message,
    required bool isUser,
  }) async {
    final p = await prefs;
    final chatJson = p.getString(_chatHistoryKey) ?? '[]';
    final chatHistory = (jsonDecode(chatJson) as List).cast<Map<String, dynamic>>();

    chatHistory.add({
      'message': message,
      'isUser': isUser ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 messages
    if (chatHistory.length > 100) {
      chatHistory.removeAt(0);
    }

    await p.setString(_chatHistoryKey, jsonEncode(chatHistory));
    return 1;
  }

  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    final p = await prefs;
    final chatJson = p.getString(_chatHistoryKey) ?? '[]';
    final chatHistory = (jsonDecode(chatJson) as List).cast<Map<String, dynamic>>();

    var result = chatHistory.reversed.toList();
    if (limit > 0 && result.length > limit) {
      result = result.take(limit).toList();
    }

    return result;
  }

  Future<int> clearChatHistory() async {
    final p = await prefs;
    await p.remove(_chatHistoryKey);
    return 1;
  }

  // Statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final creations = await getAllCreations();
    final searches = await getRecentSearches(limit: 100);

    final totalCreations = creations.length;
    final successfulCreations = creations.where((c) => c.isSuccessful).length;

    return {
      'totalCreations': totalCreations,
      'successfulCreations': successfulCreations,
      'failedCreations': totalCreations - successfulCreations,
      'totalSearches': searches.length,
      'successRate': totalCreations > 0
          ? (successfulCreations / totalCreations * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  Future<void> close() async {
    // No-op for web
  }
}