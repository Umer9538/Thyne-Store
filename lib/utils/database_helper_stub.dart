import '../data/models/ai_creation.dart';

/// Stub implementation for conditional imports
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<dynamic> get database async => null;
  Future<int> insertCreation(AICreation creation) async => 0;
  Future<List<AICreation>> getAllCreations({int? limit, int? offset}) async => [];
  Future<List<AICreation>> getSuccessfulCreations({int? limit}) async => [];
  Future<AICreation?> getCreation(String id) async => null;
  Future<int> deleteCreation(String id) async => 0;
  Future<int> clearAllCreations() async => 0;
  Future<int> addSearchHistory(String prompt) async => 0;
  Future<List<String>> getRecentSearches({int limit = 10}) async => [];
  Future<int> clearSearchHistory() async => 0;
  Future<int> addChatMessage({required String message, required bool isUser}) async => 0;
  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async => [];
  Future<int> clearChatHistory() async => 0;
  Future<Map<String, dynamic>> getStatistics() async => {
    'totalCreations': 0,
    'successfulCreations': 0,
    'failedCreations': 0,
    'totalSearches': 0,
    'successRate': '0.0',
  };
  Future<void> close() async {}
}