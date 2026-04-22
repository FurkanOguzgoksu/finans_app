import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR Servisi — Google ML Kit ile on-device metin tanıma
///
/// Fotoğraftan metin çıkarmak için kullanılır.
/// Sadece Android ve iOS platformlarında çalışır.
class OcrService {
  late final TextRecognizer _textRecognizer;

  OcrService() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Verilen [imagePath] dosyasındaki görüntüden metin tanır.
  ///
  /// Başarılı olursa tanınan ham metni döndürür.
  /// Metin bulunamazsa boş string döndürür.
  /// Hata oluşursa [OcrException] fırlatır.
  Future<String> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isEmpty) {
        return '';
      }

      // Tüm satırları serbest bir havuza çıkar
      final List<TextLine> allLines = [];
      for (final block in recognizedText.blocks) {
        allLines.addAll(block.lines);
      }

      // Yukarıdan aşağıya (Y eksenine) göre sırala
      allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      final buffer = StringBuffer();
      List<TextLine> currentRow = [];
      
      // Aynı satır sayılması için sapma payı (px). 
      // Çok yüksek değerler satırların birleşmesine (Adres + Marka) neden olur.
      const double yTolerance = 18.0; 

      for (final line in allLines) {
        if (currentRow.isEmpty) {
          currentRow.add(line);
        } else {
          // Mevcut satırın başlangıcı ile karşılaştır
          final diff = (line.boundingBox.top - currentRow.first.boundingBox.top).abs();
          if (diff <= yTolerance) {
            // Aynı yatay hizada sayılır
            currentRow.add(line);
          } else {
            // Y hizası bitti, mevcut satırı Soldan Sağa sıralayıp yaz
            currentRow.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
            buffer.writeln(currentRow.map((e) => e.text).join('   '));
            // Yeni satıra başla
            currentRow = [line];
          }
        }
      }

      // Kalan son satırı da yaz
      if (currentRow.isNotEmpty) {
        currentRow.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        buffer.writeln(currentRow.map((e) => e.text).join('   '));
      }

      return buffer.toString().trim();
    } catch (e) {
      throw OcrException('Metin tanıma sırasında hata oluştu: $e');
    }
  }

  /// Kaynakları serbest bırakır
  void dispose() {
    _textRecognizer.close();
  }
}

/// OCR işlemi sırasında oluşan hatalar için özel exception sınıfı
class OcrException implements Exception {
  final String message;
  OcrException(this.message);

  @override
  String toString() => 'OcrException: $message';
}
