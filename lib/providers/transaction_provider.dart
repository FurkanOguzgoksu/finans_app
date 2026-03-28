import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_app/models/transaction.dart' as models;
import 'package:finans_app/services/transaction_dao.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionDao _transactionDao = TransactionDao();
  List<models.Transaction> _transactions = [];
  bool _isLoading = false;

  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _balance = 0.0;
  double _budgetLimit = 7500.0;

  List<models.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;
  double get budgetLimit => _budgetLimit;

  TransactionProvider() {
    _loadBudgetLimit();
  }

  Future<void> _loadBudgetLimit() async {
    final prefs = await SharedPreferences.getInstance();
    _budgetLimit = prefs.getDouble('budget_limit') ?? 7500.0;
    notifyListeners();
  }

  Future<void> setBudgetLimit(double limit) async {
    _budgetLimit = limit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_limit', limit);
  }

  /// Veritabanından tüm işlemleri, gelir/gider toplamlarını çeker ve UI'ı günceller
  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. İşlem Listesini Çek
      _transactions = await _transactionDao.getAll();

      // 2. Toplam Gelir ve Gideri Çek
      _totalIncome = await _transactionDao.getTotalIncome();
      _totalExpense = await _transactionDao.getTotalExpense();
      _balance = _totalIncome - _totalExpense;
    } catch (e) {
      debugPrint("İşlemler yüklenirken hata: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni işlem (harcama/gelir) ekler ve state'i tazeler
  Future<void> addTransaction(models.Transaction transaction) async {
    await _transactionDao.insert(transaction);
    await loadTransactions();
  }

  /// İşlemi ID'ye göre siler ve state'i tazeler
  Future<void> deleteTransaction(int id) async {
    await _transactionDao.delete(id);
    await loadTransactions();
  }
}
