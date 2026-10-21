/// Tarih doğrulama ve tarih seçici yardımcıları
class DateHelper {
  /// OCR/AI ile okunan gün-ay-yıl değerlerinden geçerli bir tarih üretir.
  ///
  /// 31.02 gibi takvimde olmayan tarihleri (DateTime bunları sonraki aya
  /// kaydırır) ve makul aralık dışındaki yılları reddeder; bu durumda null döner.
  static DateTime? validDate(int year, int month, int day) {
    if (year < 100) year += 2000;
    final now = DateTime.now();
    if (year < 2000 || year > now.year + 1) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// showDatePicker, initialDate [first]-[last] aralığının dışındaysa hata verir.
  /// Bu metot aralığı seçili tarihi kapsayacak şekilde genişletir.
  static ({DateTime first, DateTime last}) pickerBounds(
    DateTime initial, {
    required DateTime first,
    required DateTime last,
  }) {
    return (
      first: initial.isBefore(first) ? initial : first,
      last: initial.isAfter(last) ? initial : last,
    );
  }
}
