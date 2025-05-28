// ignore_for_file: avoid_print, duplicate_ignore

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const int _databaseVersion = 2;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'products.db');
    
    // Only use resetDatabase() when needed during development
    // await deleteDatabase(path);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            price REAL NOT NULL,
            category TEXT NOT NULL,
            location TEXT,
            image TEXT,
            sellerId TEXT,
            isLocalImage INTEGER,
            status TEXT,
            views INTEGER DEFAULT 0,
            inCart INTEGER DEFAULT 0,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE payments(
            id TEXT PRIMARY KEY,
            productId TEXT,
            amount REAL,
            timestamp INTEGER,
            status TEXT,
            FOREIGN KEY(productId) REFERENCES products(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add new columns if upgrading from version 1
          await db.execute('ALTER TABLE products ADD COLUMN category TEXT');
          await db.execute('ALTER TABLE products ADD COLUMN location TEXT');
        }
      },
    );
  }

  // Helper method to reset database (use during development)
  static Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'products.db');
    await deleteDatabase(path);
    _database = null;
  }

  // Add these debug methods
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    final products = await db.query('products');
    // ignore: avoid_print
    print('Retrieved ${products.length} products from database');
    return products;
  }

  static Future<void> debugPrintTableInfo() async {
    final db = await database;
    final tableInfo = await db.rawQuery("SELECT * FROM sqlite_master WHERE type='table'");
    print('Database tables: $tableInfo');
    
    final productCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products')
    );
    print('Number of products in database: $productCount');
  }
}