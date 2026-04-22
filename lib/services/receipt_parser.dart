import '../models/parsed_receipt.dart';
import '../models/transaction.dart';

/// OCR'dan gelen ham metni (raw text) analiz edip anlamlı finansal veri (Tarih, Tutar, Kalemler, İşletme Adı) çıkartan sınıf.
class ReceiptParser {
  /// Verilen ham metni satır satır analiz eder ve [ParsedReceipt] nesnesi döndürür.
  static ParsedReceipt parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedReceipt(rawText: rawText);
    }

    final lines = rawText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    String? merchantName;
    DateTime? receiptDate;
    double? totalAmount;
    List<TransactionItem> items = [];

    // 1. İşletme Adı (Merchant Name) Bulma
    // Öncelikli markalar sözlüğü
    const knownBrands = ['BIM', 'A101', 'SOK', 'MIGROS', 'CARREFOUR', 'TARIM KREDI', 'STARBUCKS', 'KAHVE DUNYASI', 'KOCTAS', 'TEKNOSA', 'MEDI MARKT'];
    
    // İşletme adı olamayacak bariz adres veya iletişim kelimeleri (Bütünsel kelimelerle karışmaması için kısa harfli ekler spesifikleştirildi)
    final addressKeywords = ['MAH.', 'MAHALLE', 'CAD.', 'CADDE', 'CD.', 'SOK.', 'SOKAK', 'SK.', 'NO:', ' BULVAR ', 'BLV', 'ILCE', 'İLÇE', 'YOLU', 'KAVŞAĞI', 'KAYACAN', 'ARTUKLU', 'MARDIN', 'MARDİN', 'TEL:', 'TEL ', 'TELEFON', 'FAX', 'FAKS', 'EMAIL', 'E-MAIL', 'WEB', 'VD', 'V.D', 'VERGİ', 'VERGI DAIRESI'];
    final junkKeywords = ['E-ARSIV', 'E-ARŞİV', 'FATURA', 'SATIŞ FİŞİ', 'SATIS FISI', 'YM NO', 'TARIH', 'TARİH', 'SAAT', 'FİŞ NO', 'FIS NO', 'TKN:', 'TRH:'];

    // Önce bilinen büyük markaları ara (En yüksek öncelik)
    for (int i = 0; i < lines.length && i < 15; i++) {
        final upper = lines[i].toUpperCase();
        
        // BIM, A101 gibi markaları regex ile daha güvenli ara (BIM veya BİM)
        final bool isBim = upper.contains(RegExp(r'B[Iİ]M'));
        final bool isA101 = upper.contains('A101');
        final bool isSok = upper.contains(RegExp(r'S[OÖ]K'));
        final bool isMigros = upper.contains('MIGROS') || upper.contains('MİGROS');
        
        if (isBim || isA101 || isSok || isMigros || knownBrands.any((b) => upper.contains(b))) {
            String foundBrand = '';
            if (isBim) foundBrand = 'BIM';
            else if (isA101) foundBrand = 'A101';
            else if (isSok) foundBrand = 'SOK';
            else if (isMigros) foundBrand = 'MIGROS';
            else foundBrand = knownBrands.firstWhere((b) => upper.contains(b));

            // Markayı bulduğumuz satırın başındaki çöpleri (adres vs.) temizle
            int brandStart = upper.indexOf(foundBrand);
            if (brandStart > 0) {
               merchantName = lines[i].substring(brandStart);
            } else {
               merchantName = lines[i];
            }
            break;
        }
    }

    // Eğer bilinen marka yoksa, adres ve junk içermeyen ilk düzgün satırı al
    if (merchantName == null) {
      for (int i = 0; i < lines.length && i < 10; i++) {
        final line = lines[i];
        final upper = line.toUpperCase().replaceAll('.', ''); // Noktaları temizleyip karşılaştır
        
        final onlySymbolsAndNumbers = RegExp(r'^[\d\s.,:*#\-+/]+$');
        if (onlySymbolsAndNumbers.hasMatch(line)) continue;
        if (line.length < 2) continue;

        bool isAddress = addressKeywords.any((kw) => upper.contains(kw));
        bool isJunk = junkKeywords.any((kw) => upper.contains(kw));
        
        if (isAddress || isJunk) continue;

        merchantName = line;
        break;
      }
    }

    if (merchantName != null) {
      // (Önceden ticari ünvanları siliyorduk, artık fişteki orijinal unvanıyla bırakıyoruz)
          
      // Eğer temizleme sonrası adres kalıntısı varsa onları da süz ama satırı tamamen silme
      for (var kw in addressKeywords) {
          final upName = merchantName!.toUpperCase().replaceAll('.', '');
          if (upName.contains(kw)) {
             int idx = upName.indexOf(kw);
             // Orijinal metinden o indekse kadar olan kısmı al
             if (idx > 0) {
                merchantName = merchantName!.substring(0, idx).trim();
             }
          }
      }
      
      // Marka isminin önündeki bölge eklerini temizle (ARTUKLU BIM -> BIM)
      merchantName = merchantName!.replaceAll(RegExp(r'^(ARTUKLU|MARDIN|MARDİN|KAYACAN)\s+', caseSensitive: false), '').trim();
      
      // En sonda kalan gereksiz noktalama işaretlerini (virgül, iki nokta, tire vb.) sil
      // (Noktayı sildirmedik ki A.Ş. veya LTD. ŞTİ. bozulmasın)
      merchantName = merchantName!.replaceAll(RegExp(r'[,\-:;\s]+$'), '');
    }
    
    if (merchantName != null && merchantName!.length < 2) merchantName = null;

    // 2. Tarih ve Saat Bulma
    final dateRegExp = RegExp(r'(\d{2})[./-](\d{2})[./-](\d{4}|\d{2})');
    // Saat regex'i: gerçek saat/dakika aralığını kontrol eder (0-23 saat, 0-59 dakika)
    // Ayrıca satırın SAAT kelimesi içermesi VEYA tarih satırıyla aynı veya bitişik olması gerekir
    final timeRegExp = RegExp(r'(?:^|\D)(([01]?\d|2[0-3]):([0-5]\d))(?!\d)');

    for (var line in lines) {
      if (receiptDate == null) {
        final match = dateRegExp.firstMatch(line);
        if (match != null) {
          try {
            int day = int.parse(match.group(1)!);
            int month = int.parse(match.group(2)!);
            int year = int.parse(match.group(3)!);
            if (year < 100) year += 2000;
            if (day > 0 && day <= 31 && month > 0 && month <= 12) {
              receiptDate = DateTime(year, month, day);
            }
          } catch (_) {}
        }
      }
    }

    int hour = DateTime.now().hour;
    int minute = DateTime.now().minute;
    for (var line in lines) {
      final upperLine = line.toUpperCase();
      // Saat bilgisini yalnızca açıkça saat/zaman içeren satırlarda ara:
      // - Satır 'SAAT' veya 'TRH' veya 'TARIH' kelimesi içeriyor
      // - Veya satırda hem tarih hem saat var (örn: 14.04.2026 10:30)
      // - Veya satır neredeyse tamamen saat formatındadır (örn: "10:30")
      final bool isTimeLine = upperLine.contains('SAAT') ||
          upperLine.contains('TRH') ||
          upperLine.contains('TARIH') ||
          upperLine.contains('TARİH') ||
          dateRegExp.hasMatch(line) ||
          RegExp(r'^\s*\d{1,2}:\d{2}\s*$').hasMatch(line);
      if (!isTimeLine) continue;

      final match = timeRegExp.firstMatch(line);
      if (match != null) {
        try {
          int h = int.parse(match.group(2)!);
          int m = int.parse(match.group(3)!);
          if (h >= 0 && h < 24 && m >= 0 && m < 60) {
            hour = h;
            minute = m;
            break;
          }
        } catch (_) {}
      }
    }

    if (receiptDate != null) {
      receiptDate = DateTime(receiptDate.year, receiptDate.month, receiptDate.day, hour, minute);
    } else {
      receiptDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
    }

    // 3. Kalemleri (Items) ve Toplam Tutarı Bulma
    final targetKeywords = [
      'TOPLAM', 'T0PLAM', 'GENEL TOPLAM', 'ODENEN', 'ÖDENEN'
    ];
    
    // Ürün kalemi olamayacak satırlar için kara liste
    final ignoreKeywordsForItems = [
      ...targetKeywords,
      'TOP:', 'TOP.', 'TOPKDV', 'FİŞ', 'FIS', 'KDV', 'KASİYE', 'ARA', 'PARA', 'TEŞEKKÜR', 'TESSEKKUR', 'NO:', 'TARIH', 'TARİH', 'İNDİRİM', 'INDIRIM', 'KART', 'POS', 'PROVIZ', 'PROVİZ', 'T:SORI', 'B:', 'MÜŞTERİ', 'ALINAN', 'KREDİ', 'KREDI', 'NAKİT', 'NAKIT', 'SAAT',
    ];

    // Yıldızlı veya yanaşık fiyatları algılayabilmek için word boundary (\b) kaldırıldı
    final priceRegExp = RegExp(r'(\d{1,5})[.,]\s?(\d{2})(?!\d)');

    double currentQty = 1.0; // Anlık miktar havuzu

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upperLine = line.toUpperCase();
      
      bool isTarget = targetKeywords.any((kw) => upperLine.contains(kw)) && !upperLine.contains('KDV') && !upperLine.contains('ARA');
      bool hasDate = dateRegExp.hasMatch(line);
      // Saat satırı mı? (Yalnızca SAAT/TRH/TARİH içeren ya da sade HH:MM olan satırlar)
      bool hasTimeOnly = (upperLine.contains('SAAT') || upperLine.contains('TRH') ||
          RegExp(r'^\s*\d{1,2}:\d{2}\s*$').hasMatch(line)) &&
          !priceRegExp.hasMatch(line);
      bool isIgnoredForItem = ignoreKeywordsForItems.any((kw) => upperLine.contains(kw)) || hasDate || hasTimeOnly;

      // Fişlerde asıl ürün-tutar veya genel toplam fiyatı her zaman satırın EN SONUNDADIR.
      final matches = priceRegExp.allMatches(line);
      final match = matches.isNotEmpty ? matches.last : null;

      // Eğer tutar ibaresiyse
      if (isTarget) {
         if (match != null && totalAmount == null) {
            String pStr = '${match.group(1)}.${match.group(2)}';
            double? parsed = double.tryParse(pStr);
            if (parsed != null && parsed > 0) {
              totalAmount = parsed;
            }
         } else if (i + 1 < lines.length && totalAmount == null) {
            final nextMatches = priceRegExp.allMatches(lines[i+1]);
            final nextMatch = nextMatches.isNotEmpty ? nextMatches.last : null;
            if (nextMatch != null) {
               String pStr = '${nextMatch.group(1)}.${nextMatch.group(2)}';
               double? parsed = double.tryParse(pStr);
               if (parsed != null && parsed > 0) {
                 totalAmount = parsed;
               }
            }
         }
      } 
      // Kalem Satırı Tahmini
      else if (!isIgnoredForItem && match != null) {
         String pStr = '${match.group(1)}.${match.group(2)}';
         double? parsed = double.tryParse(pStr);
         if (parsed != null && parsed > 0) {
            // İsim Çıkarımı: Satırdan fiyatı ve fişteki yıldızları temizle
            String rawName = line.replaceAll(match.group(0)!, '').replaceAll('*', '').trim();
            final nameMatches = RegExp(r'[A-Za-z0-9ÇĞİÖŞÜçğıöşü%/\-&.,]+').allMatches(rawName);
            String name = nameMatches.map((m) => m.group(0)).join(' ').trim();
            
            // O satırdaki harflerden sadece birim veya çok kısa şeyler kaldıysa (örn: 2,25 KGX6,00 t %1) üst satırdaki gerçek isme bak (örn: ELMA)
            String rawLettersOnly = name.toUpperCase().replaceAll(RegExp(r'[\d.,*%\s₺T]+'), '');
            bool isJunkName = rawLettersOnly.length <= 2 || ['KGX', 'ADX', 'KG', 'AD', 'GR', 'LT', 'X'].contains(rawLettersOnly);
            
            if (isJunkName && i > 0) {
               String prevLine = lines[i - 1];
               if (!ignoreKeywordsForItems.any((kw) => prevLine.toUpperCase().contains(kw)) &&
                   !targetKeywords.any((kw) => prevLine.toUpperCase().contains(kw))) {
                   final prevNameMatches = RegExp(r'[A-Za-z0-9ÇĞİÖŞÜçğıöşü%/\-&.,]+').allMatches(prevLine);
                   String prevName = prevNameMatches.map((m) => m.group(0)).join(' ').trim();
                   
                   // Eğer önceki satır da bir fiyat vs içermiyorsa saf isim onda demektir
                   if (prevName.length > 2 && !RegExp(r'\d+[.,]\d+').hasMatch(prevName)) {
                       name = prevName;
                   }
               }
            }
            
            // Fişte sağda kalan KDV rakamlarını temizle (Sadece boşluk sonrası ve satır sonundaki 1-3 haneli sayıları hedef alır)
            // Bu sayede '2L' veya '200 LU' gibi isim içindeki sayılar korunur.
            name = name.replaceAll(RegExp(r'\s+([zZ%]?\d{1,2}0?)$', caseSensitive: false), '').trim();

            String checkName = name.toUpperCase();
            String filterName = checkName.replaceAll(RegExp(r'[\d.,*]+'), '').trim();
            
            // "2 ad x 15,50" gibi miktar ara satırlarını fiş kalemi saymak hatalıdır
            if (filterName == "AD X" || filterName == "ADX" || filterName == "AD" || 
                filterName.contains("ADET X") || filterName.contains("X AD") || filterName == "B S" ||
                filterName.length <= 2) {
               
               // Eğer bu bir miktar satırıysa içindeki sayıyı (adeti) çekip hafızaya al
               final adetMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:AD|KG|GR|X|adet|L\b)', caseSensitive: false).firstMatch(line);
               if (adetMatch != null) {
                   String nStr = adetMatch.group(1)!.replaceAll(',', '.');
                   currentQty = double.tryParse(nStr) ?? 1.0;
               }
               
               continue; // bu satırı listeye ekleme
            }

            // Bazen miktar (örn: 2,25 KG) fiyat ile aynı satırda yer alabilir. Bu durumda satır içinden miktarı avla.
            final inlineAdetMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:AD|KG|GR|X|adet|L\b)', caseSensitive: false).firstMatch(line);
            if (inlineAdetMatch != null) {
                 String nStr = inlineAdetMatch.group(1)!.replaceAll(',', '.');
                 double? pQty = double.tryParse(nStr);
                 if (pQty != null && pQty > 0) {
                     currentQty = pQty;
                 }
            }

            items.add(TransactionItem(name: name, amount: parsed, quantity: currentQty));
            currentQty = 1.0; // Adet kullanıldı, varsayılana sıfırla
         }
      }
    }

    // Ana toplam bulunamadıysa Fallback mekanizması
    if (totalAmount == null) {
      if (items.isNotEmpty) {
        // Eğer kalem tarayabildiysek, fişteki en pahalı kalemi 'Toplam' ücreti varsayalım
        double maxPrice = 0;
        for (var i in items) {
          if (i.amount > maxPrice) maxPrice = i.amount;
        }
        if (maxPrice > 0) totalAmount = maxPrice;
        // En büyük kalemi sepetten çıkar (çünkü o genel toplamdır)
        items.removeWhere((element) => element.amount == maxPrice);
      } else {
        // En kötü senaryo, düz metin price parse et
        double maxPrice = 0;
        for (var line in lines) {
          final matches = priceRegExp.allMatches(line);
          for (var m in matches) {
             String pStr = '${m.group(1)}.${m.group(2)}';
             double? val = double.tryParse(pStr);
             if (val != null && val > maxPrice && val < 50000.0) {
                maxPrice = val;
             }
          }
        }
        if (maxPrice > 0) totalAmount = maxPrice;
      }
    }

    return ParsedReceipt(
      amount: totalAmount,
      date: receiptDate,
      merchantName: merchantName,
      rawText: rawText,
      items: items.isEmpty ? null : items, // Boşsa null gönder
    );
  }
}
