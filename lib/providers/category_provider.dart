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
      
      // Güvenlik Önlemi: Eğer veritabanında hiç kategori yoksa (eski sürümden kalmışsa), 
      // temel kategorileri ekleyip tekrar çekelim.
      if (_categories.isEmpty) {
        debugPrint("Veritabanı boş, varsayılan kategoriler yükleniyor...");
        await _categoryDao.insert(Category(name: 'Market & Mutfak', type: 'gider', icon: 'shopping_cart', color: '#FF9800'));
        await _categoryDao.insert(Category(name: 'Faturalar', type: 'gider', icon: 'receipt_long', color: '#F44336'));
        await _categoryDao.insert(Category(name: 'Ulaşım', type: 'gider', icon: 'directions_bus', color: '#2196F3'));
        await _categoryDao.insert(Category(name: 'Yemek & Kafe', type: 'gider', icon: 'restaurant', color: '#E91E63'));
        await _categoryDao.insert(Category(name: 'Sağlık', type: 'gider', icon: 'local_hospital', color: '#9C27B0'));
        await _categoryDao.insert(Category(name: 'Maaş', type: 'gelir', icon: 'account_balance_wallet', color: '#4CAF50'));
        await _categoryDao.insert(Category(name: 'Diğer Gelir', type: 'gelir', icon: 'attach_money', color: '#009688'));
        
        _categories = await _categoryDao.getAll();
      }
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

  /// Kategoriyi günceller ve listeyi tazeler
  Future<void> updateCategory(Category category) async {
    await _categoryDao.update(category);
    await loadCategories();
  }

  /// Kategoriyi siler ve listeyi tazeler
  Future<void> deleteCategory(int id) async {
    await _categoryDao.delete(id);
    await loadCategories();
  }

  /// Çıkış yapıldığında verileri temizler
  void clear() {
    _categories = [];
    notifyListeners();
  }
}

