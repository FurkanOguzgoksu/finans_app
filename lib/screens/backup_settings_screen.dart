import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/providers/backup_provider.dart';

class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yedekleme Ayarları')),
      body: Consumer<BackupProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Yedekleme Yöntemi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Yöntem Seçimi
                RadioListTile<BackupType>(
                  title: const Text('Cihaza Kaydet (JSON)'),
                  subtitle: const Text('Verileri telefon hafızasına kaydeder.'),
                  value: BackupType.json,
                  groupValue: provider.selectedBackupType,
                  onChanged: (value) {
                    if (value != null) provider.setBackupType(value);
                  },
                ),
                RadioListTile<BackupType>(
                  title: const Text('Buluta Kaydet (Firebase)'),
                  subtitle: const Text('Verileri bulut hesabınıza eşitler.'),
                  value: BackupType.firebase,
                  groupValue: provider.selectedBackupType,
                  onChanged: (value) {
                    if (value != null) provider.setBackupType(value);
                  },
                ),

                const SizedBox(height: 32),

                // Mesaj Alanı
                if (provider.lastMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: provider.lastMessage!.contains('başarı')
                          ? Colors.green.withAlpha(50)
                          : Colors.red.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.lastMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: provider.lastMessage!.contains('başarı')
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Aksiyon Butonları
                if (provider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Şimdi Yedekle'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        // ui preview için geçici false kontrolü bypass edildi
                        onPressed: () => provider.performBackup(),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Yedekten Yükle'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => provider.performRestore(),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
