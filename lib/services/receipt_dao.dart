import '../models/receipt.dart';
import '../repositories/receipt_repository.dart';
import 'database_service.dart';

/// Receipt Data Access Object - SQLite üzerinden Fiş/Fatura CRUD operasyonları
class ReceiptDao implements ReceiptRepository {
  final DatabaseService _dbService = DatabaseService();
  final String _tableName = 'receipts';

  @override
  Future<List<Receipt>> getAll() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Receipt.fromMap(map)).toList();
  }

  @override
  Future<Receipt?> getById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Receipt.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<Receipt>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'receipt_date >= ? AND receipt_date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'receipt_date DESC',
    );
    return maps.map((map) => Receipt.fromMap(map)).toList();
  }

  @override
  Future<int> insert(Receipt receipt) async {
    final db = await _dbService.database;
    return await db.insert(_tableName, receipt.toMap());
  }

  @override
  Future<int> update(Receipt receipt) async {
    if (receipt.id == null) return 0;

    final db = await _dbService.database;
    return await db.update(
      _tableName,
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  @override
  Future<int> delete(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
