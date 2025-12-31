import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/ai_creation.dart';

/// Simple storage service for web using SharedPreferences
class StorageServiceWeb {
  static final StorageServiceWeb _instance = StorageServiceWeb._internal();
  factory StorageServiceWeb() => _instance;
  StorageServiceWeb._internal();

  static const String _creationsKey = 'ai_creations';
  static const String _searchHistoryKey = 'search_history';
  static const String _chatHistoryKey = 'chat_history';
  static const String _conversationsKey = 'ai_conversations';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // AI Creations operations
  Future<int> insertCreation(AICreation creation) async {
    try {
      final p = await prefs;
      final creationsJson = p.getString(_creationsKey) ?? '[]';
      final creations = (jsonDecode(creationsJson) as List).cast<Map<String, dynamic>>();

      creations.insert(0, creation.toJson());

      final success = await p.setString(_creationsKey, jsonEncode(creations));
      print('💾 Storage: insertCreation success=$success, total=${creations.length}');

      // Verify write worked
      final verification = p.getString(_creationsKey);
      if (verification == null) {
        print('⚠️ Storage: Write verification FAILED - SharedPreferences may not be working on web');
      }

      return success ? 1 : 0;
    } catch (e) {
      print('❌ Storage: insertCreation error: $e');
      return 0;
    }
  }

  Future<List<AICreation>> getAllCreations({int? limit, int? offset}) async {
    try {
      final p = await prefs;
      final creationsJson = p.getString(_creationsKey) ?? '[]';
      print('💾 Storage: getAllCreations raw data length: ${creationsJson.length}');

      final creations = (jsonDecode(creationsJson) as List).cast<Map<String, dynamic>>();

      // Debug: Log raw JSON values for first few items
      for (var i = 0; i < creations.length && i < 3; i++) {
        final json = creations[i];
        print('💾 Storage: Raw JSON[$i] isSuccessful=${json['isSuccessful']} (type: ${json['isSuccessful'].runtimeType})');
      }

      var result = creations.map((json) => AICreation.fromJson(json)).toList();

      // Deduplicate by ID (keep the first occurrence which is the newest)
      final seen = <String>{};
      result = result.where((creation) {
        if (seen.contains(creation.id)) {
          print('💾 Storage: Removing duplicate ID: ${creation.id}');
          return false;
        }
        seen.add(creation.id);
        return true;
      }).toList();

      if (offset != null && offset > 0) {
        result = result.skip(offset).toList();
      }
      if (limit != null && limit > 0) {
        result = result.take(limit).toList();
      }

      print('💾 Storage: getAllCreations returning ${result.length} items (after dedup)');
      return result;
    } catch (e) {
      print('❌ Storage: getAllCreations error: $e');
      return [];
    }
  }

  /// Cleans up duplicate entries in storage
  Future<void> deduplicateCreations() async {
    try {
      final p = await prefs;
      final creationsJson = p.getString(_creationsKey) ?? '[]';
      final creations = (jsonDecode(creationsJson) as List).cast<Map<String, dynamic>>();

      // Deduplicate by ID
      final seen = <String>{};
      final dedupedCreations = creations.where((json) {
        final id = json['id'] as String;
        if (seen.contains(id)) {
          return false;
        }
        seen.add(id);
        return true;
      }).toList();

      if (dedupedCreations.length < creations.length) {
        print('💾 Storage: Removed ${creations.length - dedupedCreations.length} duplicates');
        await p.setString(_creationsKey, jsonEncode(dedupedCreations));
      }
    } catch (e) {
      print('❌ Storage: deduplicateCreations error: $e');
    }
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

  // Conversation operations
  Future<int> saveConversation(Map<String, dynamic> conversation) async {
    try {
      final p = await prefs;
      final conversationsJson = p.getString(_conversationsKey) ?? '[]';
      final conversations = (jsonDecode(conversationsJson) as List).cast<Map<String, dynamic>>();

      // Find and update existing or add new
      final existingIndex = conversations.indexWhere((c) => c['id'] == conversation['id']);
      if (existingIndex >= 0) {
        conversations[existingIndex] = conversation;
      } else {
        conversations.insert(0, conversation);
      }

      // Keep only last 50 conversations
      if (conversations.length > 50) {
        conversations.removeRange(50, conversations.length);
      }

      await p.setString(_conversationsKey, jsonEncode(conversations));
      print('💾 Storage: saveConversation success, total=${conversations.length}');
      return 1;
    } catch (e) {
      print('❌ Storage: saveConversation error: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getAllConversations() async {
    try {
      final p = await prefs;
      final conversationsJson = p.getString(_conversationsKey) ?? '[]';
      final conversations = (jsonDecode(conversationsJson) as List).cast<Map<String, dynamic>>();
      print('💾 Storage: getAllConversations returning ${conversations.length} items');
      return conversations;
    } catch (e) {
      print('❌ Storage: getAllConversations error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getConversation(String id) async {
    try {
      final conversations = await getAllConversations();
      return conversations.firstWhere((c) => c['id'] == id, orElse: () => <String, dynamic>{});
    } catch (e) {
      return null;
    }
  }

  Future<int> deleteConversation(String id) async {
    try {
      final p = await prefs;
      final conversations = await getAllConversations();
      conversations.removeWhere((c) => c['id'] == id);
      await p.setString(_conversationsKey, jsonEncode(conversations));
      print('💾 Storage: deleteConversation success');
      return 1;
    } catch (e) {
      print('❌ Storage: deleteConversation error: $e');
      return 0;
    }
  }

  Future<int> clearAllConversations() async {
    try {
      final p = await prefs;
      await p.remove(_conversationsKey);
      return 1;
    } catch (e) {
      print('❌ Storage: clearAllConversations error: $e');
      return 0;
    }
  }

  Future<void> close() async {
    // No-op for web
  }
}