import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Ayarlar Ekranı - Uygulama ayarlarını yönetir
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar'), centerTitle: true),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Yedekleme Ayarları'),
            subtitle: const Text('JSON veya Supabase ile yedek alın'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/backup_settings');
            },
          ),
          const Divider(),
          // Diğer ayarlar eklenebilir
        ],
      ),
    );
  }
}
