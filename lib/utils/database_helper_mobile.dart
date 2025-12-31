import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/models/ai_creation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'thyne_ai_creations.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create AI creations table
    await db.execute('''
      CREATE TABLE creations (
        id TEXT PRIMARY KEY,
        prompt TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isSuccessful INTEGER DEFAULT 1,
        errorMessage TEXT,
        metadata TEXT
      )
    ''');

    // Create chat history table
    await db.execute('''
      CREATE TABLE chat_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        isUser INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Create search history table
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prompt TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        UNIQUE(prompt)
      )
    ''');
  }

  // AI Creations operations
  Future<int> insertCreation(AICreation creation) async {
    final db = await database;
    return await db.insert(
      'creations',
      creation.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AICreation>> getAllCreations({int? limit, int? offset}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'creations',
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      return AICreation.fromJson(maps[i]);
    });
  }

  Future<List<AICreation>> getSuccessfulCreations({int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'creations',
      where: 'isSuccessful = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return AICreation.fromJson(maps[i]);
    });
  }

  Future<AICreation?> getCreation(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'creations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AICreation.fromJson(maps.first);
    }
    return null;
  }

  Future<int> deleteCreation(String id) async {
    final db = await database;
    return await db.delete(
      'creations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllCreations() async {
    final db = await database;
    return await db.delete('creations');
  }

  // Search history operations
  Future<int> addSearchHistory(String prompt) async {
    final db = await database;
    return await db.insert(
      'search_history',
      {
        'prompt': prompt,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getRecentSearches({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'search_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => map['prompt'] as String).toList();
  }

  Future<int> clearSearchHistory() async {
    final db = await database;
    return await db.delete('search_history');
  }

  // Chat history operations
  Future<int> addChatMessage({
    required String message,
    required bool isUser,
  }) async {
    final db = await database;
    return await db.insert(
      'chat_history',
      {
        'message': message,
        'isUser': isUser ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    final db = await database;
    return await db.query(
      'chat_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  Future<int> clearChatHistory() async {
    final db = await database;
    return await db.delete('chat_history');
  }

  // Statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    final totalCreations = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM creations'),
    ) ?? 0;

    final successfulCreations = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM creations WHERE isSuccessful = 1'),
    ) ?? 0;

    final totalSearches = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM search_history'),
    ) ?? 0;

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

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}