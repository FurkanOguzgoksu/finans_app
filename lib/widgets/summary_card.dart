import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const SummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
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
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Toplam Bakiye',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₺ ${balance.toStringAsFixed(2)}',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
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
            color: colorScheme.onPrimary.withOpacity(0.2),
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
                color: colorScheme.onPrimary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₺ ${amount.toStringAsFixed(2)}',
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
}
