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
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('Bulut yedeklemesi için önce giriş yapmalısınız.');
      }

      final categories = await _categoryDao.getAll();
      final transactions = await _transactionDao.getAll();

      // Kategorileri yükle (upsert = varsa güncelle, yoksa ekle)
      if (categories.isNotEmpty) {
        final categoryMaps = categories.map((c) {
          final map = c.toMap();
          map['user_id'] = currentUser.id; // Giriş yapan kullanıcının ID'si ekleniyor
          return map;
        }).toList();

        await client.from('categories').upsert(
          categoryMaps,
          onConflict: 'id,user_id',
        );
        debugPrint('✅ ${categories.length} kategori buluta yedeklendi.');
      }

      // ID'si null olmayan işlemleri filtrele (Supabase PRIMARY KEY null kabul etmez)
      final validTransactions = transactions.where((t) => t.id != null).toList();
      if (validTransactions.isNotEmpty) {
        final transactionMaps = validTransactions.map((t) {
          final map = t.toMap();
          map['user_id'] = currentUser.id; // Giriş yapan kullanıcının ID'si ekleniyor
          return map;
        }).toList();

        await client.from('transactions').upsert(
          transactionMaps,
          onConflict: 'id,user_id',
        );
        debugPrint('✅ ${validTransactions.length} işlem buluta yedeklendi.');
        
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
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('Yedekleri geri yüklemek için önce giriş yapmalısınız.');
      }

      final db = await DatabaseService().database;

      // ── Sadece aktif kullanıcıya ait kategorileri çek ve SQLite'ye yaz ──
      final categoryData = await client
          .from('categories')
          .select()
          .eq('user_id', currentUser.id);

      for (final row in categoryData) {
        // Yerel veritabanında 'user_id' kolonu olmadığı için onu çıkarıyoruz
        final localRow = Map<String, dynamic>.from(row);
        localRow.remove('user_id');

        await db.insert(
          'categories',
          localRow,
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      debugPrint('✅ ${categoryData.length} kategori geri yüklendi.');

      // ── Sadece aktif kullanıcıya ait işlemleri çek ve SQLite'ye yaz ──
      final transactionData = await client
          .from('transactions')
          .select()
          .eq('user_id', currentUser.id);

      for (final row in transactionData) {
        // Yerel veritabanında 'user_id' kolonu olmadığı için onu çıkarıyoruz
        final localRow = Map<String, dynamic>.from(row);
        localRow.remove('user_id');

        await db.insert(
          'transactions',
          localRow,
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
