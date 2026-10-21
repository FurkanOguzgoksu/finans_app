import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:finans_app/models/category.dart';
import 'package:finans_app/models/transaction.dart';
import 'package:finans_app/providers/auth_provider.dart';
import 'package:finans_app/repositories/category_repository.dart';
import 'package:finans_app/repositories/transaction_repository.dart';

/// Supabase olmadan oturum açma/kapama taklidi yapan sahte oturum
class FakeSession extends ChangeNotifier implements UserSession {
  FakeSession([this._userId]);

  String? _userId;

  @override
  String? get userId => _userId;

  void login(String id) {
    _userId = id;
    notifyListeners();
  }

  void logout() {
    _userId = null;
    notifyListeners();
  }
}

/// Bellekte çalışan kategori deposu. [delay] ağ gecikmesini taklit eder.
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository({this.delay = Duration.zero});

  final Duration delay;
  final List<Category> items = [];
  int _nextId = 1;

  @override
  Future<List<Category>> getAll() async {
    await Future.delayed(delay);
    return List.of(items);
  }

  @override
  Future<Category?> getById(int id) async {
    for (final c in items) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<List<Category>> getByType(String type) async =>
      items.where((c) => c.type == type).toList();

  @override
  Future<int> insert(Category category) async {
    final id = _nextId++;
    items.add(category.copyWith(id: id));
    return id;
  }

  @override
  Future<int> update(Category category) async {
    final index = items.indexWhere((c) => c.id == category.id);
    if (index == -1) return 0;
    items[index] = category;
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    items.removeWhere((c) => c.id == id);
    return 1;
  }
}

/// Bellekte çalışan işlem deposu. [failWrites] true ise yazma işlemleri hata verir.
class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> items = [];
  bool failWrites = false;
  int _nextId = 1;

  @override
  Future<List<Transaction>> getAll() async => List.of(items);

  @override
  Future<Transaction?> getById(int id) async {
    for (final t in items) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<List<Transaction>> getByType(String type) async =>
      items.where((t) => t.type == type).toList();

  @override
  Future<List<Transaction>> getByCategoryId(int categoryId) async =>
      items.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async =>
      items.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();

  @override
  Future<int> insert(Transaction transaction) async {
    if (failWrites) throw Exception('bağlantı yok');
    final id = _nextId++;
    items.add(transaction.copyWith(id: id));
    return id;
  }

  @override
  Future<int> update(Transaction transaction) async {
    if (failWrites) throw Exception('bağlantı yok');
    final index = items.indexWhere((t) => t.id == transaction.id);
    if (index == -1) return 0;
    items[index] = transaction;
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    if (failWrites) throw Exception('bağlantı yok');
    items.removeWhere((t) => t.id == id);
    return 1;
  }

  @override
  Future<double> getTotalIncome({DateTime? start, DateTime? end}) async =>
      items.where((t) => t.type == 'gelir').fold<double>(0.0, (s, t) => s + t.amount);

  @override
  Future<double> getTotalExpense({DateTime? start, DateTime? end}) async =>
      items.where((t) => t.type == 'gider').fold<double>(0.0, (s, t) => s + t.amount);
}
