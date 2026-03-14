import 'package:flutter/material.dart';

/// Ana Sayfa Ekranı - Özet bilgileri gösterir
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finans Takip'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Ana Sayfa\n(İleride gelir/gider özeti burada gösterilecek)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
