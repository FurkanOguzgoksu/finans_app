import 'package:flutter/material.dart';
import 'package:finans_app/models/category.dart';
import 'package:finans_app/providers/auth_provider.dart';
import 'package:finans_app/repositories/category_repository.dart';
import 'package:finans_app/services/category_dao.dart';

class CategoryProvider with ChangeNotifier {
  final UserSession _session;
  final CategoryRepository _repository;
  String? _userId;

  List<Category> _categories = [];
  bool _isLoading = false;
  Future<void>? _loadFuture;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  /// [repository] testlerde sahte veri kaynağı vermek içindir.
  CategoryProvider(this._session, {CategoryRepository? repository})
      : _repository = repository ?? CategoryDao() {
    _session.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Oturum kapanınca kategorileri temizler, yeni kullanıcı gelince yükler
  void _onSessionChanged() {
    final userId = _session.userId;
    if (userId == _userId) return;
    _userId = userId;

    _categories = [];
    _loadFuture = null;
    notifyListeners();

    if (userId != null) loadCategories();
  }

  /// Kategorileri veritabanından yükler ve state'i günceller.
  ///
  /// Yükleme sürerken yapılan çağrılar aynı işlemi bekler; aksi halde iki yükleme
  /// de listeyi boş görüp varsayılan kategorileri iki kez ekleyebilirdi.
  Future<void> loadCategories() {
    final inFlight = _loadFuture;
    if (inFlight != null) return inFlight;

    late final Future<void> future;
    future = _load().whenComplete(() {
      if (identical(_loadFuture, future)) _loadFuture = null;
    });
    _loadFuture = future;
    return future;
  }

  Future<void> _load() async {
    final userId = _userId;
    _isLoading = true;
    notifyListeners();

    try {
      var categories = await _repository.getAll();

      // Güvenlik Önlemi: Eğer veritabanında hiç kategori yoksa (yeni kullanıcı),
      // temel kategorileri ekleyip tekrar çekelim.
      if (categories.isEmpty && userId == _userId) {
        debugPrint("Veritabanı boş, varsayılan kategoriler yükleniyor...");
        await _repository.insert(Category(name: 'Market & Mutfak', type: 'gider', icon: 'shopping_cart', color: '#FF9800'));
        await _repository.insert(Category(name: 'Faturalar', type: 'gider', icon: 'receipt_long', color: '#F44336'));
        await _repository.insert(Category(name: 'Ulaşım', type: 'gider', icon: 'directions_bus', color: '#2196F3'));
        await _repository.insert(Category(name: 'Yemek & Kafe', type: 'gider', icon: 'restaurant', color: '#E91E63'));
        await _repository.insert(Category(name: 'Sağlık', type: 'gider', icon: 'local_hospital', color: '#9C27B0'));
        await _repository.insert(Category(name: 'Maaş', type: 'gelir', icon: 'account_balance_wallet', color: '#4CAF50'));
        await _repository.insert(Category(name: 'Diğer Gelir', type: 'gelir', icon: 'attach_money', color: '#009688'));

        categories = await _repository.getAll();
      }

      // Yükleme sürerken hesap değiştiyse eski kullanıcının verisini yazma
      if (userId == _userId) _categories = categories;
    } catch (e) {
      debugPrint("Kategoriler yüklenirken hata: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni kategori ekler ve listeyi tazeler.
  /// Kayıt başarısız olursa hata çağırana iletilir.
  Future<void> addCategory(Category category) async {
    await _repository.insert(category);
    await _reload();
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
    await _repository.update(category);
    await _reload();
  }

  /// Kategoriyi siler ve listeyi tazeler
  Future<void> deleteCategory(int id) async {
    await _repository.delete(id);
    await _reload();
  }

  /// Değişiklik sonrası listeyi tazeler. Değişiklikten önce başlamış bir yükleme
  /// varsa onu beklemek yetmez (eski veriyi getirir), ardından yeniden yüklenir.
  Future<void> _reload() async {
    await _loadFuture;
    await loadCategories();
  }
}
