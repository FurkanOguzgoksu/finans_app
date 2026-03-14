import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import 'backup_service.dart';
import '../transaction_dao.dart';
import '../category_dao.dart';
import '../receipt_dao.dart';

/// JSON tabanlı yerel yedekleme servisi
class JsonBackupService implements BackupService {
  final TransactionDao _transactionDao = TransactionDao();
  final CategoryDao _categoryDao = CategoryDao();
  final ReceiptDao _receiptDao = ReceiptDao();

  @override
  Future<bool> exportData() async {
    try {
      final categories = await _categoryDao.getAll();
      final transactions = await _transactionDao.getAll();
      final receipts = await _receiptDao.getAll();

      // Tüm veriyi tek bir Map içinde topla
      final Map<String, dynamic> backupData = {
        'version': 1,
        'export_date': DateTime.now().toIso8601String(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'receipts': receipts.map((r) => r.toMap()).toList(),
      };

      final jsonString = jsonEncode(backupData);

      // Cihazın dokümanlar klasörüne kaydet
      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/finans_backup_$dateStr.json');

      await file.writeAsString(jsonString);
      print('Yedekleme başarılı: ${file.path}');
      return true;
    } catch (e) {
      print('JSON Dışa Aktarırken Hata: $e');
      return false;
    }
  }

  @override
  Future<bool> importData() async {
    // Gerçek implementasyonda file picker ile seçilen dosya okunur
    // Şimdilik sadece metodun iskeleti oluşturuldu
    try {
      // Örnek: final file = /* seçilen dosya */
      // final jsonString = await file.readAsString();
      // final backupData = jsonDecode(jsonString);
      // DB'yi temizle ve döngü ile insert yap...
      
      print('JSON İçe Aktarma çağrıldı');
      return true;
    } catch (e) {
      print('JSON İçe Aktarırken Hata: $e');
      return false;
    }
  }
}
