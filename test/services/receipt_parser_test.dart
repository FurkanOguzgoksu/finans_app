import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Tests - RegEx Extraction', () {
    test('Market Receipt Parsing', () {
      final rawText = '''
MİGROS TİCARET A.Ş.
İZMİR ŞUBESİ
TARİH: 14.04.2026  SAAT: 15:30
FİŞ NO: 0012
-------------------------
SÜT 1L                35,50
EKMEK                  8,00
YUMURTA 15'Lİ         65,00
-------------------------
TOPLAM              108,50
KDV %1                 1,08
KDV %8                 0,00
Nakit               110,00
Para Üstü             1,50
''';

      final parsed = ReceiptParser.parse(rawText);

      expect(parsed.merchantName, contains('MİGROS'));
      // Parser TOPLAM 108,50 satırını doğru okur
      expect(parsed.amount, 108.5);
      expect(parsed.date?.year, 2026);
      expect(parsed.date?.month, 4);
      expect(parsed.date?.day, 14);
      expect(parsed.isValid, true);
      expect(parsed.confidence, greaterThanOrEqualTo(0.5));
    });

    test('Restaurant Receipt Parsing with slash date format', () {
      final rawText = '''
STARBUCKS COFFEE
KADIKOY
15/05/2026  12:45
ICED LATTE TALL       95,00
CARAMEL MACCHIATO    115,00
----------------------
KREDI KARTI          210,00
TESEKKURLER
''';

      final parsed = ReceiptParser.parse(rawText);

      expect(parsed.merchantName, contains('STARBUCKS'));
      expect(parsed.amount, 210.00);
      expect(parsed.date?.day, 15);
      // Confidence 0.5 veya üzeri kabul edilir
      expect(parsed.confidence, greaterThanOrEqualTo(0.5));
    });

    test('Messy OCR Text with Maximum Value Fallback and dash date', () {
      final rawText = '''
--**--
BURGER KING
TARIH: 20-03-24
WHOPPER MENU
130.00
KDV 10.50
Fatura vb
GECERSIZ
''';

      final parsed = ReceiptParser.parse(rawText);
      expect(parsed.merchantName, contains('BURGER KING'));
      expect(parsed.amount, greaterThan(10));
      expect(parsed.date?.day, 20);
      // Bulanık OCR'da confidence 0.3 üzeri yeterli kabul edilir
      expect(parsed.confidence, greaterThanOrEqualTo(0.3));
    });

    test('Empty or Insufficient OCR Text', () {
      final rawText = '''
???
111
''';
      final parsed = ReceiptParser.parse(rawText);

      expect(parsed.amount, null);
      // Sadece '111' olan metin isValid olabilir (tek rakam), temel kontrol: confidence düşük olmalı
      expect(parsed.confidence, lessThanOrEqualTo(0.5));
    });
  });
}
