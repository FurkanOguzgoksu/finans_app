import '../models/category.dart';
import '../repositories/category_repository.dart';
import 'database_service.dart';

/// Category Data Access Object - SQLite üzerinden Kategori CRUD operasyonları
class CategoryDao implements CategoryRepository {
  final DatabaseService _dbService = DatabaseService();
  final String _tableName = 'categories';

  @override
  Future<List<Category>> getAll() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'type, name',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  @override
  Future<Category?> getById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<Category>> getByType(String type) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  @override
  Future<int> insert(Category category) async {
    final db = await _dbService.database;
    return await db.insert(_tableName, category.toMap());
  }

  @override
  Future<int> update(Category category) async {
    if (category.id == null) return 0;

    final db = await _dbService.database;
    return await db.update(
      _tableName,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _dbService.database;
    // Not: Foreign key constraint nedeniyle, bu kategoriye ait işlemler cascade delete ile silinebilir (ON DELETE CASCADE yapısı)
    // Veya kullanıcı uyarılmalı
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
