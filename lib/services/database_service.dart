import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Veritabanı servisi - SQLite veritabanı yönetimini sağlar
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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finans_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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

  /// Veritabanı sürüm yükseltmelerinde çalışır
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // İleride şema değişikliklerinde kullanılacak
  }

  /// Varsayılan gelir/gider kategorilerini ekler
  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      // Gider kategorileri
      {'name': 'Yiyecek & İçecek', 'type': 'gider', 'icon': 'restaurant', 'color': '#FF5722'},
      {'name': 'Ulaşım', 'type': 'gider', 'icon': 'directions_bus', 'color': '#2196F3'},
      {'name': 'Alışveriş', 'type': 'gider', 'icon': 'shopping_cart', 'color': '#9C27B0'},
      {'name': 'Faturalar', 'type': 'gider', 'icon': 'receipt_long', 'color': '#FF9800'},
      {'name': 'Sağlık', 'type': 'gider', 'icon': 'local_hospital', 'color': '#F44336'},
      {'name': 'Eğitim', 'type': 'gider', 'icon': 'school', 'color': '#3F51B5'},
      {'name': 'Eğlence', 'type': 'gider', 'icon': 'movie', 'color': '#E91E63'},
      {'name': 'Diğer Gider', 'type': 'gider', 'icon': 'more_horiz', 'color': '#607D8B'},
      // Gelir kategorileri
      {'name': 'Maaş', 'type': 'gelir', 'icon': 'account_balance_wallet', 'color': '#4CAF50'},
      {'name': 'Freelance', 'type': 'gelir', 'icon': 'work', 'color': '#00BCD4'},
      {'name': 'Yatırım', 'type': 'gelir', 'icon': 'trending_up', 'color': '#8BC34A'},
      {'name': 'Diğer Gelir', 'type': 'gelir', 'icon': 'attach_money', 'color': '#009688'},
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
