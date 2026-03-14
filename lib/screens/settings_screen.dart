import 'package:flutter/material.dart';

/// Ayarlar Ekranı - Uygulama ayarlarını yönetir
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Ayarlar\n(İleride uygulama ayarları burada gösterilecek)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
