import '../models/receipt.dart';

/// Receipt Repository - Fiş/Fatura CRUD operasyonları için abstract sınıf
abstract class ReceiptRepository {
  /// Tüm fişleri getirir
  Future<List<Receipt>> getAll();

  /// ID'ye göre tek bir fiş getirir
  Future<Receipt?> getById(int id);

  /// Tarih aralığına göre fişleri getirir
  Future<List<Receipt>> getByDateRange(DateTime start, DateTime end);

  /// Yeni fiş ekler, eklenen kaydın ID'sini döndürür
  Future<int> insert(Receipt receipt);

  /// Mevcut fişi günceller (OCR sonuçları eklendiğinde)
  Future<int> update(Receipt receipt);

  /// Fişi siler
  Future<int> delete(int id);
}
