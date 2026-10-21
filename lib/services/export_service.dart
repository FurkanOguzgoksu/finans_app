import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as models;
import '../models/category.dart' as models;

class ExportService {
  /// Harcamaları CSV olarak dışa aktarır ve paylaşım ekranını açar.
  Future<void> exportTransactionsToCSV({
    required List<models.Transaction> transactions,
    required List<models.Category> categories,
  }) async {
    if (transactions.isEmpty) {
      throw Exception('Dışa aktarılacak işlem bulunamadı.');
    }

    try {
      // Başlıklar
      List<List<dynamic>> rows = [
        ['Tarih', 'İşlem Başlığı', 'Tutar (TL)', 'Tür', 'Kategori', 'Açıklama']
      ];

      // Kategori adlarını hızlı bulmak için map
      final categoryMap = {for (var c in categories) c.id: c.name};

      final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

      // Verileri doldur
      for (var tx in transactions) {
        rows.add([
          dateFormat.format(tx.date),
          tx.title,
          tx.amount.toStringAsFixed(2),
          tx.type == 'gelir' ? 'Gelir' : 'Gider',
          categoryMap[tx.categoryId] ?? 'Bilinmeyen',
          tx.description ?? '',
        ]);
      }

      // CSV string oluştur (ListToCsvConverter kullanımı)
      String csv = const CsvEncoder(fieldDelimiter: ';').convert(rows);
      
      // UTF-8 BOM ekle (Excel'de Türkçe karakterlerin düzgün görünmesi için)
      final String bom = '\uFEFF';
      csv = bom + csv;

      // Geçici dosyaya kaydet
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/finans_dokumu_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File(path);
      
      await file.writeAsString(csv);

      // Paylaşım menüsünü aç
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Finansal Rapor (CSV Formatında)',
        ),
      );
    } catch (e) {
      throw Exception('Dışa aktarım sırasında bir hata oluştu: $e');
    }
  }
}
