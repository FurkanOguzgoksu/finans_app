import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import 'database_service.dart';

/// Transaction Data Access Object - SQLite üzerinden İşlem CRUD operasyonları
class TransactionDao implements TransactionRepository {
  final DatabaseService _dbService = DatabaseService();
  final String _tableName = 'transactions';

  @override
  Future<List<Transaction>> getAll() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  @override
  Future<Transaction?> getById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Transaction.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<Transaction>> getByType(String type) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  @override
  Future<List<Transaction>> getByCategoryId(int categoryId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  @override
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  @override
  Future<int> insert(Transaction transaction) async {
    final db = await _dbService.database;
    return await db.insert(_tableName, transaction.toMap());
  }

  @override
  Future<int> update(Transaction transaction) async {
    if (transaction.id == null) return 0;
    
    final db = await _dbService.database;
    return await db.update(
      _tableName,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
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

  @override
  Future<double> getTotalIncome({DateTime? start, DateTime? end}) async {
    return _getTotalAmountByType('gelir', start: start, end: end);
  }

  @override
  Future<double> getTotalExpense({DateTime? start, DateTime? end}) async {
    return _getTotalAmountByType('gider', start: start, end: end);
  }
  
  /// Yardımcı metot: Belirli tür ve tarih aralığına göre toplam tutarı hesaplar
  Future<double> _getTotalAmountByType(String type, {DateTime? start, DateTime? end}) async {
    final db = await _dbService.database;
    
    String whereClause = 'type = ?';
    List<dynamic> whereArgs = [type];
    
    if (start != null && end != null) {
      whereClause += ' AND date >= ? AND date <= ?';
      whereArgs.addAll([start.toIso8601String(), end.toIso8601String()]);
    }
    
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $_tableName WHERE $whereClause',
      whereArgs,
    );
    
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }
}
