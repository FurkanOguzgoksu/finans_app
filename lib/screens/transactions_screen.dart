import 'package:flutter/material.dart';

/// İşlemler Ekranı - Gelir/gider listesini gösterir
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlemler'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'İşlemler Listesi\n(İleride gelir/gider kayıtları burada listelenecek)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
