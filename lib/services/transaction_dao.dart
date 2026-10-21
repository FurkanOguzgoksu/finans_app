import 'package:finans_app/models/transaction.dart';
import 'package:finans_app/repositories/transaction_repository.dart';
import 'package:finans_app/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestFilterBuilder;

/// Transaction Data Access Object - Supabase üzerinden İşlem CRUD operasyonları
///
/// Erişim RLS ile kullanıcının kendi kayıtlarıyla sınırlıdır; sorgular ayrıca
/// user_id ile filtrelenir (ek güvenlik ve indeks kullanımı için).
class TransactionDao implements TransactionRepository {
  final String _tableName = 'transactions';
  final _client = SupabaseService.client;

  /// Kullanıcının kayıtlarını sorgulamaya başlar
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _select([String columns = '*']) {
    return _client
        .from(_tableName)
        .select(columns)
        .eq('user_id', SupabaseService.currentUserId);
  }

  /// Sorgunun tüm sayfalarını tarihe göre (yeniden eskiye) sıralı çeker
  Future<List<Transaction>> _fetchAll(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function() query,
  ) async {
    final rows = await SupabaseService.fetchAllPages(
      (from, to) => query()
          .order('date', ascending: false)
          .order('id', ascending: false)
          .range(from, to),
    );
    return rows.map((map) => Transaction.fromMap(map)).toList();
  }

  @override
  Future<List<Transaction>> getAll() => _fetchAll(() => _select());

  @override
  Future<Transaction?> getById(int id) async {
    final response = await _select().eq('id', id).maybeSingle();

    if (response != null) {
      return Transaction.fromMap(response);
    }
    return null;
  }

  @override
  Future<List<Transaction>> getByType(String type) =>
      _fetchAll(() => _select().eq('type', type));

  @override
  Future<List<Transaction>> getByCategoryId(int categoryId) =>
      _fetchAll(() => _select().eq('category_id', categoryId));

  @override
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) =>
      _fetchAll(() => _select()
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String()));

  @override
  Future<int> insert(Transaction transaction) async {
    final data = transaction.toMap();
    data.remove('id'); // Supabase auto-generates the ID
    data['user_id'] = SupabaseService.currentUserId;
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

    final data = transaction.toMap();
    data.remove('id'); // Kimlik değişmez; yalnızca filtrede kullanılır
    await _client
        .from(_tableName)
        .update(data)
        .eq('id', transaction.id!)
        .eq('user_id', SupabaseService.currentUserId);
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    await _client
        .from(_tableName)
        .delete()
        .eq('id', id)
        .eq('user_id', SupabaseService.currentUserId);
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
    final rows = await SupabaseService.fetchAllPages((from, to) {
      var query = _select('id, amount').eq('type', type);
      if (start != null && end != null) {
        query = query
            .gte('date', start.toIso8601String())
            .lte('date', end.toIso8601String());
      }
      return query.order('id').range(from, to);
    });

    double total = 0.0;
    for (var row in rows) {
      total += (row['amount'] as num).toDouble();
    }
    return total;
  }
}
