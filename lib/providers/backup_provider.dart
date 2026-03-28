import 'package:flutter/material.dart';
import 'package:finans_app/services/backup/backup_service.dart';
import 'package:finans_app/services/backup/json_backup_service.dart';
import 'package:finans_app/services/backup/supabase_backup_service.dart';

enum BackupType { json, supabase }

class BackupProvider with ChangeNotifier {
  BackupType _selectedBackupType = BackupType.json;
  bool _isLoading = false;
  String? _lastMessage;

  BackupType get selectedBackupType => _selectedBackupType;
  bool get isLoading => _isLoading;
  String? get lastMessage => _lastMessage;

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
    _isLoading = true;
    _lastMessage = null;
    notifyListeners();

    try {
      final service = _getService();
      final success = await service.exportData();

      if (success) {
        _lastMessage = _selectedBackupType == BackupType.supabase
            ? '☁️ Supabase yedeklemesi başarıyla tamamlandı!'
            : '📁 JSON yedeklemesi başarıyla tamamlandı!';
      } else {
        _lastMessage = 'Yedekleme sırasında bir hata oluştu.';
      }
    } catch (e) {
      _lastMessage = 'Hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> performRestore() async {
    _isLoading = true;
    _lastMessage = null;
    notifyListeners();

    try {
      final service = _getService();
      final success = await service.importData();

      if (success) {
        _lastMessage = _selectedBackupType == BackupType.supabase
            ? '☁️ Supabase\'den geri yükleme tamamlandı!'
            : '📁 JSON\'dan geri yükleme tamamlandı!';
      } else {
        _lastMessage = 'Geri yükleme sırasında bir hata oluştu.';
      }
    } catch (e) {
      _lastMessage = 'Hata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
