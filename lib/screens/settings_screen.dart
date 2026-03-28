import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Ayarlar Ekranı - Uygulama ayarlarını yönetir
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar'), centerTitle: true),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Tema'),
            subtitle: const Text('Uygulama temasını seçin'),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  themeProvider.setTheme(newMode);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Sistem Varsayılanı'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Aydınlık'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Karanlık'),
                ),
              ],
            ),
          ),
          const Divider(),
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
