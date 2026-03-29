import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

/// Veritabanı servisi (DatabaseHelper) - SQLite veritabanı yönetimini sağlar
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Veritabanı instance'ını döndürür (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Veritabanını başlatır ve tabloları oluşturur
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Note: For full Web support with sqflite, sqflite_common_ffi_web is required.
      throw UnsupportedError(
        'Platform (Web) is not supported for sqflite natively. '
        'Please build and run the application for Windows (option [1]) instead of Chrome.',
      );
    } else if (defaultTargetPlatform == TargetPlatform.windows || 
               defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finans_app.db');

    return await openDatabase(
      path,
      version:
          3, // Migration yönetimi için bu sürüm artırıldı (items_json kolonu eklendi)
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Veritabanı bağlantısı açıldığında çalışır (Foreign Key desteği için)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Tablo şemalarını oluşturur
  Future<void> _onCreate(Database db, int version) async {
    // Kategoriler tablosu
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('gelir', 'gider')),
        icon TEXT DEFAULT 'category',
        color TEXT DEFAULT '#4CAF50'
      )
    ''');

    // İşlemler (Transactions) tablosu
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('gelir', 'gider')),
        category_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        receipt_id TEXT,
        items_json TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // Fişler/Faturalar (Receipts) tablosu
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        extracted_text TEXT,
        extracted_amount REAL,
        merchant_name TEXT,
        receipt_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Varsayılan kategorileri ekle
    await _insertDefaultCategories(db);
  }

  /// Veritabanı sürüm yükseltmelerinde çalışır (Migration Management)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Önceki sürümden kalan (belki de eksik/bozuk) tabloları temizleyelim
      await db.execute('DROP TABLE IF EXISTS receipts');
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS categories');

      // Yepyeni şemayı ve varsayılan kategorileri baştan oluşturalım
      await _onCreate(db, newVersion);
    }
    if (oldVersion < 3) {
      // items_json kolonu eklendi
      await db.execute('ALTER TABLE transactions ADD COLUMN items_json TEXT;');
    }
  }

  /// Varsayılan gelir/gider kategorilerini ekler
  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      // Gider kategorileri
      {
        'name': 'Market & Mutfak',
        'type': 'gider',
        'icon': 'shopping_cart',
        'color': '#FF9800',
      },
      {
        'name': 'Faturalar',
        'type': 'gider',
        'icon': 'receipt_long',
        'color': '#F44336',
      },
      {
        'name': 'Ulaşım',
        'type': 'gider',
        'icon': 'directions_bus',
        'color': '#2196F3',
      },
      {
        'name': 'Yemek & Kafe',
        'type': 'gider',
        'icon': 'restaurant',
        'color': '#E91E63',
      },
      {
        'name': 'Sağlık',
        'type': 'gider',
        'icon': 'local_hospital',
        'color': '#9C27B0',
      },
      {
        'name': 'Diğer Gider',
        'type': 'gider',
        'icon': 'more_horiz',
        'color': '#607D8B',
      },
      // Gelir kategorileri
      {
        'name': 'Maaş',
        'type': 'gelir',
        'icon': 'account_balance_wallet',
        'color': '#4CAF50',
      },
      {
        'name': 'Freelance / Ek Gelir',
        'type': 'gelir',
        'icon': 'work',
        'color': '#00BCD4',
      },
      {
        'name': 'Yatırım',
        'type': 'gelir',
        'icon': 'trending_up',
        'color': '#8BC34A',
      },
      {
        'name': 'Diğer Gelir',
        'type': 'gelir',
        'icon': 'attach_money',
        'color': '#009688',
      },
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  /// Veritabanını kapatır
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
