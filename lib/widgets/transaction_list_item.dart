import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finans_app/models/transaction.dart';
import 'package:finans_app/utils/currency_formatter.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onTap,
  });

  @override

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == 'gelir';

    // Tarihi formatla (Örn: 10 Mar 2026)
    final dateFormat = DateFormat('dd MMM yyyy');
    final formattedDate = dateFormat.format(transaction.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isIncome
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            formattedDate,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}₺ ${CurrencyFormatter.format(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        onTap: onTap,
        onLongPress: onDelete,
      ),
    );
  }
}

