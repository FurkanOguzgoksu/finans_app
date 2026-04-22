import 'package:flutter/material.dart';
import 'package:finans_app/utils/currency_formatter.dart';

class SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double monthlyIncome;

  const SummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.monthlyIncome = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary, // Örn: Koyu Mavi
            colorScheme.primaryContainer, // Örn: Açık Mavi
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            monthlyIncome > 0 ? 'Net Bakiye' : 'Toplam Bakiye',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₺ ${CurrencyFormatter.format(balance)}',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (monthlyIncome > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 14,
                    color: colorScheme.onPrimary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Aylık Gelir: ₺${CurrencyFormatter.format(monthlyIncome)}',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Gelir Kısmı
              _buildMinicard(
                context,
                title: 'Gelir',
                amount: totalIncome,
                iconData: Icons.arrow_downward_rounded,
                iconColor: Colors.greenAccent,
              ),
              // Gider Kısmı
              _buildMinicard(
                context,
                title: 'Gider',
                amount: totalExpense,
                iconData: Icons.arrow_upward_rounded,
                iconColor: Colors.redAccent,
              ),
            ],
          ),
          if (monthlyIncome > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            _buildSavingsRow(context, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildMinicard(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData iconData,
    required Color iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.onPrimary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onPrimary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₺ ${CurrencyFormatter.format(amount)}',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavingsRow(BuildContext context, ColorScheme colorScheme) {
    final effectiveIncome = monthlyIncome > 0 ? monthlyIncome : 1.0;
    final savingsAmount = monthlyIncome - totalExpense;
    final savingsRate = ((savingsAmount / effectiveIncome) * 100).clamp(-100.0, 100.0);
    final isSaving = savingsAmount >= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Tasarruf',
          style: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.75),
            fontSize: 13,
          ),
        ),
        Row(
          children: [
            Icon(
              isSaving ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: isSaving ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(width: 6),
            Text(
              '₺${CurrencyFormatter.format(savingsAmount.abs())} (${savingsRate.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: isSaving ? Colors.greenAccent : Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
