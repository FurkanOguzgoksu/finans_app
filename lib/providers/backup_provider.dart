import 'package:flutter/material.dart';
import 'package:finans_app/services/backup/backup_service.dart';
import 'package:finans_app/services/backup/json_backup_service.dart';

/// Yedekleme durumunu yönetir.
///
/// Veriler zaten Supabase hesabında tutulduğu için ayrıca bulut yedeğine gerek
/// yoktur; yedekleme, hesaptan bağımsız saklanabilen bir JSON dosyasıyla yapılır.
class BackupProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _lastMessage;
  bool _lastSucceeded = false;

  bool get isLoading => _isLoading;
  String? get lastMessage => _lastMessage;

  /// Son işlem başarılı mı? (Mesajın rengini belirler)
  bool get lastSucceeded => _lastSucceeded;

  BackupService _getService() => JsonBackupService();

  Future<void> performBackup() async {
    await _run(
      (service) => service.exportData(),
      successMessage: '📁 Yedek dosyası başarıyla oluşturuldu!',
      errorMessage: 'Yedekleme sırasında bir hata oluştu.',
    );
  }

  /// Geri yükleme başarılı olduysa true döner (ekran verileri yeniden yükler)
  Future<bool> performRestore() async {
    return _run(
      (service) => service.importData(),
      successMessage: '📁 Yedek dosyası başarıyla geri yüklendi!',
      errorMessage: 'Geri yükleme sırasında bir hata oluştu.',
    );
  }

  Future<bool> _run(
    Future<bool?> Function(BackupService service) operation, {
    required String successMessage,
    required String errorMessage,
  }) async {
    _isLoading = true;
    _lastMessage = null;
    notifyListeners();

    bool succeeded = false;
    try {
      final result = await operation(_getService());
      succeeded = result == true;
      // null: kullanıcı iptal etti, mesaj gösterilmez
      if (result != null) {
        _lastMessage = succeeded ? successMessage : errorMessage;
      }
    } catch (e) {
      _lastMessage = 'Hata: $e';
    } finally {
      _lastSucceeded = succeeded;
      _isLoading = false;
      notifyListeners();
    }
    return succeeded;
  }
}
