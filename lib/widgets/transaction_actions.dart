import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/models/transaction.dart' as models;
import 'package:finans_app/providers/transaction_provider.dart';
import 'package:finans_app/widgets/add_transaction_sheet.dart';

/// İşlem düzenleme ve silme akışları (ana sayfa ve işlemler ekranında ortak)
class TransactionActions {
  /// İşlemi düzenleme formunu açar
  static void showEditSheet(BuildContext context, models.Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddTransactionSheet(transaction: tx),
    );
  }

  /// Onay alıp işlemi siler; silme başarısız olursa kullanıcıyı bilgilendirir
  static void confirmDelete(BuildContext context, models.Transaction tx) {
    final id = tx.id;
    if (id == null) return;

    final provider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: const Text('Bu işlemi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await provider.deleteTransaction(id);
              } catch (e) {
                debugPrint('İşlem silinemedi: $e');
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('İşlem silinemedi. İnternet bağlantınızı kontrol edin.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
