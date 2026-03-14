import 'package:flutter/material.dart';

/// Fiş Tarama Ekranı - OCR ile fiş/fatura tarama
class ReceiptScanScreen extends StatelessWidget {
  const ReceiptScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiş Tara'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Fiş Tarama\n(İleride kamera ile fiş tarama burada yapılacak)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
