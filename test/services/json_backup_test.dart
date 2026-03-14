import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

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
}
