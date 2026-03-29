import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finans_app/widgets/add_transaction_sheet.dart';

class TransactionOptionsSheet extends StatelessWidget {
  const TransactionOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'İşlem Yöntemi Seçin',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // 1. Manuel Giriş
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit_note, color: theme.colorScheme.primary),
            ),
            title: const Text(
              'Manuel Giriş',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Gelir veya gideri elle ekleyin'),
            onTap: () {
              Navigator.pop(context); // Bu menüyü kapat
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const AddTransactionSheet(),
              );
            },
          ),
          const Divider(),

          // 2. Kamera ile Tarama
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.document_scanner, color: Colors.orange),
            ),
            title: const Text(
              'Kamera ile Fiş Tara',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('OCR ile fatura bilgilerini otomatik alın'),
            onTap: () {
              Navigator.pop(context);
              context.push('/scan'); // Yönlendirme go_router ile yapılır
            },
          ),
          const Divider(),

          // 3. PDF Yükeleme (İleride eklenecek)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.purple),
            ),
            title: const Text(
              'PDF Yükle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Dijital faturanızı sisteme aktarın'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF Yükleme özelliği yakında eklenecektir.'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
