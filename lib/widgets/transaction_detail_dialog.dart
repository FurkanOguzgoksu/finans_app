import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/models/transaction.dart' as models;
import 'package:finans_app/models/category.dart' as category_models;
import 'package:finans_app/providers/transaction_provider.dart';

import 'package:finans_app/providers/category_provider.dart';

class TransactionDetailDialog extends StatelessWidget {
  final models.Transaction transaction;

  const TransactionDetailDialog({super.key, required this.transaction});

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: const Text('Bu işlemi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Onay penceresini kapat
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (transaction.id != null) {
                Provider.of<TransactionProvider>(context, listen: false)
                    .deleteTransaction(transaction.id!);
                
                // Önce onay penceresini, sonra detay penceresini kapat
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İşlem silindi.')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == 'gelir';
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR');
    
    // Kategoriyi bul
    final catProvider = Provider.of<CategoryProvider>(context, listen: false);
    final category = catProvider.categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => category_models.Category(
        id: -1, 
        name: 'Bilinmeyen', 

        type: transaction.type, 
        color: '#808080'

      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ekranın ortasında, sadece gerektiği kadar yer kaplar
          children: [
            // İkon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            
            // Başlık
            Text(
              transaction.title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Tutar
            Text(
              '${isIncome ? '+' : '-'}₺ ${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Detay Bilgileri
            _buildDetailRow('Kategori', category.name, theme),
            const SizedBox(height: 12),
            _buildDetailRow('Tarih', dateFormat.format(transaction.date), theme),
            // Buraya ileride OCR'dan gelen PDF linki veya not eklenebilir.
            
            const SizedBox(height: 32),
            
            // Aksiyon Butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kapat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(context),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Sil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ],
    );
  }
}
