import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/utils/currency_formatter.dart';
import 'package:finans_app/utils/date_helper.dart';
import 'package:finans_app/utils/text_helper.dart';

void main() {
  group('DateHelper.validDate', () {
    test('Gecerli tarihi dondurur, iki haneli yili tamamlar', () {
      expect(DateHelper.validDate(26, 4, 14), DateTime(2026, 4, 14));
      expect(DateHelper.validDate(2024, 2, 29), DateTime(2024, 2, 29));
    });

    test('Takvimde olmayan tarihi sonraki aya kaydirmak yerine reddeder', () {
      expect(DateHelper.validDate(2026, 2, 31), isNull);
      expect(DateHelper.validDate(2025, 2, 29), isNull);
      expect(DateHelper.validDate(2026, 13, 1), isNull);
    });

    test('Makul olmayan yili reddeder', () {
      expect(DateHelper.validDate(1999, 5, 5), isNull);
      expect(DateHelper.validDate(DateTime.now().year + 2, 5, 5), isNull);
    });
  });

  group('DateHelper.pickerBounds', () {
    test('Aralik disindaki baslangic tarihini kapsayacak sekilde genisletir', () {
      final first = DateTime(2020);
      final last = DateTime(2026, 10, 21);

      final future = DateHelper.pickerBounds(DateTime(2027, 1, 5), first: first, last: last);
      expect(future.first, first);
      expect(future.last, DateTime(2027, 1, 5));

      final past = DateHelper.pickerBounds(DateTime(2019, 3, 1), first: first, last: last);
      expect(past.first, DateTime(2019, 3, 1));
      expect(past.last, last);
    });
  });

  group('TextHelper.trLower', () {
    test('Turkce buyuk harfleri dogru kucultur', () {
      expect(TextHelper.trLower('İŞ BANKASI'), 'iş bankası');
      expect(TextHelper.trLower('KIRTASİYE'), 'kırtasiye');
      expect(TextHelper.trLower('İŞ BANKASI').contains(TextHelper.trLower('iş')), isTrue);
    });
  });

  group('CurrencyInputFormatter', () {
    final formatter = CurrencyInputFormatter();

    test('Binlik ayiriciyla bicimlendirir', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1234567,5'),
      );
      expect(result.text, '1.234.567,5');
    });

    test('Cok uzun giriste hata vermez, onceki degeri korur', () {
      const oldValue = TextEditingValue(text: '123');
      final result = formatter.formatEditUpdate(
        oldValue,
        const TextEditingValue(text: '99999999999999999999999'),
      );
      expect(result.text, '123');
    });
  });
}
