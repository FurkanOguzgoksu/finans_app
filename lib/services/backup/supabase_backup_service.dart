import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:finans_app/services/supabase_service.dart';
import 'package:finans_app/services/database_service.dart';
import 'package:finans_app/services/transaction_dao.dart';
import 'package:finans_app/services/category_dao.dart';
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

      // ID'si null olmayan işlemleri filtrele (Supabase PRIMARY KEY null kabul etmez)
      final validTransactions = transactions.where((t) => t.id != null).toList();
      if (validTransactions.isNotEmpty) {
        await client.from('transactions').upsert(
          validTransactions.map((t) => t.toMap()).toList(),
          onConflict: 'id',
        );
        debugPrint('✅ ${validTransactions.length} işlem yedeklendi.');
        
        final skipped = transactions.length - validTransactions.length;
        if (skipped > 0) {
          debugPrint('⚠️ $skipped işlem ID eksik olduğundan atlandı.');
        }
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
      final db = await DatabaseService().database;

      // ── Kategorileri çek ve SQLite'ye yaz ──
      final categoryData = await client.from('categories').select();
      for (final row in categoryData) {
        // INSERT OR REPLACE: aynı ID varsa günceller, yoksa ekler
        await db.insert(
          'categories',
          row,
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      debugPrint('✅ ${categoryData.length} kategori geri yüklendi.');

      // ── İşlemleri çek ve SQLite'ye yaz ──
      final transactionData = await client.from('transactions').select();
      for (final row in transactionData) {
        await db.insert(
          'transactions',
          row,
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      debugPrint('✅ ${transactionData.length} işlem geri yüklendi.');

      return true;
    } catch (e) {
      debugPrint('❌ Supabase Geri Yükleme Hatası: $e');
      return false;
    }
  }
}
