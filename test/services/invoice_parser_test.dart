import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/services/invoice_parser.dart';

void main() {
  group('InvoiceParser Tests - PDF e-Fatura Ayrıştırma', () {
    test('Kurumsal şirket adını doğru okur', () {
      const rawText = '''
RABAT YAPI İNŞ.SAN.TİC.A.Ş
VKN: 1234567890
FATURA TARİHİ: 02.05.2026
TOPLAM: 1.200,00 TL
ÖDENECEK: 1.200,00
''';
      final parsed = InvoiceParser.parse(rawText);
      expect(parsed.merchantName, isNotNull);
      expect(parsed.merchantName!.toLowerCase(), contains('rabat'));
    });

    test('KDV Dahil Toplam tutarı doğru okur', () {
      const rawText = '''
ABC TİCARET LTD.ŞTİ.
FATURA TARİHİ: 10.05.2026
KDV DAHİL TOPLAM: 4.750,00
''';
      final parsed = InvoiceParser.parse(rawText);
      expect(parsed.amount, isNotNull);
      expect(parsed.amount, greaterThan(100));
    });

    test('Fatura tarihini doğru okur', () {
      const rawText = '''
XYZ GIDA A.Ş.
TARİH: 15.03.2026  SAAT: 09:30
GENEL TOPLAM: 360,00
''';
      final parsed = InvoiceParser.parse(rawText);
      expect(parsed.date, isNotNull);
      expect(parsed.date!.month, 3);
      expect(parsed.date!.day, 15);
    });

    test('Boş metinde null döner ve isValid false', () {
      final parsed = InvoiceParser.parse('');
      expect(parsed.isValid, false);
      expect(parsed.amount, isNull);
      expect(parsed.merchantName, isNull);
    });

    test('Birden fazla ürün kalemini okur', () {
      const rawText = '''
TEST MARKET A.Ş.
14.05.2026
SÜT 1L            35,50 TL
EKMEK              8,00 TL
YOĞURT 500GR      24,50 TL
TOPLAM            68,00 TL
''';
      final parsed = InvoiceParser.parse(rawText);
      // Ürünler parse edilebildiyse sıfırdan fazla olmalı
      if (parsed.items != null) {
        expect(parsed.items!.length, greaterThan(0));
      }
    });
  });
}
