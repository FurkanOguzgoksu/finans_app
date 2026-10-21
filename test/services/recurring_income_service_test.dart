import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_app/providers/settings_provider.dart';
import 'package:finans_app/providers/transaction_provider.dart';
import 'package:finans_app/services/recurring_income_service.dart';

import '../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTransactionRepository repository;
  late SettingsProvider settings;
  late TransactionProvider txProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final session = FakeSession('kullanici-a');
    repository = FakeTransactionRepository();
    settings = SettingsProvider(prefs, session);
    txProvider = TransactionProvider(session, repository: repository);
  });

  Future<void> configureIncome({int day = 5}) {
    return settings.setRecurringIncomeConfig(
      amount: 30000,
      day: day,
      categoryId: 1,
      title: 'Maaş',
    );
  }

  group('RecurringIncomeService', () {
    test('Gelir gunu gelince ayda bir kez eklenir', () async {
      await configureIncome();
      final now = DateTime(2026, 10, 21);

      final first = await RecurringIncomeService.checkAndAdd(
        settings: settings,
        txProvider: txProvider,
        now: now,
      );
      final second = await RecurringIncomeService.checkAndAdd(
        settings: settings,
        txProvider: txProvider,
        now: now,
      );

      expect(first, isTrue);
      expect(second, isFalse);
      expect(repository.items, hasLength(1));
      expect(repository.items.single.date, DateTime(2026, 10, 5));
      expect(settings.lastIncomeMonth, '2026-10');
    });

    test('Gelir gunu henuz gelmediyse eklenmez', () async {
      await configureIncome(day: 25);

      final added = await RecurringIncomeService.checkAndAdd(
        settings: settings,
        txProvider: txProvider,
        now: DateTime(2026, 10, 21),
      );

      expect(added, isFalse);
      expect(repository.items, isEmpty);
    });

    test('Ileri bir ay icin elle eklenmis gelir o aya kadar tekrar eklenmez', () async {
      await configureIncome();
      await settings.setLastIncomeMonth('2026-11');

      final added = await RecurringIncomeService.checkAndAdd(
        settings: settings,
        txProvider: txProvider,
        now: DateTime(2026, 10, 21),
      );

      expect(added, isFalse);
    });

    test('Ay sonu duzeltmesi: 31. gun Subat ayinda son gune eklenir', () async {
      await configureIncome(day: 31);

      await RecurringIncomeService.checkAndAdd(
        settings: settings,
        txProvider: txProvider,
        now: DateTime(2026, 2, 28),
      );

      expect(repository.items.single.date, DateTime(2026, 2, 28));
    });

    test('Kayit basarisiz olursa ay islenmis sayilmaz', () async {
      await configureIncome();
      repository.failWrites = true;

      await expectLater(
        RecurringIncomeService.checkAndAdd(
          settings: settings,
          txProvider: txProvider,
          now: DateTime(2026, 10, 21),
        ),
        throwsException,
      );
      expect(settings.lastIncomeMonth, isEmpty);
    });
  });
}
