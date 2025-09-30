import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

// Import for web/desktop support
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _isInitialized = false;

  DatabaseHelper._init();

  static Future<void> initializeDatabaseFactory() async {
    if (_isInitialized) return;
    
    if (kIsWeb) {
      // For web, we'll use a different storage strategy
      // Web doesn't support SQLite, so we'll use browser storage instead
      _isInitialized = true;
      return;
    }
    
    // For desktop platforms (Windows, Linux, macOS when not mobile)
    if (Platform.isWindows || Platform.isLinux || (Platform.isMacOS && !kIsWeb)) {
      // Initialize FFI for desktop
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _isInitialized = true;
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web. Use browser storage instead.');
    }
    
    await initializeDatabaseFactory();
    
    if (_database != null) return _database!;
    _database = await _initDB('thyne_jewels.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        email $textType UNIQUE,
        password $textType,
        phone $textType,
        profileImage $textTypeNullable,
        createdAt $textType,
        isAdmin $integerType DEFAULT 0
      )
    ''');

    // Create products table for local storage
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        description $textType,
        price REAL NOT NULL,
        category $textType,
        subcategory $textTypeNullable,
        images $textType,
        metalType $textTypeNullable,
        stoneType $textTypeNullable,
        weight REAL,
        tags $textTypeNullable,
        rating REAL DEFAULT 0,
        ratingCount $integerType DEFAULT 0,
        stock $integerType DEFAULT 0,
        videoUrl $textTypeNullable,
        createdAt $textType
      )
    ''');

    // Create cart table
    await db.execute('''
      CREATE TABLE cart (
        id $idType,
        userId $integerType,
        productId $integerType,
        quantity $integerType DEFAULT 1,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // Create orders table
    await db.execute('''
      CREATE TABLE orders (
        id $idType,
        userId $integerType,
        items $textType,
        totalAmount REAL NOT NULL,
        shippingAddress $textType,
        paymentMethod $textType,
        status $textType DEFAULT 'pending',
        createdAt $textType,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create loyalty programs table
    await db.execute('''
      CREATE TABLE loyalty_programs (
        id $idType,
        userId $integerType UNIQUE,
        totalPoints $integerType DEFAULT 0,
        currentPoints $integerType DEFAULT 0,
        tier $textType DEFAULT 'bronze',
        loginStreak $integerType DEFAULT 0,
        lastLoginDate $textTypeNullable,
        totalSpent REAL DEFAULT 0,
        totalOrders $integerType DEFAULT 0,
        joinedAt $textType,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create point transactions table
    await db.execute('''
      CREATE TABLE point_transactions (
        id $textType PRIMARY KEY,
        userId $integerType,
        type $textType,
        points $integerType,
        description $textType,
        orderId $textTypeNullable,
        createdAt $textType,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create vouchers table
    await db.execute('''
      CREATE TABLE vouchers (
        id $textType PRIMARY KEY,
        userId $integerType,
        code $textType,
        title $textType,
        description $textType,
        type $textType,
        value REAL,
        pointsCost $integerType,
        validFrom $textTypeNullable,
        validUntil $textTypeNullable,
        isUsed $integerType DEFAULT 0,
        usedAt $textTypeNullable,
        minimumPurchase REAL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create storefront config table
    await db.execute('''
      CREATE TABLE storefront_configs (
        id $textType PRIMARY KEY,
        configData $textType,
        lastUpdated $textType
      )
    ''');

    // Create notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id $idType,
        userId $integerType,
        title $textType,
        body $textType,
        type $textType,
        data $textTypeNullable,
        isRead $integerType DEFAULT 0,
        createdAt $textType,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Insert default admin user
    await db.insert('users', {
      'name': 'Admin',
      'email': 'admin@thyne.com',
      'password': 'admin123', // In production, this should be hashed
      'phone': '1234567890',
      'createdAt': DateTime.now().toIso8601String(),
      'isAdmin': 1,
    });

    // Insert some sample products
    await _insertSampleProducts(db);
  }

  Future<void> _insertSampleProducts(Database db) async {
    final sampleProducts = [
      {
        'name': 'Diamond Ring',
        'description': 'Beautiful diamond ring with 18K gold band',
        'price': 2999.99,
        'category': 'Rings',
        'subcategory': 'Engagement',
        'images': 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=400',
        'metalType': '18K Gold',
        'stoneType': 'Diamond',
        'weight': 3.5,
        'tags': 'luxury,wedding,diamond',
        'rating': 4.5,
        'ratingCount': 120,
        'stock': 5,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Pearl Necklace',
        'description': 'Elegant pearl necklace with silver chain',
        'price': 899.99,
        'category': 'Necklaces',
        'subcategory': 'Classic',
        'images': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=400',
        'metalType': 'Silver',
        'stoneType': 'Pearl',
        'weight': 15.0,
        'tags': 'elegant,classic,pearl',
        'rating': 4.8,
        'ratingCount': 85,
        'stock': 8,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Gold Bracelet',
        'description': 'Handcrafted gold bracelet with intricate design',
        'price': 1299.99,
        'category': 'Bracelets',
        'subcategory': 'Luxury',
        'images': 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=400',
        'metalType': '22K Gold',
        'stoneType': '',
        'weight': 12.0,
        'tags': 'handmade,gold,luxury',
        'rating': 4.6,
        'ratingCount': 95,
        'stock': 3,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Emerald Earrings',
        'description': 'Stunning emerald earrings with platinum setting',
        'price': 3499.99,
        'category': 'Earrings',
        'subcategory': 'Premium',
        'images': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400',
        'metalType': 'Platinum',
        'stoneType': 'Emerald',
        'weight': 4.0,
        'tags': 'emerald,premium,platinum',
        'rating': 4.9,
        'ratingCount': 150,
        'stock': 2,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];

    for (final product in sampleProducts) {
      await db.insert('products', product);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}