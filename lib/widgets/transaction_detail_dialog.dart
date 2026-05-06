import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:finans_app/models/transaction.dart' as models;
import 'package:finans_app/models/category.dart' as category_models;
import 'package:finans_app/providers/transaction_provider.dart';
import 'package:finans_app/widgets/add_transaction_sheet.dart';
import 'package:finans_app/providers/category_provider.dart';
import 'package:finans_app/utils/currency_formatter.dart';

class TransactionDetailDialog extends StatelessWidget {
  final models.Transaction transaction;

  const TransactionDetailDialog({super.key, required this.transaction});

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: const Text(
          'Bu işlemi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Onay penceresini kapat
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (transaction.id != null) {
                Provider.of<TransactionProvider>(
                  context,
                  listen: false,
                ).deleteTransaction(transaction.id!);

                // Önce onay penceresini, sonra detay penceresini kapat
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('İşlem silindi.')));
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
        color: '#808080',
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
            // İkon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isIncome
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
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
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Tutar
            Text(
              '${isIncome ? '+' : '-'}₺ ${CurrencyFormatter.format(transaction.amount)}',
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
            _buildDetailRow(
              'Tarih ve Saat',
              dateFormat.format(transaction.date),
              theme,
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Kategori', category.name, theme),
            const SizedBox(height: 12),
            _buildSourceBadge(theme),

            if (transaction.items != null && transaction.items!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fiş Detayları',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transaction.items!.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = transaction.items![index];
                    
                    String displayName = item.name;
                    if (item.quantity != 1.0 && item.quantity != 0.0) {
                      final String qtyStr = item.quantity.toString().replaceAll(RegExp(r'\.0$'), '');
                      final double unitPrice = item.amount / item.quantity;
                      final String unitStr = CurrencyFormatter.format(unitPrice);
                      displayName = '${item.name} ($qtyStr x ₺$unitStr)';
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '₺ ${CurrencyFormatter.format(item.amount)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
            ],

            // PDF / Fiş Görüntüleyici (Açıklamanın üstünde)
            if (transaction.receiptId != null) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final isPdf = transaction.receiptId!.toLowerCase().endsWith('.pdf');
                  return InkWell(
                    onTap: () {
                      if (isPdf) {
                        OpenFilex.open(transaction.receiptId!);
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            insetPadding: const EdgeInsets.all(16),
                            clipBehavior: Clip.hardEdge,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  child: Image.file(
                                    File(transaction.receiptId!),
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  right: 8, top: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isPdf
                            ? Colors.purple.withValues(alpha: 0.1)
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPdf
                              ? Colors.purple.withValues(alpha: 0.2)
                              : theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                            color: isPdf ? Colors.purple : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isPdf ? 'PDF Faturayı Aç' : 'Taranmış Fiş Fotoğrafını Gör',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isPdf ? Colors.purple : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: isPdf
                                ? Colors.purple.withValues(alpha: 0.5)
                                : theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            // Açıklama / Notlar (Açılır-Kapanır)
            if (transaction.description != null &&
                transaction.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  leading: Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    'Açıklama / Notlar',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.description!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],


            const SizedBox(height: 32),

            // Aksiyon Butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // detay dialog'ı kapat
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => AddTransactionSheet(transaction: transaction),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Düzenle'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    ],
  ),
);
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSourceBadge(ThemeData theme) {
    String sourceLabel;
    IconData sourceIcon;
    Color sourceColor;

    final desc = transaction.description ?? '';

    if (desc.contains('PDF fatura')) {
      sourceLabel = 'PDF Fatura';
      sourceIcon = Icons.picture_as_pdf;
      sourceColor = Colors.purple;
    } else if (desc.contains('Fiş tarama (OCR)')) {
      sourceLabel = 'Kamera (OCR)';
      sourceIcon = Icons.document_scanner;
      sourceColor = Colors.orange;
    } else if (desc.contains('otomatik eklenir') || desc.contains('Aylık gelir')) {
      sourceLabel = 'Otomatik Gelir';
      sourceIcon = Icons.repeat;
      sourceColor = Colors.teal;
    } else {
      sourceLabel = 'Manuel Giriş';
      sourceIcon = Icons.edit_note;
      sourceColor = theme.colorScheme.primary;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Eklenme Türü',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 16,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sourceColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sourceColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sourceIcon, size: 14, color: sourceColor),
              const SizedBox(width: 6),
              Text(
                sourceLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sourceColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
