import 'package:flutter/material.dart';
import 'package:finans_app/services/backup/backup_service.dart';
import 'package:finans_app/services/backup/json_backup_service.dart';
import 'package:finans_app/services/backup/supabase_backup_service.dart';

enum BackupType { json, supabase }

class BackupProvider with ChangeNotifier {
  BackupType _selectedBackupType = BackupType.json;
  bool _isLoading = false;
  String? _lastMessage;
  bool _lastSucceeded = false;

  BackupType get selectedBackupType => _selectedBackupType;
  bool get isLoading => _isLoading;
  String? get lastMessage => _lastMessage;

  /// Son işlem başarılı mı? (Mesajın rengini belirler)
  bool get lastSucceeded => _lastSucceeded;

  void setBackupType(BackupType type) {
    _selectedBackupType = type;
    notifyListeners();
  }

  BackupService _getService() {
    switch (_selectedBackupType) {
      case BackupType.json:
        return JsonBackupService();
      case BackupType.supabase:
        return SupabaseBackupService();
    }
  }

  Future<void> performBackup() async {
    await _run(
      (service) => service.exportData(),
      successMessage: _selectedBackupType == BackupType.supabase
          ? '☁️ Supabase yedeklemesi başarıyla tamamlandı!'
          : '📁 Yedek dosyası başarıyla oluşturuldu!',
      errorMessage: 'Yedekleme sırasında bir hata oluştu.',
    );
  }

  /// Geri yükleme başarılı olduysa true döner (ekran verileri yeniden yükler)
  Future<bool> performRestore() async {
    return _run(
      (service) => service.importData(),
      successMessage: _selectedBackupType == BackupType.supabase
          ? '☁️ Supabase\'den geri yükleme başarıyla tamamlandı!'
          : '📁 Yedek dosyası başarıyla geri yüklendi!',
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
