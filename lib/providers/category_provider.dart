import 'package:flutter/material.dart';
import 'package:finans_app/models/category.dart';
import 'package:finans_app/services/category_dao.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryDao _categoryDao = CategoryDao();
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  /// Kategorileri veritabanından yükler ve state'i günceller
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _categoryDao.getAll();
    } catch (e) {
      debugPrint("Kategoriler yüklenirken hata: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni kategori ekler ve listeyi tazeler
  Future<void> addCategory(Category category) async {
    await _categoryDao.insert(category);
    await loadCategories();
  }

  /// ID'ye göre kategori bulur
  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Gelir veya Gider kategorilerini filtreler
  List<Category> getCategoriesByType(String type) {
    return _categories.where((cat) => cat.type == type).toList();
  }
}
