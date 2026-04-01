import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı ayarlarını yöneten Provider
/// Aylık gelir, para birimi gibi bilgileri SharedPreferences ile saklar
class SettingsProvider extends ChangeNotifier {
  double _monthlyIncome = 0.0;
  String _currency = '₺';
  String _userName = '';
  String _userEmail = '';
  String _userPhotoPath = '';

  double get monthlyIncome => _monthlyIncome;
  String get currency => _currency;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhotoPath => _userPhotoPath;

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
    notifyListeners();
  }

  /// Aylık geliri günceller ve kaydeder
  Future<void> setMonthlyIncome(double income) async {
    _monthlyIncome = income;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_income', income);
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
