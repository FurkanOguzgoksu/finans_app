import '../models/category.dart';

/// Category Repository - Kategori CRUD operasyonları için abstract sınıf
abstract class CategoryRepository {
  /// Tüm kategorileri getirir
  Future<List<Category>> getAll();

  /// ID'ye göre tek bir kategori getirir
  Future<Category?> getById(int id);

  /// Türe göre kategorileri getirir ('gelir' veya 'gider')
  Future<List<Category>> getByType(String type);

  /// Yeni kategori ekler, eklenen kaydın ID'sini döndürür
  Future<int> insert(Category category);

  /// Mevcut kategoriyi günceller
  Future<int> update(Category category);

  /// Kategoriyi siler
  Future<int> delete(int id);
}
