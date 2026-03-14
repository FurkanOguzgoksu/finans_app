import '../models/transaction.dart';

/// Transaction Repository - İşlem CRUD operasyonları için abstract sınıf
abstract class TransactionRepository {
  /// Tüm işlemleri getirir
  Future<List<Transaction>> getAll();

  /// ID'ye göre tek bir işlem getirir
  Future<Transaction?> getById(int id);

  /// Türe göre işlemleri getirir ('gelir' veya 'gider')
  Future<List<Transaction>> getByType(String type);

  /// Kategoriye göre işlemleri getirir
  Future<List<Transaction>> getByCategoryId(int categoryId);

  /// Tarih aralığına göre işlemleri getirir
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end);

  /// Yeni işlem ekler, eklenen kaydın ID'sini döndürür
  Future<int> insert(Transaction transaction);

  /// Mevcut işlemi günceller
  Future<int> update(Transaction transaction);

  /// İşlemi siler
  Future<int> delete(int id);

  /// Toplam gelir miktarını hesaplar
  Future<double> getTotalIncome({DateTime? start, DateTime? end});

  /// Toplam gider miktarını hesaplar
  Future<double> getTotalExpense({DateTime? start, DateTime? end});
}
