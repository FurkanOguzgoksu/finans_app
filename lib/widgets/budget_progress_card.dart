import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/providers/transaction_provider.dart';
import 'package:finans_app/utils/currency_formatter.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final double totalExpense = provider.totalExpense;
        final double budgetLimit = provider.budgetLimit;
        final double progress = budgetLimit > 0
            ? (totalExpense / budgetLimit).clamp(0.0, 1.0)
            : 0.0;
        final bool isOverBudget = totalExpense > budgetLimit;

        return Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              _showBudgetDialog(context, provider);
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Aylık Bütçe Durumu',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      Icon(
                        isOverBudget
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: isOverBudget ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 22,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        color: isOverBudget
                            ? Colors.red.withValues(alpha: 0.85)
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      Text(
                        '%${(progress * 100).toInt()}',
                        style: TextStyle(
                          color: progress > 0.4 
                              ? Colors.white 
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₺${CurrencyFormatter.format(totalExpense)} Harcandı',
                        style: TextStyle(
                          color: isOverBudget
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₺${CurrencyFormatter.format(budgetLimit)} Limit',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBudgetDialog(BuildContext context, TransactionProvider provider) {
    final TextEditingController controller = TextEditingController(
      text: CurrencyFormatter.format(provider.budgetLimit),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bütçe Limitini Ayarla'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Aylık Limit (₺)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final double? newLimit = CurrencyFormatter.parse(controller.text);
              if (newLimit != null && newLimit > 0) {
                provider.setBudgetLimit(newLimit);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
