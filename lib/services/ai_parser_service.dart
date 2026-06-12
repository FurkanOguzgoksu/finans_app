import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/parsed_receipt.dart';
import '../models/transaction.dart';

class AiParserService {
  static Future<ParsedReceipt> parse(String rawText) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty || apiKey == 'BURAYA_API_KEYINIZI_YAZIN') {
      throw Exception('API Anahtarı bulunamadı! Lütfen assets/.env dosyanıza GEMINI_API_KEY ekleyin.');
    }

    final modelsToTry = [
      'gemini-2.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-pro-latest',
      'gemini-2.0-flash'
    ];

    String? lastError;
    String? responseText;

    final content = [Content.text('OCR TEXT:\n"""\n$rawText\n"""')];

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          systemInstruction: Content.system('''
You are a receipt and invoice parsing AI.

Extract structured financial data from the OCR/PDF text below.

STRICT RULES:
- Return ONLY valid JSON. No explanation.
- Do NOT use markdown.
- Merchant name is NOT address.
- Merchant is usually at the top, before date/time.
- Ignore lines with:
  - BANK, IBAN, POS, CARD, TERMINAL, REF, APPROVAL CODE
  - TOTAL, KDV, TAX, ARA TOPLAM, İŞLEM TUTARI
  - ADDRESS, TEL, VERGİ, VKN, TCKN
  - FİŞ HARCAMASI, SATIŞ FİŞİ, FATURA
- Choose TOTAL as:
  - GENEL TOPLAM / ÖDENECEK / İŞLEM TUTARI / ÖDENEN
- Ignore those lines in items list.
- Fix OCR errors (T0PLAM -> TOPLAM, DONER -> DÖNER, COSKUN -> COŞKUN)
- If unsure -> null

OUTPUT FORMAT:

{
  "merchantName": null,
  "date": null,
  "time": null,
  "totalAmount": null,
  "taxAmount": null,
  "paymentMethod": null,
  "items": [
    {
      "name": null,
      "quantity": 1,
      "unitPrice": null,
      "totalPrice": null
    }
  ]
}
'''),
        );

        final response = await model.generateContent(content);
        
        if (response.text != null && response.text!.isNotEmpty) {
          responseText = response.text!.trim();
          break; // Başarılı olduysa döngüden çık
        }
      } catch (e) {
        lastError = e.toString();
        // Eğer hata modeli bulamamak, 503 (yüksek talep) veya 429 ise diğer modele geç, değilse fırlat
        if (!lastError!.contains('not found') && 
            !lastError!.contains('v1beta') && 
            !lastError!.contains('503') && 
            !lastError!.contains('429')) {
           throw Exception('Yapay zeka hatası: $e');
        }
      }
    }

    if (responseText == null) {
      throw Exception('Yapay zeka ayrıştırma hatası: Model bulunamadı. Son Hata: $lastError');
    }

    try {
      
      // Markdown kalıntılarını temizle (eğer AI markdown döndürürse diye önlem)
      if (responseText.startsWith('```json')) {
        responseText = responseText.substring(7);
      }
      if (responseText.startsWith('```')) {
        responseText = responseText.substring(3);
      }
      if (responseText.endsWith('```')) {
        responseText = responseText.substring(0, responseText.length - 3);
      }
      responseText = responseText.trim();

      final data = json.decode(responseText) as Map<String, dynamic>;

      return _mapJsonToParsedReceipt(data, rawText);
    } catch (e) {
      throw Exception('Yapay zeka ayrıştırma hatası: $e');
    }
  }

  static ParsedReceipt _mapJsonToParsedReceipt(Map<String, dynamic> data, String rawText) {
    // Tarih ve saat birleştirme
    DateTime? parsedDate;
    if (data['date'] != null) {
      // Date format beklentisi: DD-MM-YYYY, YYYY-MM-DD vb.
      try {
        final dateStr = data['date'].toString().replaceAll('/', '-').replaceAll('.', '-');
        final dateParts = dateStr.split('-');
        
        if (dateParts.length == 3) {
          int year, month, day;
          
          if (dateParts[0].length == 4) {
             // YYYY-MM-DD
             year = int.parse(dateParts[0]);
             month = int.parse(dateParts[1]);
             day = int.parse(dateParts[2]);
          } else {
             // DD-MM-YYYY
             day = int.parse(dateParts[0]);
             month = int.parse(dateParts[1]);
             year = int.parse(dateParts[2]);
          }

          if (year < 100) year += 2000;

          int hour = 0;
          int minute = 0;
          if (data['time'] != null) {
            final timeParts = data['time'].toString().split(':');
            if (timeParts.length >= 2) {
              hour = int.parse(timeParts[0]);
              minute = int.parse(timeParts[1]);
            }
          }
          parsedDate = DateTime(year, month, day, hour, minute);
        }
      } catch (e) {
        // Parse edilemezse boş kalsın
      }
    }

    // Tutar
    double? amount;
    if (data['totalAmount'] != null) {
       amount = double.tryParse(data['totalAmount'].toString().replaceAll(',', '.'));
    }

    // Ürünler
    List<TransactionItem>? items;
    if (data['items'] != null && data['items'] is List) {
      items = [];
      for (var item in data['items']) {
        if (item['name'] == null) continue;
        
        final quantity = item['quantity'] != null 
            ? double.tryParse(item['quantity'].toString().replaceAll(',', '.')) ?? 1.0 
            : 1.0;
            
        final totalPrice = item['totalPrice'] != null 
            ? double.tryParse(item['totalPrice'].toString().replaceAll(',', '.')) ?? 0.0 
            : 0.0;
            
        items.add(TransactionItem(
          name: item['name'].toString(),
          amount: totalPrice,
          quantity: quantity,
        ));
      }
    }

    return ParsedReceipt(
      amount: amount,
      date: parsedDate,
      merchantName: data['merchantName']?.toString(),
      rawText: rawText,
      items: items?.isEmpty == true ? null : items,
    );
  }
}
