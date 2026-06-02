import 'package:finans_app/models/transaction.dart';
import 'package:finans_app/repositories/transaction_repository.dart';
import 'package:finans_app/services/supabase_service.dart';

/// Transaction Data Access Object - Supabase üzerinden İşlem CRUD operasyonları
class TransactionDao implements TransactionRepository {
  final String _tableName = 'transactions';
  final _client = SupabaseService.client;

  @override
  Future<List<Transaction>> getAll() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('date', ascending: false);
    return response.map((map) => Transaction.fromMap(map)).toList();
  }

  @override
  Future<Transaction?> getById(int id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response != null) {
      return Transaction.fromMap(response);
    }
    return null;
  }

  @override
  Future<List<Transaction>> getByType(String type) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('type', type)
        .order('date', ascending: false);
    return response.map((map) => Transaction.fromMap(map)).toList();
  }

  @override
  Future<List<Transaction>> getByCategoryId(int categoryId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('category_id', categoryId)
        .order('date', ascending: false);
    return response.map((map) => Transaction.fromMap(map)).toList();
  }

  @override
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async {
    final response = await _client
        .from(_tableName)
        .select()
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String())
        .order('date', ascending: false);
    return response.map((map) => Transaction.fromMap(map)).toList();
  }

  @override
  Future<int> insert(Transaction transaction) async {
    final data = transaction.toMap();
    data.remove('id'); // Supabase auto-generates the ID
    final response = await _client
        .from(_tableName)
        .insert(data)
        .select('id')
        .single();
    return response['id'] as int;
  }

  @override
  Future<int> update(Transaction transaction) async {
    if (transaction.id == null) return 0;

    await _client
        .from(_tableName)
        .update(transaction.toMap())
        .eq('id', transaction.id!);
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
    return 1;
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
  Future<double> _getTotalAmountByType(
    String type, {
    DateTime? start,
    DateTime? end,
  }) async {
    var query = _client.from(_tableName).select('amount').eq('type', type);

    if (start != null && end != null) {
      query = query
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());
    }

    final response = await query;
    if (response.isEmpty) return 0.0;

    double total = 0.0;
    for (var row in response) {
      total += (row['amount'] as num).toDouble();
    }
    return total;
  }
}
