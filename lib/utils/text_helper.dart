/// Metin yardımcıları
class TextHelper {
  /// Türkçe kurallarına göre küçük harfe çevirir.
  ///
  /// Dart'ın toLowerCase() metodu 'İ' harfini 'i̇' (noktalı i + birleşik nokta),
  /// 'I' harfini de 'i' yapar; bu yüzden "İŞ" araması "iş" ile eşleşmez.
  static String trLower(String text) {
    return text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
  }
}
