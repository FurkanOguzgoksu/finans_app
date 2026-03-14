import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

class DashboardChart extends StatelessWidget {
  const DashboardChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final totalIncome = provider.totalIncome;
        final totalExpense = provider.totalExpense;

        // Veri Yoksa Gostermiyoruz/Bos Ekran Gosterebiliriz
        if (totalIncome == 0 && totalExpense == 0) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Henüz analiz edilecek veri bulunmuyor.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.greenAccent,
                  value: totalIncome,
                  title: '${(totalIncome / (totalIncome + totalExpense) * 100).toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.redAccent,
                  value: totalExpense,
                  title: '${(totalExpense / (totalIncome + totalExpense) * 100).toStringAsFixed(1)}%',
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
