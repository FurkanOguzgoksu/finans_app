import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiAdvisorService {
  static Future<String> getFinancialAdvice({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> expensesByCategory,
  }) async {
    // .env dosyası yoksa dotenv boş yüklenir; hiç yüklenemediyse env'e erişim hata verir
    final apiKey = dotenv.isInitialized ? dotenv.maybeGet('GEMINI_API_KEY') : null;

    if (apiKey == null || apiKey.isEmpty || apiKey == 'BURAYA_API_KEYINIZI_YAZIN') {
      throw Exception('API Anahtarı bulunamadı! Lütfen assets/env/.env dosyanıza GEMINI_API_KEY ekleyin.');
    }

    // gemini-1.5 modelleri kapatıldı; 'gemini-flash-latest' güncel Flash
    // modeline yönlenen takma addır
    final modelsToTry = [
      'gemini-2.5-flash',
      'gemini-flash-latest',
      'gemini-2.5-flash-lite',
    ];

    String? responseText;
    String? lastError;

    // Harcama verilerini metne dök
    final categoryBreakdown = expensesByCategory.entries
        .map((e) => '- ${e.key}: ₺${e.value.toStringAsFixed(2)}')
        .join('\n');

    final promptText = '''
Aşağıda kullanıcının bu ayki finansal özeti bulunmaktadır:

Toplam Gelir: ₺${totalIncome.toStringAsFixed(2)}
Toplam Gider: ₺${totalExpense.toStringAsFixed(2)}

Kategori Bazlı Harcamalar:
$categoryBreakdown

Sen profesyonel, cesaretlendirici ve dost canlısı bir yapay zeka finansal danışmanısın. Kullanıcının dilini (Türkçe) konuşuyorsun.
Lütfen aşağıdaki kurallara uyarak kullanıcıya finansal bir değerlendirme yap:
1. Kısa bir özet geç (Durumu iyi mi, yoksa bütçeyi aşmış mı?)
2. Harcama kategorilerine bakarak en çok para harcanan yerlerde tasarruf edebilmesi için 1-2 uygulanabilir ve pratik tavsiye ver.
3. Çıktını kısa, okunabilir ve Markdown formatında (kalın yazılar, emojiler ve listeler kullanarak) hazırla.
4. Çıktı en fazla 3-4 paragraf olsun, kullanıcıyı sıkma.
''';

    final content = [Content.text(promptText)];

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

        final response = await model.generateContent(content);
        
        if (response.text != null && response.text!.isNotEmpty) {
          responseText = response.text!.trim();
          break;
        }
      } catch (e) {
        final error = e.toString();
        lastError = error;
        // Eğer hata modeli bulamamak, 503 (yüksek talep) veya 429 ise diğer modele geç
        if (!error.contains('not found') &&
            !error.contains('v1beta') &&
            !error.contains('503') &&
            !error.contains('429')) {
           throw Exception('Yapay zeka hatası: $e');
        }
      }
    }

    if (responseText == null) {
      throw Exception('Yapay zeka yanıt oluşturamadı. Son Hata: $lastError');
    }

    return responseText;
  }
}
