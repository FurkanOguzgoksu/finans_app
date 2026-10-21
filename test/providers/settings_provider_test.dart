import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_app/providers/settings_provider.dart';

import '../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider', () {
    test('Cihaz ayarlari (uygulama kilidi) olusturulur olusturulmaz okunabilir', () async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      final prefs = await SharedPreferences.getInstance();

      final settings = SettingsProvider(prefs, FakeSession());

      // Asenkron bekleme olmadan ilk frame'de doğru değer okunmalı
      expect(settings.appLockEnabled, isTrue);
    });

    test('Eski cihaz geneli ayarlar ilk giris yapan kullaniciya tasinir', () async {
      SharedPreferences.setMockInitialValues({
        'budget_limit': 5000.0,
        'monthly_income': 30000.0,
        'income_category_id': 3,
        'last_income_month': '2026-09',
      });
      final prefs = await SharedPreferences.getInstance();
      final session = FakeSession();
      final settings = SettingsProvider(prefs, session);

      session.login('kullanici-a');

      expect(settings.budgetLimit, 5000.0);
      expect(settings.monthlyIncome, 30000.0);
      expect(settings.incomeCategoryId, 3);
      expect(settings.lastIncomeMonth, '2026-09');
      expect(prefs.containsKey('budget_limit'), isFalse);
    });

    test('Kullaniciya ozel ayarlar hesaplar arasinda karismaz', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final session = FakeSession('kullanici-a');
      final settings = SettingsProvider(prefs, session);

      await settings.setBudgetLimit(2500.0);
      await settings.setRecurringIncomeConfig(
        amount: 20000,
        day: 15,
        categoryId: 7,
        title: 'Maaş',
      );

      // Başka hesap: önceki hesabın bütçesi ve gelir kategorisi gelmemeli
      session.login('kullanici-b');
      expect(settings.budgetLimit, 10000.0);
      expect(settings.incomeCategoryId, isNull);
      expect(settings.hasRecurringIncome, isFalse);

      // İlk hesaba dönünce ayarları geri gelir
      session.login('kullanici-a');
      expect(settings.budgetLimit, 2500.0);
      expect(settings.incomeCategoryId, 7);
    });
  });
}
