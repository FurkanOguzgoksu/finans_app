import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

/// Kullanıcı ayarlarını yöneten Provider
///
/// Cihaza ait ayarlar (bildirim, uygulama kilidi vb.) tüm hesaplar için ortaktır.
/// Bütçe, aylık gelir ve profil fotoğrafı gibi ayarlar ise oturumdaki kullanıcıya
/// özeldir; aynı cihazda başka hesap açılınca o hesabın ayarları yüklenir.
///
/// SharedPreferences örneği hazır olarak verildiği için ayarlar senkron yüklenir;
/// böylece ilk frame'de (ör. uygulama kilidi kontrolünde) doğru değerler okunur.
class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final UserSession _session;
  String? _userId;

  // ─── Kullanıcıya özel ayarlar ─────────────────────
  double _monthlyIncome = 0.0;
  String _userPhotoPath = '';
  double _budgetLimit = _defaultBudgetLimit;

  // Tekrarlayan gelir alanları
  int _incomeDay = 0;            // Ayın kaçında ekleneceği (0 = ayarlanmamış)
  String _lastIncomeMonth = '';  // Son eklenen ay: 'YYYY-MM'
  int? _incomeCategoryId;        // Gelir kategorisi ID
  String _incomeTitle = _defaultIncomeTitle; // İşlem başlığı

  // ─── Cihaza ait ayarlar ───────────────────────────
  String _currency = '₺';
  String _userName = '';
  String _userEmail = '';

  // Bildirim ayarları
  bool _notificationsEnabled = true;
  List<String> _notificationTimes = ['12:30', '20:30']; // Varsayılan 2 saat

  // Güvenlik ayarları
  bool _appLockEnabled = false;

  static const double _defaultBudgetLimit = 10000.0;
  static const String _defaultIncomeTitle = 'Aylık Maaş';

  /// Kullanıcıya özel anahtarlar (eski sürümlerde cihaz geneline yazılıyordu)
  static const _userScopedKeys = [
    'monthly_income',
    'user_photo_path',
    'budget_limit',
    'income_day',
    'last_income_month',
    'income_category_id',
    'income_title',
  ];

  double get monthlyIncome => _monthlyIncome;
  String get currency => _currency;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhotoPath => _userPhotoPath;
  double get budgetLimit => _budgetLimit;

  int get incomeDay => _incomeDay;
  String get lastIncomeMonth => _lastIncomeMonth;
  int? get incomeCategoryId => _incomeCategoryId;
  String get incomeTitle => _incomeTitle;

  bool get notificationsEnabled => _notificationsEnabled;
  List<String> get notificationTimes => _notificationTimes;

  bool get appLockEnabled => _appLockEnabled;

  /// Tekrarlayan gelir tam olarak ayarlanmış mı?
  bool get hasRecurringIncome =>
      _monthlyIncome > 0 && _incomeDay > 0 && _incomeCategoryId != null;

  SettingsProvider(this._prefs, this._session) {
    _loadDeviceSettings();
    _session.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Cihaza ait ayarları yükler
  void _loadDeviceSettings() {
    _currency = _prefs.getString('currency') ?? '₺';
    _userName = _prefs.getString('user_name') ?? '';
    _userEmail = _prefs.getString('user_email') ?? '';
    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
    _notificationTimes = _prefs.getStringList('notification_times') ?? ['12:30', '20:30'];
    _appLockEnabled = _prefs.getBool('app_lock_enabled') ?? false;

    _applyNotificationSettings();
  }

  /// Oturumdaki kullanıcı değiştiyse onun ayarlarını yükler
  void _onSessionChanged() {
    final userId = _session.userId;
    if (userId == _userId) return;
    _userId = userId;

    if (userId != null) _migrateLegacyKeys(userId);
    _loadUserSettings();
    notifyListeners();
  }

  /// Eski sürümde cihaz geneline kaydedilen ayarları ilk giriş yapan
  /// kullanıcıya taşır; diğer hesaplar bu değerleri devralmaz.
  void _migrateLegacyKeys(String userId) {
    for (final key in _userScopedKeys) {
      final value = _prefs.get(key);
      if (value == null) continue;
      final scopedKey = _scopedKey(key, userId);
      if (!_prefs.containsKey(scopedKey)) {
        if (value is double) {
          _prefs.setDouble(scopedKey, value);
        } else if (value is int) {
          _prefs.setInt(scopedKey, value);
        } else if (value is String) {
          _prefs.setString(scopedKey, value);
        }
      }
      _prefs.remove(key);
    }
  }

  void _loadUserSettings() {
    _monthlyIncome = _getUserValue<double>('monthly_income') ?? 0.0;
    _userPhotoPath = _getUserValue<String>('user_photo_path') ?? '';
    _budgetLimit = _getUserValue<double>('budget_limit') ?? _defaultBudgetLimit;
    _incomeDay = _getUserValue<int>('income_day') ?? 0;
    _lastIncomeMonth = _getUserValue<String>('last_income_month') ?? '';
    _incomeCategoryId = _getUserValue<int>('income_category_id');
    _incomeTitle = _getUserValue<String>('income_title') ?? _defaultIncomeTitle;
  }

  static String _scopedKey(String key, String userId) => 'user:$userId:$key';

  T? _getUserValue<T>(String key) {
    final userId = _userId;
    if (userId == null) return null;
    final value = _prefs.get(_scopedKey(key, userId));
    // Bazı platformlar tam sayı değerli double'ları int olarak döndürebilir
    if (T == double && value is num) return value.toDouble() as T;
    return value is T ? value : null;
  }

  /// Oturum yokken kullanıcıya özel ayar kalıcı olarak yazılmaz
  Future<void> _setUserValue(String key, Object value) async {
    final userId = _userId;
    if (userId == null) return;
    final scopedKey = _scopedKey(key, userId);
    if (value is double) {
      await _prefs.setDouble(scopedKey, value);
    } else if (value is int) {
      await _prefs.setInt(scopedKey, value);
    } else if (value is String) {
      await _prefs.setString(scopedKey, value);
    }
  }

  /// Bildirim ayarlarını NotificationService'e uygular
  void _applyNotificationSettings() {
    if (_notificationsEnabled) {
      final times = _notificationTimes.map((t) {
        final parts = t.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
      NotificationService().scheduleDailyReminders(times);
    } else {
      NotificationService().cancelAllNotifications();
    }
  }

  /// Aylık geliri günceller ve kaydeder
  Future<void> setMonthlyIncome(double income) async {
    _monthlyIncome = income;
    notifyListeners();
    await _setUserValue('monthly_income', income);
  }

  /// Aylık bütçe limitini günceller ve kaydeder
  Future<void> setBudgetLimit(double limit) async {
    _budgetLimit = limit;
    notifyListeners();
    await _setUserValue('budget_limit', limit);
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
    await _setUserValue('monthly_income', amount);
    await _setUserValue('income_day', day);
    await _setUserValue('income_category_id', categoryId);
    await _setUserValue('income_title', title);
  }

  /// Son otomatik gelir eklenen ayı kaydeder (YYYY-MM)
  Future<void> setLastIncomeMonth(String monthKey) async {
    _lastIncomeMonth = monthKey;
    notifyListeners();
    await _setUserValue('last_income_month', monthKey);
  }

  /// Para birimini günceller ve kaydeder
  Future<void> setCurrency(String currency) async {
    _currency = currency;
    notifyListeners();
    await _prefs.setString('currency', currency);
  }

  /// Kullanıcı adını günceller ve kaydeder
  Future<void> setUserName(String name) async {
    _userName = name;
    notifyListeners();
    await _prefs.setString('user_name', name);
  }

  /// Kullanıcı e-postasını günceller ve kaydeder
  Future<void> setUserEmail(String email) async {
    _userEmail = email;
    notifyListeners();
    await _prefs.setString('user_email', email);
  }

  /// Kullanıcı profil fotoğrafı yolunu günceller ve kaydeder
  Future<void> setUserPhotoPath(String path) async {
    _userPhotoPath = path;
    notifyListeners();
    await _setUserValue('user_photo_path', path);
  }

  /// Bildirim durumunu günceller ve kaydeder
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    _applyNotificationSettings();
    notifyListeners();
    await _prefs.setBool('notifications_enabled', enabled);
  }

  /// Bildirim saatlerini günceller ve kaydeder
  Future<void> setNotificationTimes(List<String> times) async {
    _notificationTimes = times;
    _applyNotificationSettings();
    notifyListeners();
    await _prefs.setStringList('notification_times', times);
  }

  /// Uygulama kilidi durumunu günceller ve kaydeder
  Future<void> setAppLockEnabled(bool enabled) async {
    _appLockEnabled = enabled;
    notifyListeners();
    await _prefs.setBool('app_lock_enabled', enabled);
  }
}
