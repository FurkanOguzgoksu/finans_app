/// Yedekleme Stratejisi Arayüzü (Strategy Pattern)
/// Çeşitli yedekleme yöntemleri (JSON, Supabase vb.) bu arayüzü uygular.
///
/// Metotlar başarıda true, hatada false döner; kullanıcı işlemi iptal ettiyse
/// (ör. dosya seçmedi) null döner.
abstract class BackupService {
  /// Tüm uygulama verilerini (Categories, Transactions) dışa aktarır
  Future<bool?> exportData();

  /// Dışa aktarılan verileri geri yükler
  Future<bool?> importData();
}
