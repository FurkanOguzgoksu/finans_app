import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/models/category.dart';
import 'package:finans_app/models/transaction.dart';
import 'package:finans_app/services/backup/json_backup_service.dart';

import '../helpers/fakes.dart';

void main() {
  group('JSON Backup Format Testleri', () {
    test('JSON yedek dosyasi dogru formatta olusturulmali', () {
      final Map<String, dynamic> mockBackupData = {
        'version': 1,
        'export_date': '2026-03-14T10:00:00.000',
        'categories': [
          {'id': 1, 'name': 'Maaş', 'type': 'gelir'}
        ],
        'transactions': [
          {
            'id': 1,
            'title': 'Test',
            'amount': 100.0,
            'type': 'gelir',
            'category_id': 1
          }
        ],
        'receipts': []
      };

      final jsonString = jsonEncode(mockBackupData);
      
      expect(jsonString, contains('"version":1'));
      expect(jsonString, contains('"categories":[{'));
      expect(jsonString, contains('"transactions":[{'));
    });

    test('Geri yukleme icin JSON dogru pars edilebilmeli', () {
      const jsonString = '{"version":1,"categories":[{"id":1,"name":"Maaş","type":"gelir"}]}';
      final parsedMap = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(parsedMap['version'], equals(1));
      expect(parsedMap['categories'][0]['name'], equals('Maaş'));
    });
  });

  group('JSON Geri Yukleme (restoreFromJson)', () {
    late FakeCategoryRepository categories;
    late FakeTransactionRepository transactions;
    late JsonBackupService service;

    setUp(() {
      categories = FakeCategoryRepository();
      transactions = FakeTransactionRepository();
      service = JsonBackupService(
        categoryRepository: categories,
        transactionRepository: transactions,
      );
    });

    String backupJson() => jsonEncode({
          'version': 2,
          'categories': [
            {'id': 10, 'name': 'Maaş', 'type': 'gelir'},
            {'id': 11, 'name': 'Kira', 'type': 'gider'},
          ],
          'transactions': [
            Transaction(
              id: 1,
              title: 'Ekim maaşı',
              amount: 30000,
              type: 'gelir',
              categoryId: 10,
              date: DateTime(2026, 10, 5),
            ).toMap(),
            Transaction(
              id: 2,
              title: 'Ekim kirası',
              amount: 12000,
              type: 'gider',
              categoryId: 11,
              date: DateTime(2026, 10, 1),
            ).toMap(),
          ],
        });

    test('Kategori ID leri hesaptaki karsiliklarina cevrilir', () async {
      // Hesapta "Maaş" zaten farklı bir ID ile var
      final existingId = await categories.insert(
        Category(name: 'Maaş', type: 'gelir'),
      );

      final result = await service.restoreFromJson(backupJson());

      expect(result.categories, 1); // Yalnızca "Kira" eklendi
      expect(result.transactions, 2);
      final kiraId = categories.items.firstWhere((c) => c.name == 'Kira').id;
      final maas = transactions.items.firstWhere((t) => t.title == 'Ekim maaşı');
      final kira = transactions.items.firstWhere((t) => t.title == 'Ekim kirası');
      expect(maas.categoryId, existingId);
      expect(kira.categoryId, kiraId);
    });

    test('Ayni yedek ikinci kez yuklenince kopya kayit olusmaz', () async {
      await service.restoreFromJson(backupJson());
      final second = await service.restoreFromJson(backupJson());

      expect(second.categories, 0);
      expect(second.transactions, 0);
      expect(categories.items, hasLength(2));
      expect(transactions.items, hasLength(2));
    });

    test('Gecersiz dosya hata verir', () async {
      expect(
        () => service.restoreFromJson('{"version":2}'),
        throwsFormatException,
      );
    });

    test('Disa aktarilan yedek geri yuklenebilir', () async {
      await categories.insert(Category(name: 'Market', type: 'gider'));
      await transactions.insert(
        Transaction(
          title: 'Market alışverişi',
          amount: 450.5,
          type: 'gider',
          categoryId: 1,
          date: DateTime(2026, 10, 20, 18, 30),
          items: [TransactionItem(name: 'Ekmek', amount: 15)],
        ),
      );
      final exported = await service.buildBackupJson();

      // Boş bir hesaba geri yükle
      final emptyCategories = FakeCategoryRepository();
      final emptyTransactions = FakeTransactionRepository();
      final result = await JsonBackupService(
        categoryRepository: emptyCategories,
        transactionRepository: emptyTransactions,
      ).restoreFromJson(exported);

      expect(result.transactions, 1);
      expect(emptyTransactions.items.single.amount, 450.5);
      expect(emptyTransactions.items.single.items!.single.name, 'Ekmek');
    });
  });
}
