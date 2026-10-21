import 'package:finans_app/models/category.dart';
import 'package:finans_app/repositories/category_repository.dart';
import 'package:finans_app/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestFilterBuilder;

/// Category Data Access Object - Supabase üzerinden Kategori CRUD operasyonları
///
/// Erişim RLS ile kullanıcının kendi kayıtlarıyla sınırlıdır; sorgular ayrıca
/// user_id ile filtrelenir (ek güvenlik ve indeks kullanımı için).
class CategoryDao implements CategoryRepository {
  final String _tableName = 'categories';
  final _client = SupabaseService.client;

  /// Kullanıcının kayıtlarını sorgulamaya başlar
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _select() {
    return _client
        .from(_tableName)
        .select()
        .eq('user_id', SupabaseService.currentUserId);
  }

  @override
  Future<List<Category>> getAll() async {
    final rows = await SupabaseService.fetchAllPages(
      (from, to) => _select()
          .order('type')
          .order('name')
          .order('id')
          .range(from, to),
    );
    return rows.map((map) => Category.fromMap(map)).toList();
  }

  @override
  Future<Category?> getById(int id) async {
    final response = await _select().eq('id', id).maybeSingle();

    if (response != null) {
      return Category.fromMap(response);
    }
    return null;
  }

  @override
  Future<List<Category>> getByType(String type) async {
    final rows = await SupabaseService.fetchAllPages(
      (from, to) => _select()
          .eq('type', type)
          .order('name')
          .order('id')
          .range(from, to),
    );
    return rows.map((map) => Category.fromMap(map)).toList();
  }

  @override
  Future<int> insert(Category category) async {
    final data = category.toMap();
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
  Future<int> update(Category category) async {
    if (category.id == null) return 0;

    final data = category.toMap();
    data.remove('id'); // Kimlik değişmez; yalnızca filtrede kullanılır
    await _client
        .from(_tableName)
        .update(data)
        .eq('id', category.id!)
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
}
