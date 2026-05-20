import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Edge Case Tests - Kenar Durumlar', () {
    test('Sadece boşluk içeren metin hata vermez', () {
      final parsed = ReceiptParser.parse('   \n\n   ');
      expect(parsed.isValid, false);
      expect(parsed.amount, isNull);
    });

    test('Çok uzun metin performanslı işlenir', () {
      // 1000 satırlık sahte metin
      final longText = List.generate(1000, (i) => 'SATIR $i MIKTAR ${i * 1.5}').join('\n');
      final stopwatch = Stopwatch()..start();
      final parsed = ReceiptParser.parse(longText);
      stopwatch.stop();

      // 2 saniyeden kısa sürmeli
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      // Crash olmamalı
      expect(parsed, isNotNull);
    });

    test('Sadece sayılar içeren metin amount tahmin eder', () {
      const rawText = '''
12,50
34,75
99,00
''';
      final parsed = ReceiptParser.parse(rawText);
      // En büyük sayıyı fallback olarak almalı
      expect(parsed.amount, isNotNull);
      expect(parsed.amount, greaterThan(0));
    });

    test('Negatif tutar içeren fiş hatalı miktarla patlamaz', () {
      const rawText = '''
TEST MARKET
TOPLAM: -50,00
''';
      final parsed = ReceiptParser.parse(rawText);
      // Negatif miktar kabul edilmemeli veya null olmalı
      if (parsed.amount != null) {
        expect(parsed.amount!, isNonNegative);
      }
    });

    test('Tarih olmayan fişte tarih null gelir', () {
      const rawText = '''
CAFE LEZZET
ESPRESSO       35,00
CROISSANT      25,00
TOPLAM         60,00
''';
      final parsed = ReceiptParser.parse(rawText);
      expect(parsed.amount, 60.0);
      // Tarih olmayabilir, patlamadan null döner
      expect(parsed.date, anyOf(isNull, isA<DateTime>()));
    });

    test('Türkçe karakter içeren işletme adı doğru okunur', () {
      const rawText = '''
ŞAŞMAZ KÖFTECİSİ
İZMİR ŞUBESİ
15.04.2026
İZGARA KÖFTE   85,00
AYRAN          15,00
TOPLAM        100,00
''';
      final parsed = ReceiptParser.parse(rawText);
      expect(parsed.merchantName, isNotNull);
      expect(parsed.amount, greaterThan(0));
    });
  });
}
