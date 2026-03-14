/// Yedekleme Stratejisi Arayüzü (Strategy Pattern)
/// Çeşitli yedekleme yöntemleri (JSON, Firebase vb.) bu arayüzü uygular.
abstract class BackupService {
  /// Tüm uygulama verilerini (Categories, Transactions, Receipts) dışa aktarır
  Future<bool> exportData();

  /// Dışa aktarılan verileri geri yükler
  Future<bool> importData();
}
