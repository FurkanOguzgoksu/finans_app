import '../models/parsed_receipt.dart';
import '../models/transaction.dart';
import '../utils/date_helper.dart';

class InvoiceParser {
  static ParsedReceipt parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedReceipt(rawText: rawText);
    }

    final lines = _prepareLines(rawText);

    final merchantName = _extractMerchantName(lines);
    final receiptDate = _extractDateTime(lines);
    final items = _extractItems(lines);
    final totalAmount = _extractTotalAmount(lines, items);

    return ParsedReceipt(
      amount: totalAmount,
      date: receiptDate,
      merchantName: merchantName,
      rawText: rawText,
      items: items.isEmpty ? null : items,
    );
  }

  static List<String> _prepareLines(String rawText) {
    return rawText
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static String _normalizeForSearch(String text) {
    return text
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('ı', 'I')
        .replaceAll('Ö', 'O')
        .replaceAll('Ü', 'U')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ç', 'C')
        .replaceAll('₺', ' TL ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isAddressLine(String line) {
    final n = _normalizeForSearch(line);

    final addressWords = [
      'MAH',
      'MAHALLE',
      'CAD',
      'CADDE',
      'SOK',
      'SOKAK',
      'SK',
      'BULVAR',
      'BLV',
      'NO:',
      'APT',
      'DAIRE',
      'DAİRE',
      'ILCE',
      'İLÇE',
      'MERKEZ',
      'YOLU',
      'KAT:',
      'MARDIN',
      'ISTANBUL',
      'ANKARA',
      'KONYA',
      'IZMIR',
    ];

    final hasAddressWord = addressWords.any((w) => n.contains(w));
    final hasDoorNo =
        RegExp(r'\bNO\s*[:.]?\s*\d+', caseSensitive: false).hasMatch(n);
    final hasPostal = RegExp(r'\b\d{5}\b').hasMatch(n);

    return hasAddressWord || hasDoorNo || hasPostal;
  }

  static bool _isBankInfoLine(String line) {
    final n = _normalizeForSearch(line);

    final bankWords = [
      'BANKA',
      'BANK',
      'IBAN',
      'HESAP NO',
      'HESAPNO',
      'SUBE',
      'ŞUBE',
      'SWIFT',
      'BIC',
      'POS',
      'KART',
      'KREDI KARTI',
      'KREDİ KARTI',
      'BANKA KARTI',
      'VISA',
      'MASTERCARD',
      'MAESTRO',
      'TROY',
      'PROVIZYON',
      'PROVİZYON',
      'PROVIZ',
      'PROVİZ',
      'ONAY KODU',
      'REFERANS',
      'REF NO',
      'TERMINAL',
      'TERMINAL NO',
      'ISYERI NO',
      'İŞYERİ NO',
      'TAHSILAT',
      'TAHSİLAT',
      'EKU NO',
      'Z NO',
      'BATCH',
      'SLIP',
    ];

    final hasBankWord = bankWords.any((w) => n.contains(_normalizeForSearch(w)));

    final hasIbanLike = RegExp(
      r'\bTR\d{2}\s?\d{4}\s?\d{4}',
      caseSensitive: false,
    ).hasMatch(n);

    final hasMaskedCard = RegExp(
      r'(\*{2,}|X{2,}|\d{4})\s?(\*{2,}|X{2,})\s?(\*{2,}|X{2,})\s?\d{4}',
      caseSensitive: false,
    ).hasMatch(n);

    return hasBankWord || hasIbanLike || hasMaskedCard;
  }


  static bool _isTotalLine(String line) {
    final n = _normalizeForSearch(line);

    final totalWords = [
      'TOPLAM',
      'T0PLAM',
      'GENEL TOPLAM',
      'TUTAR',
      'TUTARI',
      'ODENECEK',
      'ÖDENECEK',
      'ISLEM TUTARI',
      'İŞLEM TUTARI',
      'İSLEM TUTARI',
    ];

    return totalWords.any((w) => n.contains(_normalizeForSearch(w)));
  }

  static int _merchantSearchLimit(List<String> lines) {
    final dateRegex = RegExp(r'(\d{2})[./-](\d{2})[./-](\d{4}|\d{2})');
    final timeRegex =
        RegExp(r'(?:^|\D)(([01]?\d|2[0-3]):([0-5]\d))(?!\d)');

    for (int i = 0; i < lines.length; i++) {
      final n = _normalizeForSearch(lines[i]);

      final hasDate = dateRegex.hasMatch(lines[i]);
      final hasTime = timeRegex.hasMatch(lines[i]);
      final hasDateKeyword =
          n.contains('TARIH') || n.contains('TRH') || n.contains('SAAT');

      if (hasDate || hasTime || hasDateKeyword) {
        return i == 0 ? 1 : i;
      }
    }

    return lines.length < 15 ? lines.length : 15;
  }

  static double? _parseMoneyFromLine(String line) {
    final moneyRegex = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})*|\d+)[,.](\d{2})(?!\d)',
    );

    final matches = moneyRegex.allMatches(line).toList();
    if (matches.isEmpty) return null;

    final match = matches.last;

    String intPart = match.group(1)!;
    String decimalPart = match.group(2)!;

    intPart = intPart.replaceAll(RegExp(r'[.,]'), '');

    return double.tryParse('$intPart.$decimalPart');
  }
  
  static bool _isReceiptHeaderLine(String line) {
    final n = _normalizeForSearch(line);

    final words = [
      'FIS HARCAMASI',
      'FİŞ HARCAMASI',
      'FIS HARCAMA',
      'FİŞ HARCAMA',
      'HARCAMA',
      'HARCAMASI',
      'SATIS FISI',
      'SATIŞ FİŞİ',
      'FATURA',
      'E-ARSIV',
      'E-ARŞIV',
      'E-ARŞİV',
    ];

    return words.any((w) => n.contains(_normalizeForSearch(w)));
  }

  static String? _extractMerchantName(List<String> lines) {
    final candidates = <_MerchantCandidate>[];

    final limit = _merchantSearchLimit(lines);

    // Öncelikli işletme adı yakalama
    for (int i = 0; i < limit; i++) {
      final line = lines[i];
      final normalized = _normalizeForSearch(line);

      if (_isAddressLine(line)) continue;
      if (_isBankInfoLine(line)) continue;
      if (_isTotalLine(line)) continue;
      if (_isReceiptHeaderLine(line)) continue;
      // if (_isLegalCompanyLine(line)) continue; // Şirket adını atlamaması için kapatıldı

      final strongMerchantWords = [
        'DONER',
        'DÖNER',
        'KEBAP',
        'KOFTE',
        'KÖFTE',
        'PIDE',
        'PİDE',
        'TANTUNI',
        'TANTUNİ',
        'USTA',
        'CAFE',
        'KAFE',
        'RESTORAN',
        'LOKANTA',
        'MARKET',
        'GIDA',
      ];

      final hasStrongMerchantWord = strongMerchantWords.any(
        (word) => normalized.contains(_normalizeForSearch(word)),
      );

      final hasEnoughLetters =
          RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').allMatches(line).length >= 5;

      if (hasStrongMerchantWord && hasEnoughLetters) {
        return _cleanMerchantName(line);
      }
    }

    const knownBrands = [
    // Market zincirleri
    'BIM', 'BİM',
    'A101',
    'SOK', 'ŞOK',
    'MIGROS', 'MİGROS',
    'CARREFOUR', 'CARREFOURSA',
    'HAKMAR',
    'METRO',
    'GROSS',
    'UCAR', 'UÇAR',
    'ONUR MARKET',
    'KIM MARKET', 'KİM MARKET',
    'ŞAYPA', 'SAYPA',

    // Kahve & Cafe
    'STARBUCKS',
    'KAHVE DUNYASI', 'KAHVE DÜNYASI',
    'ESPRESSOLAB',
    'COFFY',
    'COFFEE LAB',
    'GLORIA JEANS',
    'TCHIBO',
    'CARIBOU COFFEE',
    'CAFE NERO',

    // Fast food & restoran
    'MC DONALDS', 'MCDONALDS',
    'BURGER KING',
    'KFC',
    'POPEYES',
    'ARBY S',
    'SUBWAY',
    'DOMINOS', 'DOMINO S',
    'PIZZA HUT',
    'LITTLE CAESARS',

    // Türkiye restoran zincirleri
    'EKREM COŞKUN', 'EKREM COSKUN',
    'KÖFTECİ YUSUF', 'KOFTECI YUSUF',
    'HD İSKENDER',
    'BAYDÖNER', 'BAYDONER',
    'USTA DÖNER', 'USTA DONER',
    'TAVUK DÜNYASI',
    'KASAP DÖNER',
    'SUSHICO',
    'BIG CHEFS',

    // Akaryakıt
    'OPET',
    'SHELL',
    'BP',
    'TOTAL',
    'PETROL OFISI', 'PETROL OFİSİ',
    'AYTEMIZ', 'AYTEMİZ',
    'SUNPET',
    'GO',

    // Teknoloji
    'TEKNOSA',
    'MEDIA MARKT',
    'VATAN',
    'VODAFONE',
    'TURKCELL', 'TÜRKÇELL',
    'TURK TELEKOM', 'TÜRK TELEKOM',

    // Giyim
    'LCW', 'LC WAIKIKI',
    'DEFACTO',
    'KOTON',
    'MAVI', 'MAVİ',
    'ZARA',
    'H M', 'H&M',
    'BERSHKA',
    'PULL BEAR',

    // Eczane & sağlık
    'ECZANE',
    'MEDICANA',
    'ACIBADEM',
    'FARMASI',

    // Diğer yaygın
    'ŞOK MARKET',
    'BİM MARKET',
    'A101 MARKET',
    'MARKET',
    'GIDA',
    'BÜFE', 'BUFE',
    'KAFE', 'CAFE',
    'RESTORAN',
    'LOKANTA',
    'DÖNER', 'DONER',
    'PİDE', 'PIDE',
    'KEBAP',
  ];

    const badWords = [
      'FATURA',
      'E-ARSIV',
      'E-ARŞIV',
      'E-ARŞİV',
      'SATIS FISI',
      'SATIŞ FİŞİ',
      'FIS HARCAMASI',
      'FİŞ HARCAMASI',
      'FIS HARCAMA',
      'FİŞ HARCAMA',
      'HARCAMA',
      'HARCAMASI',
      'TARIH',
      'TARİH',
      'SAAT',
      'VERGI',
      'VERGİ',
      'VD',
      'V.D',
      'TEL',
      'TELEFON',
      'FAX',
      'EMAIL',
      'WEB',
    ];

    const companyWords = [
      'GIDA',
      'MARKET',
      'BÜFE',
      'BUFE',
      'ŞARKÜTERİ',
      'SARKUTERI',
      'CAFE',
      'KAFE',
      'RESTORAN',
      'LOKANTA',
      'DÖNER',
      'DONER',
      'PİDE',
      'PIDE',
      'KEBAP',
      'TANTUNİ',
      'TANTUNI',
      'KÖFTE',
      'KOFTE',
      'FASTFOOD',
      'FAST FOOD',
      'USTA',
      'SALONU',
      'SALON',
      'PETROL',
    ];

    const corporateBadWords = [
      'INS',
      'İNŞ',
      'INSAAT',
      'İNŞAAT',
      'YAPI',
      'SAN',
      'SANAYI',
      'SANAYİ',
      'TIC',
      'TİC',
      'TICARET',
      'TİCARET',
      'LTD',
      'STI',
      'ŞTİ',
      'A.S',
      'A.Ş',
      'HOLDING',
      'HOLDİNG',
    ];

    for (int i = 0; i < limit; i++) {
      final line = lines[i];

      if (_isAddressLine(line)) continue;
      if (_isBankInfoLine(line)) continue;
      if (_isTotalLine(line)) continue;

      final normalized = _normalizeForSearch(line);
      int score = 0;

      score += (15 - i);

      if (i == 0) {
        score += 40;
      }

      for (final brand in knownBrands) {
        if (normalized.contains(_normalizeForSearch(brand))) {
          score += 100;
        }
      }

      for (final word in companyWords) {
        if (normalized.contains(_normalizeForSearch(word))) {
          score += 50;
        }
      }

      if (normalized.endsWith('USTA')) {
        score += 25;
      }

      for (final word in corporateBadWords) {
        if (normalized.contains(_normalizeForSearch(word))) {
          // Eskiden -40 ceza veriliyordu, artık kurumsal şirket isimlerini yakalamak için +20 bonus.
          score += 20;
        }
      }

      if (line.length > 3 && line.length < 40) score += 10;

      if (RegExp(r'^[\d\s.,:*#\-+/]+$').hasMatch(line)) {
        score -= 50;
      }

      for (final word in badWords) {
        if (normalized.contains(_normalizeForSearch(word))) {
          score -= 30;
        }
      }

      if (RegExp(r'\d').allMatches(line).length > 5) {
        score -= 10;
      }

      if (RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').allMatches(line).length > 3) {
        score += 10;
      }

      candidates.add(_MerchantCandidate(line, score));
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final best = candidates.first;

    if (best.score < 0) return null;

    return _cleanMerchantName(best.line);
  }

  static String? _cleanMerchantName(String? name) {
    if (name == null) return null;

    String cleaned = name
        .replaceAll(RegExp(r'[,\-:;\s]+$'), '')
        .replaceAll(RegExp(r'^\s+'), '')
        .trim();

    cleaned = cleaned.replaceAll(
      RegExp(
        r'^(ARTUKLU|MARDIN|MARDİN|KAYACAN)\s+',
        caseSensitive: false,
      ),
      '',
    );

    if (cleaned.length < 2) return null;
    return cleaned;
  }

  static DateTime _extractDateTime(List<String> lines) {
    final dateRegex = RegExp(r'(\d{2})[./-](\d{2})[./-](\d{4}|\d{2})');
    final timeRegex =
        RegExp(r'(?:^|\D)(([01]?\d|2[0-3]):([0-5]\d))(?!\d)');

    DateTime? date;
    int? hour;
    int? minute;

    for (final line in lines) {
      final dateMatch = dateRegex.firstMatch(line);

      if (dateMatch != null && date == null) {
        final day = int.tryParse(dateMatch.group(1)!);
        final month = int.tryParse(dateMatch.group(2)!);
        final year = int.tryParse(dateMatch.group(3)!);

        if (day != null && month != null && year != null) {
          // 31.02 gibi geçersiz veya yılı hatalı okunmuş tarihler atlanır
          date = DateHelper.validDate(year, month, day);
        }
      }

      final normalized = _normalizeForSearch(line);

      final isPossibleTimeLine =
          normalized.contains('SAAT') ||
          normalized.contains('TARIH') ||
          normalized.contains('TRH') ||
          dateRegex.hasMatch(line) ||
          RegExp(r'^\s*\d{1,2}:\d{2}\s*$').hasMatch(line);

      if (isPossibleTimeLine && hour == null && minute == null) {
        final timeMatch = timeRegex.firstMatch(line);

        if (timeMatch != null) {
          hour = int.tryParse(timeMatch.group(2)!);
          minute = int.tryParse(timeMatch.group(3)!);
        }
      }
    }

    final now = DateTime.now();

    date ??= DateTime(now.year, now.month, now.day);
    hour ??= now.hour;
    minute ??= now.minute;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static double? _extractTotalAmount(
    List<String> lines,
    List<TransactionItem> items,
  ) {
    final candidates = <_AmountCandidate>[];

    final priorityKeywords = {
      'ODENECEK TUTAR': 100,
      'ÖDENECEK TUTAR': 100,
      'GENEL TOPLAM': 90,
      'ISLEM TUTARI': 95,
      'İŞLEM TUTARI': 95,
      'İSLEM TUTARI': 95,
      'TOPLAM TUTAR': 85,
      'TOPLAM': 80,
      'VERGILER DAHIL TOPLAM': 70,
      'VERGİLER DAHİL TOPLAM': 70,
      'MAL HIZMET TOPLAM': 50,
      'MAL HİZMET TOPLAM': 50,
      'ODENEN': 45,
      'ÖDENEN': 45,
    };

    const badTotalKeywords = [
      'ARA TOPLAM',
      // 'KDV', // "KDV DAHİL TOPLAM" satırını engellememesi için kaldırıldı
      'TOPKDV',
      'INDIRIM',
      'İNDİRİM',
      'PARA USTU',
      'PARA ÜSTÜ',
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final normalized = _normalizeForSearch(line);

      final isBadLine = badTotalKeywords.any((word) {
        return normalized.contains(_normalizeForSearch(word));
      });

      if (isBadLine) continue;

      int? priority;

      for (final entry in priorityKeywords.entries) {
        if (normalized.contains(_normalizeForSearch(entry.key))) {
          priority = entry.value;
          break;
        }
      }

      if (priority == null) continue;

      final currentLineAmount = _parseMoneyFromLine(line);

      if (currentLineAmount != null && currentLineAmount > 0) {
        candidates.add(_AmountCandidate(currentLineAmount, priority, line));
        continue;
      }

      if (i + 1 < lines.length) {
        final nextLineAmount = _parseMoneyFromLine(lines[i + 1]);

        if (nextLineAmount != null && nextLineAmount > 0) {
          candidates.add(
            _AmountCandidate(nextLineAmount, priority - 5, lines[i + 1]),
          );
        }
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;

        return b.amount.compareTo(a.amount);
      });

      return candidates.first.amount;
    }

    if (items.isNotEmpty) {
      final calculatedTotal = items.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );

      if (calculatedTotal > 0) {
        return double.parse(calculatedTotal.toStringAsFixed(2));
      }
    }

    double? maxAmount;

    for (final line in lines) {
      final amount = _parseMoneyFromLine(line);

      if (amount != null && amount > 0 && amount < 50000) {
        if (maxAmount == null || amount > maxAmount) {
          maxAmount = amount;
        }
      }
    }

    return maxAmount;
  }

  static List<TransactionItem> _extractItems(List<String> lines) {
    final items = <TransactionItem>[];

    const ignoreKeywords = [
      'TOPLAM',
      'T0PLAM',
      'TUTAR',
      'TUTARI',
      'KALAN',
      'KALAN TL',
      'TOP',
      'T0P',
      'GENEL TOPLAM',
      'ODENECEK',
      'ÖDENECEK',
      'ODENEN',
      'ÖDENEN',
      'ISLEM TUTARI',
      'İŞLEM TUTARI',
      'İSLEM TUTARI',
      'İŞLEM',
      'ISLEM',
      'KDV',
      'FIS',
      'FİŞ',
      'FATURA',
      'TARIH',
      'TARİH',
      'SAAT',
      'KASIYER',
      'KASİYER',
      'NAKIT',
      'NAKİT',
      'KREDI',
      'KREDİ',
      'KART',
      'POS',
      'PROVIZ',
      'PROVİZ',
      'PROVIZYON',
      'PROVİZYON',
      'MUSTERI',
      'MÜŞTERİ',
      'ALINAN',
      'PARA',
      'TESEKKUR',
      'TEŞEKKÜR',
      'NO:',
      'VERGI',
      'VERGİ',
      'VD',
      'V.D',
      'TEL',
      'TELEFON',
      'ADRES',
      'BANKA',
      'BANK',
      'IBAN',
      'HESAP NO',
      'HESAPNO',
      'SUBE',
      'ŞUBE',
      'SWIFT',
      'BIC',
      'VISA',
      'MASTERCARD',
      'MAESTRO',
      'TROY',
      'ONAY KODU',
      'REFERANS',
      'REF NO',
      'TERMINAL',
      'TERMINAL NO',
      'ISYERI NO',
      'İŞYERİ NO',
      'TAHSILAT',
      'TAHSİLAT',
      'EKU NO',
      'Z NO',
      'BATCH',
      'SLIP',
    ];

    final dateRegex = RegExp(r'(\d{2})[./-](\d{2})[./-](\d{4}|\d{2})');
    final timeOnlyRegex = RegExp(r'^\s*\d{1,2}:\d{2}\s*$');

    double pendingQuantity = 1.0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final normalized = _normalizeForSearch(line);

      if (dateRegex.hasMatch(line)) continue;
      if (timeOnlyRegex.hasMatch(line)) continue;
      if (_isBankInfoLine(line)) continue;

      final shouldIgnore = ignoreKeywords.any((word) {
        return normalized.contains(_normalizeForSearch(word));
      });

      if (shouldIgnore) continue;

      final amount = _parseMoneyFromLine(line);

      if (amount == null || amount <= 0) {
        final qty = _extractQuantity(line);
        if (qty != null) {
          pendingQuantity = qty;
        }

        continue;
      }

      String name = _extractItemName(line);

      if (_isWeakItemName(name) && i > 0) {
        final prevLine = lines[i - 1];
        final prevNormalized = _normalizeForSearch(prevLine);

        final prevIgnored = ignoreKeywords.any((word) {
          return prevNormalized.contains(_normalizeForSearch(word));
        });

        if (!prevIgnored && _parseMoneyFromLine(prevLine) == null) {
          final prevName = _extractItemName(prevLine);

          if (!_isWeakItemName(prevName)) {
            name = prevName;
          }
        }
      }

      if (_isWeakItemName(name)) {
        final qty = _extractQuantity(line);
        if (qty != null) {
          pendingQuantity = qty;
        }

        continue;
      }

      final inlineQuantity = _extractQuantity(line);
      final quantity = inlineQuantity ?? pendingQuantity;

      items.add(
        TransactionItem(
          name: name,
          amount: amount,
          quantity: quantity,
        ),
      );

      pendingQuantity = 1.0;
    }

    // Fişteki aynı ürünlerin silinmesini engellemek için doğrudan items dönülüyor
    return items;
  }

  static String _extractItemName(String line) {
    String cleaned = line;

    final moneyRegex = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})*|\d+)[,.](\d{2})(?!\d)',
    );

    cleaned = cleaned.replaceAll(moneyRegex, '');
    cleaned = cleaned.replaceAll('₺', '');
    cleaned = cleaned.replaceAll('*', '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    cleaned = cleaned.replaceAll(
      RegExp(r'\s+([zZ%]?\d{1,2}0?)$', caseSensitive: false),
      '',
    );

    final nameMatches = RegExp(
      r'[A-Za-z0-9ÇĞİÖŞÜçğıöşü%/\-&.,]+',
    ).allMatches(cleaned);

    cleaned = nameMatches.map((m) => m.group(0)).join(' ').trim();

    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b\d+(?:[.,]\d+)?\s*(AD|ADET|KG|GR|LT|L|X)\b',
        caseSensitive: false,
      ),
      '',
    );

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  static bool _isWeakItemName(String name) {
    final normalized = _normalizeForSearch(name)
        .replaceAll(RegExp(r'[\d.,*%₺\s]'), '')
        .trim();

    if (normalized.length <= 2) return true;

    const weakWords = [
      'AD',
      'ADX',
      'ADETX',
      'KG',
      'KGX',
      'GR',
      'GRX',
      'LT',
      'LTX',
      'X',
      'BS',
      'TL',
    ];

    return weakWords.contains(normalized);
  }

  static double? _extractQuantity(String line) {
    final quantityRegex = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(AD|ADET|KG|GR|LT|L)\b',
      caseSensitive: false,
    );

    final match = quantityRegex.firstMatch(line);
    if (match == null) return null;

    final value = match.group(1)!.replaceAll(',', '.');
    final parsed = double.tryParse(value);

    if (parsed == null || parsed <= 0) return null;

    return parsed;
  }

}

class _MerchantCandidate {
  final String line;
  final int score;

  _MerchantCandidate(this.line, this.score);
}

class _AmountCandidate {
  final double amount;
  final int priority;
  final String sourceLine;

  _AmountCandidate(this.amount, this.priority, this.sourceLine);
}