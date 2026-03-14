import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/models/transaction.dart';

void main() {
  group('Transaction Model & Data Testleri', () {
    test('Transaction nesnesi toMap ile dogru JSON/Map uretmeli', () {
      final date = DateTime(2026, 3, 14, 10, 0);
      final t = Transaction(
        id: 1,
        title: 'Market',
        amount: 250.5,
        type: 'gider',
        categoryId: 2,
        date: date,
        createdAt: date,
      );

      final map = t.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Market');
      expect(map['amount'], 250.5);
      expect(map['type'], 'gider');
      expect(map['category_id'], 2);
    });

    test('Map verisi fromMap ile dogru Transaction nesnesine donusmeli', () {
      final Map<String, dynamic> map = {
        'id': 2,
        'title': 'Maaş',
        'amount': 5000.0,
        'type': 'gelir',
        'category_id': 1,
        'date': '2026-03-14T10:00:00.000',
        'created_at': '2026-03-14T10:00:00.000',
      };

      final t = Transaction.fromMap(map);

      expect(t.id, 2);
      expect(t.title, 'Maaş');
      expect(t.amount, 5000.0);
      expect(t.type, 'gelir');
    });
  });
}
