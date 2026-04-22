import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı ayarlarını yöneten Provider
/// Aylık gelir, para birimi, tekrarlayan gelir bilgilerini SharedPreferences ile saklar
class SettingsProvider extends ChangeNotifier {
  double _monthlyIncome = 0.0;
  String _currency = '₺';
  String _userName = '';
  String _userEmail = '';
  String _userPhotoPath = '';

  // Tekrarlayan gelir alanları
  int _incomeDay = 0;            // Ayın kaçında ekleneceği (0 = ayarlanmamış)
  String _lastIncomeMonth = '';  // Son eklenen ay: 'YYYY-MM'
  int? _incomeCategoryId;        // Gelir kategorisi ID
  String _incomeTitle = 'Aylık Maaş'; // İşlem başlığı

  double get monthlyIncome => _monthlyIncome;
  String get currency => _currency;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhotoPath => _userPhotoPath;

  int get incomeDay => _incomeDay;
  String get lastIncomeMonth => _lastIncomeMonth;
  int? get incomeCategoryId => _incomeCategoryId;
  String get incomeTitle => _incomeTitle;

  /// Tekrarlayan gelir tam olarak ayarlanmış mı?
  bool get hasRecurringIncome =>
      _monthlyIncome > 0 && _incomeDay > 0 && _incomeCategoryId != null;

  SettingsProvider() {
    _loadSettings();
  }

  /// Kaydedilmiş ayarları SharedPreferences'dan yükler
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;
    _currency = prefs.getString('currency') ?? '₺';
    _userName = prefs.getString('user_name') ?? '';
    _userEmail = prefs.getString('user_email') ?? '';
    _userPhotoPath = prefs.getString('user_photo_path') ?? '';
    _incomeDay = prefs.getInt('income_day') ?? 0;
    _lastIncomeMonth = prefs.getString('last_income_month') ?? '';
    final catId = prefs.getInt('income_category_id');
    _incomeCategoryId = catId;
    _incomeTitle = prefs.getString('income_title') ?? 'Aylık Maaş';
    notifyListeners();
  }

  /// Aylık geliri günceller ve kaydeder
  Future<void> setMonthlyIncome(double income) async {
    _monthlyIncome = income;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_income', income);
  }

  /// Tekrarlayan gelir bilgilerini toplu kaydeder
  Future<void> setRecurringIncomeConfig({
    required double amount,
    required int day,
    required int categoryId,
    required String title,
  }) async {
    _monthlyIncome = amount;
    _incomeDay = day;
    _incomeCategoryId = categoryId;
    _incomeTitle = title;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_income', amount);
    await prefs.setInt('income_day', day);
    await prefs.setInt('income_category_id', categoryId);
    await prefs.setString('income_title', title);
  }

  /// Son otomatik gelir eklenen ayı kaydeder (YYYY-MM)
  Future<void> setLastIncomeMonth(String monthKey) async {
    _lastIncomeMonth = monthKey;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_income_month', monthKey);
  }

  /// Para birimini günceller ve kaydeder
  Future<void> setCurrency(String currency) async {
    _currency = currency;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
  }

  /// Kullanıcı adını günceller ve kaydeder
  Future<void> setUserName(String name) async {
    _userName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  /// Kullanıcı e-postasını günceller ve kaydeder
  Future<void> setUserEmail(String email) async {
    _userEmail = email;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  /// Kullanıcı profil fotoğrafı yolunu günceller ve kaydeder
  Future<void> setUserPhotoPath(String path) async {
    _userPhotoPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_photo_path', path);
  }
}
