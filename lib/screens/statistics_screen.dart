import 'package:flutter/material.dart';

/// İstatistik Ekranı - Grafik ve analizleri gösterir
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'İstatistikler\n(İleride grafikler ve analizler burada gösterilecek)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
