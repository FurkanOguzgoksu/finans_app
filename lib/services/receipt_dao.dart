import 'package:finans_app/models/receipt.dart';
import 'package:finans_app/repositories/receipt_repository.dart';
import 'package:finans_app/services/supabase_service.dart';

/// Receipt Data Access Object - Supabase üzerinden Fiş/Fatura CRUD operasyonları
class ReceiptDao implements ReceiptRepository {
  final String _tableName = 'receipts';
  final _client = SupabaseService.client;

  @override
  Future<List<Receipt>> getAll() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);
    return response.map((map) => Receipt.fromMap(map)).toList();
  }

  @override
  Future<Receipt?> getById(int id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response != null) {
      return Receipt.fromMap(response);
    }
    return null;
  }

  @override
  Future<List<Receipt>> getByDateRange(DateTime start, DateTime end) async {
    final response = await _client
        .from(_tableName)
        .select()
        .gte('receipt_date', start.toIso8601String())
        .lte('receipt_date', end.toIso8601String())
        .order('receipt_date', ascending: false);
    return response.map((map) => Receipt.fromMap(map)).toList();
  }

  @override
  Future<int> insert(Receipt receipt) async {
    final data = receipt.toMap();
    data.remove('id'); // Supabase auto-generates the ID
    final response = await _client
        .from(_tableName)
        .insert(data)
        .select('id')
        .single();
    return response['id'] as int;
  }

  @override
  Future<int> update(Receipt receipt) async {
    if (receipt.id == null) return 0;

    await _client
        .from(_tableName)
        .update(receipt.toMap())
        .eq('id', receipt.id!);
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
    return 1;
  }
}
