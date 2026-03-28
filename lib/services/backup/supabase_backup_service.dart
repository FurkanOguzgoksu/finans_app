import 'package:flutter/material.dart';
import 'package:finans_app/services/supabase_service.dart';
import 'package:finans_app/services/transaction_dao.dart';
import 'package:finans_app/services/category_dao.dart';
import 'package:finans_app/models/category.dart';
import 'package:finans_app/models/transaction.dart' as models;
import 'backup_service.dart';

/// Supabase (PostgreSQL) tabanlı bulut yedekleme servisi
class SupabaseBackupService implements BackupService {
  final TransactionDao _transactionDao = TransactionDao();
  final CategoryDao _categoryDao = CategoryDao();

  /// Tüm verileri Supabase'e yedekler
  @override
  Future<bool> exportData() async {
    try {
      final client = SupabaseService.client;

      final categories = await _categoryDao.getAll();
      final transactions = await _transactionDao.getAll();

      // Kategorileri yükle (upsert = varsa güncelle, yoksa ekle)
      if (categories.isNotEmpty) {
        await client.from('categories').upsert(
          categories.map((c) => c.toMap()).toList(),
          onConflict: 'id',
        );
        debugPrint('✅ ${categories.length} kategori yedeklendi.');
      }

      // İşlemleri yükle
      if (transactions.isNotEmpty) {
        await client.from('transactions').upsert(
          transactions.map((t) => t.toMap()).toList(),
          onConflict: 'id',
        );
        debugPrint('✅ ${transactions.length} işlem yedeklendi.');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Supabase Yedekleme Hatası: $e');
      return false;
    }
  }

  /// Supabase'den verileri çekip SQLite'ye yazar (Geri Yükleme)
  @override
  Future<bool> importData() async {
    try {
      final client = SupabaseService.client;

      // Kategorileri çek
      final categoryData = await client.from('categories').select();
      for (final row in categoryData) {
        final cat = Category.fromMap(row);
        await _categoryDao.insert(cat);
      }
      debugPrint('✅ ${categoryData.length} kategori geri yüklendi.');

      // İşlemleri çek
      final transactionData = await client.from('transactions').select();
      for (final row in transactionData) {
        final tx = models.Transaction.fromMap(row);
        await _transactionDao.insert(tx);
      }
      debugPrint('✅ ${transactionData.length} işlem geri yüklendi.');

      return true;
    } catch (e) {
      debugPrint('❌ Supabase Geri Yükleme Hatası: $e');
      return false;
    }
  }
}
