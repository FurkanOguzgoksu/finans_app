import 'package:finans_app/models/category.dart';
import 'package:finans_app/repositories/category_repository.dart';
import 'package:finans_app/services/supabase_service.dart';

/// Category Data Access Object - Supabase üzerinden Kategori CRUD operasyonları
class CategoryDao implements CategoryRepository {
  final String _tableName = 'categories';
  final _client = SupabaseService.client;

  @override
  Future<List<Category>> getAll() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('type')
        .order('name');
    return response.map((map) => Category.fromMap(map)).toList();
  }

  @override
  Future<Category?> getById(int id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response != null) {
      return Category.fromMap(response);
    }
    return null;
  }

  @override
  Future<List<Category>> getByType(String type) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('type', type)
        .order('name');
    return response.map((map) => Category.fromMap(map)).toList();
  }

  @override
  Future<int> insert(Category category) async {
    final data = category.toMap();
    data.remove('id'); // Supabase auto-generates the ID
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

    await _client
        .from(_tableName)
        .update(category.toMap())
        .eq('id', category.id!);
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
    return 1;
  }
}
