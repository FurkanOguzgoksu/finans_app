import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/providers/backup_provider.dart';
import 'package:finans_app/providers/category_provider.dart';
import 'package:finans_app/providers/transaction_provider.dart';

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
                // Bilgilendirme: veriler zaten bulutta, dosya yedeği isteğe bağlı
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cloud_done_outlined),
                  title: Text('Verileriniz bulutta'),
                  subtitle: Text(
                    'Kategori ve işlemleriniz hesabınızda saklanır; '
                    'giriş yaptığınız her cihazda otomatik olarak görünür.',
                  ),
                ),
                const SizedBox(height: 8),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.description_outlined),
                  title: Text('Yedek Dosyası (JSON)'),
                  subtitle: Text(
                    "Hesaptan bağımsız bir kopya oluşturur; dosyayı Drive'a, "
                    'e-postaya veya cihaza kaydedebilir, istediğiniz zaman geri yükleyebilirsiniz.',
                  ),
                ),

                const SizedBox(height: 32),

                // Mesaj Alanı
                if (provider.lastMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: provider.lastSucceeded
                          ? Colors.green.withValues(alpha: 50/255)
                          : Colors.red.withValues(alpha: 50/255),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.lastMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: provider.lastSucceeded
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
                        icon: const Icon(Icons.file_upload_outlined),
                        label: const Text('Yedek Dosyası Oluştur'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => provider.performBackup(),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Yedek Dosyasından Yükle'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          final restored = await provider.performRestore();
                          // Geri yükleme sonrası UI'ı güncellemek için verileri yeniden çek
                          if (restored && context.mounted) {
                            Provider.of<CategoryProvider>(context, listen: false).loadCategories();
                            Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
                          }
                        },
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
