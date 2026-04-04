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

      // Tüm blokları satır satır birleştir
      final buffer = StringBuffer();
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
        buffer.writeln(); // Bloklar arası boşluk
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
