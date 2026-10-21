import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/models/transaction.dart';
import 'package:finans_app/providers/transaction_provider.dart';

import '../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Transaction expense(double amount, DateTime date) => Transaction(
        title: 'Harcama',
        amount: amount,
        type: 'gider',
        categoryId: 1,
        date: date,
      );

  group('TransactionProvider', () {
    test('Aylik gider yalnizca icinde bulunulan ayi sayar', () async {
      final now = DateTime.now();
      final repository = FakeTransactionRepository();
      await repository.insert(expense(100, now));
      await repository.insert(expense(250, DateTime(now.year, now.month - 1, 15)));
      await repository.insert(expense(400, DateTime(now.year - 1, now.month, 1)));

      final provider = TransactionProvider(FakeSession('kullanici-a'), repository: repository);
      await provider.loadTransactions();

      expect(provider.totalExpense, 750); // Tüm zamanlar
      expect(provider.currentMonthExpense, 100); // Bütçe kartı bunu kullanır
    });

    test('Kayit hatasi cagirana iletilir', () async {
      final repository = FakeTransactionRepository()..failWrites = true;
      final provider = TransactionProvider(FakeSession('kullanici-a'), repository: repository);

      await expectLater(
        provider.addTransaction(expense(50, DateTime.now())),
        throwsException,
      );
    });

    test('Cikis yapilinca onceki kullanicinin islemleri temizlenir', () async {
      final repository = FakeTransactionRepository();
      await repository.insert(expense(100, DateTime.now()));
      final session = FakeSession('kullanici-a');
      final provider = TransactionProvider(session, repository: repository);
      await provider.loadTransactions();
      expect(provider.transactions, hasLength(1));

      session.logout();

      expect(provider.transactions, isEmpty);
      expect(provider.totalExpense, 0);
    });
  });
}
