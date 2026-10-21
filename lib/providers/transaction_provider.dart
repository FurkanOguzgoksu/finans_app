import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:finans_app/models/transaction.dart' as models;
import 'package:finans_app/providers/auth_provider.dart';
import 'package:finans_app/repositories/transaction_repository.dart';
import 'package:finans_app/services/transaction_dao.dart';
import 'package:finans_app/utils/currency_formatter.dart';

class TransactionProvider with ChangeNotifier {
  final UserSession _session;
  final TransactionRepository _repository;
  String? _userId;

  List<models.Transaction> _transactions = [];
  bool _isLoading = false;
  String? _loadError;

  List<models.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  /// Son yükleme başarısız olduysa kullanıcıya gösterilecek hata mesajı
  String? get loadError => _loadError;

  double get totalIncome => _sum(_transactions, 'gelir');
  double get totalExpense => _sum(_transactions, 'gider');
  double get balance => totalIncome - totalExpense;

  /// İçinde bulunulan aya ait gelir toplamı
  double get currentMonthIncome => _sum(_currentMonthTransactions, 'gelir');

  /// İçinde bulunulan aya ait gider toplamı (aylık bütçe bununla karşılaştırılır)
  double get currentMonthExpense => _sum(_currentMonthTransactions, 'gider');

  Iterable<models.Transaction> get _currentMonthTransactions {
    final now = DateTime.now();
    return _transactions.where(
      (tx) => tx.date.year == now.year && tx.date.month == now.month,
    );
  }

  static double _sum(Iterable<models.Transaction> txs, String type) {
    return txs
        .where((tx) => tx.type == type)
        .fold(0.0, (total, tx) => total + tx.amount);
  }

  /// [repository] testlerde sahte veri kaynağı vermek içindir.
  TransactionProvider(this._session, {TransactionRepository? repository})
      : _repository = repository ?? TransactionDao() {
    _session.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Oturum kapanınca verileri temizler, yeni kullanıcı gelince yükler
  void _onSessionChanged() {
    final userId = _session.userId;
    if (userId == _userId) return;
    _userId = userId;

    _transactions = [];
    _loadError = null;
    notifyListeners();
    _updateHomeWidget();

    if (userId != null) loadTransactions();
  }

  /// Veritabanından tüm işlemleri çeker ve UI'ı günceller
  Future<void> loadTransactions() async {
    final userId = _userId;
    _isLoading = true;
    notifyListeners();

    try {
      final transactions = await _repository.getAll();
      // Yükleme sürerken hesap değiştiyse eski kullanıcının verisini yazma
      if (userId != _userId) return;
      _transactions = transactions;
      _loadError = null;
      _updateHomeWidget();
    } catch (e) {
      debugPrint("İşlemler yüklenirken hata: $e");
      if (userId == _userId) {
        _loadError = 'İşlemler yüklenemedi. İnternet bağlantınızı kontrol edin.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ana ekran widget'ındaki bu ayın gelir/gider bilgisini günceller
  Future<void> _updateHomeWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('monthly_income', '₺${CurrencyFormatter.format(currentMonthIncome)}');
      await HomeWidget.saveWidgetData<String>('monthly_expense', '₺${CurrencyFormatter.format(currentMonthExpense)}');
      await HomeWidget.updateWidget(name: 'FinanceWidgetProvider', iOSName: 'FinanceWidgetProvider');
    } catch (e) {
      // Widget desteklenmeyen platformlarda (Windows, test vb.) sessizce geç
      debugPrint("Ana ekran widget'ı güncellenemedi: $e");
    }
  }

  /// Yeni işlem (harcama/gelir) ekler ve state'i tazeler.
  /// Kayıt başarısız olursa hata çağırana iletilir.
  Future<void> addTransaction(models.Transaction transaction) async {
    await _repository.insert(transaction);
    await loadTransactions();
  }

  /// İşlemi ID'ye göre siler ve state'i tazeler
  Future<void> deleteTransaction(int id) async {
    await _repository.delete(id);
    await loadTransactions();
  }

  /// Var olan işlemi günceller ve state'i tazeler
  Future<void> updateTransaction(models.Transaction transaction) async {
    await _repository.update(transaction);
    await loadTransactions();
  }
}
