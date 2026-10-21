import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_service.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../utils/text_helper.dart';
import '../transaction_dao.dart';
import '../category_dao.dart';

/// JSON tabanlı yedekleme servisi
///
/// Dışa aktarma: veriler JSON dosyasına yazılır ve paylaşım menüsü açılır;
/// kullanıcı dosyayı Drive'a, e-postaya veya cihaz klasörüne kaydedebilir.
/// İçe aktarma: seçilen yedek dosyası hesaba eklenir. Aynı ad ve türdeki
/// kategoriler ile birebir aynı işlemler tekrar eklenmez; böylece aynı yedek
/// iki kez yüklense de kopya kayıt oluşmaz.
class JsonBackupService implements BackupService {
  static const int formatVersion = 2;

  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;

  /// Depolar testlerde sahte veri kaynağı vermek içindir.
  JsonBackupService({
    CategoryRepository? categoryRepository,
    TransactionRepository? transactionRepository,
  })  : _categoryRepository = categoryRepository ?? CategoryDao(),
        _transactionRepository = transactionRepository ?? TransactionDao();

  @override
  Future<bool?> exportData() async {
    try {
      final jsonString = await buildBackupJson();

      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/finans_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Finans Takip yedeği'),
      );
      if (result.status == ShareResultStatus.dismissed) return null;

      debugPrint('Yedekleme başarılı: ${file.path}');
      return true;
    } catch (e) {
      debugPrint('JSON Dışa Aktarırken Hata: $e');
      return false;
    }
  }

  /// Tüm kategori ve işlemleri yedek formatında JSON metnine çevirir
  Future<String> buildBackupJson() async {
    final categories = await _categoryRepository.getAll();
    final transactions = await _transactionRepository.getAll();

    return jsonEncode({
      'version': formatVersion,
      'export_date': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
    });
  }

  @override
  Future<bool?> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = result?.files.single.path;
      if (path == null) return null; // Kullanıcı dosya seçmedi

      final jsonString = await File(path).readAsString();
      final restored = await restoreFromJson(jsonString);
      debugPrint(
        'JSON geri yüklendi: ${restored.categories} kategori, '
        '${restored.transactions} işlem eklendi',
      );
      return true;
    } catch (e) {
      debugPrint('JSON İçe Aktarırken Hata: $e');
      return false;
    }
  }

  /// Yedek içeriğini hesaba ekler; eklenen kategori ve işlem sayısını döndürür.
  Future<({int categories, int transactions})> restoreFromJson(String jsonString) async {
    final data = jsonDecode(jsonString);
    if (data is! Map<String, dynamic> ||
        data['categories'] is! List ||
        data['transactions'] is! List) {
      throw const FormatException('Geçersiz yedek dosyası');
    }

    // 1. Kategoriler: aynı ad ve türde kategori varsa o kullanılır, yoksa eklenir.
    // Yedekteki ID'ler hesaptakilerle aynı olmadığı için eşleme tablosu tutulur.
    final idsByKey = <String, int>{
      for (final c in await _categoryRepository.getAll())
        if (c.id != null) _categoryKey(c): c.id!,
    };
    final categoryIdMap = <int, int>{}; // yedekteki ID → hesaptaki ID
    var addedCategories = 0;

    for (final map in (data['categories'] as List).cast<Map<String, dynamic>>()) {
      final category = Category.fromMap(map);
      final key = _categoryKey(category);
      var accountId = idsByKey[key];
      if (accountId == null) {
        accountId = await _categoryRepository.insert(
          Category(
            name: category.name,
            type: category.type,
            icon: category.icon,
            color: category.color,
          ),
        );
        idsByKey[key] = accountId;
        addedCategories++;
      }
      if (category.id != null) categoryIdMap[category.id!] = accountId;
    }

    // 2. İşlemler: kategori ID'leri hesaptaki karşılıklarına çevrilir
    final existingKeys = (await _transactionRepository.getAll())
        .map(_transactionKey)
        .toSet();
    var addedTransactions = 0;

    for (final map in (data['transactions'] as List).cast<Map<String, dynamic>>()) {
      final tx = Transaction.fromMap(map);
      final categoryId = categoryIdMap[tx.categoryId];
      if (categoryId == null) continue; // Kategorisi yedekte olmayan işlem

      final restored = Transaction(
        title: tx.title,
        amount: tx.amount,
        type: tx.type,
        categoryId: categoryId,
        date: tx.date,
        description: tx.description,
        receiptId: tx.receiptId,
        items: tx.items,
        createdAt: tx.createdAt,
      );
      if (!existingKeys.add(_transactionKey(restored))) continue; // Zaten var

      await _transactionRepository.insert(restored);
      addedTransactions++;
    }

    return (categories: addedCategories, transactions: addedTransactions);
  }

  static String _categoryKey(Category c) =>
      '${c.type}|${TextHelper.trLower(c.name.trim())}';

  static String _transactionKey(Transaction t) =>
      '${t.type}|${t.categoryId}|${t.amount}|${t.date.millisecondsSinceEpoch}|${t.title}';
}
