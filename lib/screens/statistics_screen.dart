import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../models/category.dart';
import '../utils/currency_formatter.dart';
import '../widgets/ai_advisor_bottom_sheet.dart';

Color _hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _selectedMonth;
  int _touchedPieIndex = -1;
  int _touchedIncomePieIndex = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    final now = DateTime.now();
    final maxDate = DateTime(now.year, now.month + 6, 1);

    if (nextMonth.isAfter(maxDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kredi kartı taksitleri için en fazla 6 ay sonrasını görüntüleyebilirsiniz.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedMonth = nextMonth;
      _touchedPieIndex = -1;
      _touchedIncomePieIndex = -1;
    });
  }

  Future<void> _selectMonthAndYear() async {
    int tempYear = _selectedMonth.year;
    final now = DateTime.now();
    final maxDate = DateTime(now.year, now.month + 6, 1);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final months = [
              'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
              'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
            ];

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 28),
                        onPressed: () => setModalState(() => tempYear--),
                      ),
                      Text(
                        tempYear.toString(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 28),
                        onPressed: tempYear >= maxDate.year
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Daha ileri bir yıla gidemezsiniz.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : () => setModalState(() => tempYear++),
                        color: tempYear >= maxDate.year
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final selectedGridDate = DateTime(tempYear, index + 1, 1);
                      final isFutureRestricted = selectedGridDate.isAfter(maxDate);
                      final isSelected = tempYear == _selectedMonth.year &&
                          (index + 1) == _selectedMonth.month;
                          
                      return InkWell(
                        onTap: isFutureRestricted
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kredi kartı taksitleri için en fazla 6 ay sonrasını görebilirsiniz.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : () {
                                setState(() {
                                  _selectedMonth = selectedGridDate;
                                  _touchedPieIndex = -1;
                                });
                                Navigator.pop(context);
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : isFutureRestricted
                                    ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
                                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            months[index],
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : isFutureRestricted
                                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                                      : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final txProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final monthlyIncomeGoal = settingsProvider.monthlyIncome;

    // Seçili aya ait işlemleri filtrele
    final monthlyTx = txProvider.transactions.where((tx) {
      return tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
    }).toList();

    // Sadece giderleri al
    final expenseTx = monthlyTx.where((tx) => tx.type == 'gider').toList();

    // Sadece gelirleri al
    final incomeTx = monthlyTx.where((tx) => tx.type == 'gelir').toList();

    // Kategoriye göre harcama toplamlarını hesapla
    final Map<int, double> categoryTotals = {};
    double totalMonthlyExpense = 0;

    for (var tx in expenseTx) {
      categoryTotals[tx.categoryId] =
          (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
      totalMonthlyExpense += tx.amount;
    }

    // Kategoriye göre gelir toplamlarını hesapla
    final Map<int, double> incomeCategoryTotals = {};
    double totalMonthlyIncome = 0;

    for (var tx in incomeTx) {
      incomeCategoryTotals[tx.categoryId] =
          (incomeCategoryTotals[tx.categoryId] ?? 0) + tx.amount;
      totalMonthlyIncome += tx.amount;
    }

    // Gelir kategori listesi
    final incomeCategoryList = incomeCategoryTotals.entries.toList();
    incomeCategoryList.sort((a, b) => b.value.compareTo(a.value));

    // Günlük harcama ortalaması hesapla
    final now = DateTime.now();
    int daysElapsed;
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      daysElapsed = now.day;
    } else if (_selectedMonth.isBefore(DateTime(now.year, now.month, 1))) {
      daysElapsed = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    } else {
      daysElapsed = 0; // Gelecek ay: henüz geçen gün yok, ortalama hesaplanmaz
    }
    final dailyAverage = daysElapsed > 0 ? totalMonthlyExpense / daysElapsed : 0.0;

    // En büyük 5 harcama
    final topExpenses = List.of(expenseTx);
    topExpenses.sort((a, b) => b.amount.compareTo(a.amount));
    final top5Expenses = topExpenses.take(5).toList();

    // PieChart dilimlerini oluştur
    final pieSections = <PieChartSectionData>[];
    final categoryList = categoryTotals.entries.toList();
    // Büyükten küçüğe sırala
    categoryList.sort((a, b) => b.value.compareTo(a.value));

    int index = 0;
    for (var entry in categoryList) {
      final isTouched = index == _touchedPieIndex;
      final radius = isTouched ? 60.0 : 50.0;
      
      // Kategori bilgisini bul
      Category? cat;
      try {
        cat = catProvider.categories.firstWhere((c) => c.id == entry.key);
      } catch (_) {
        cat = Category(name: 'Bilinmeyen', type: 'gider', color: '#9E9E9E');
      }

      pieSections.add(
        PieChartSectionData(
          color: _hexToColor(cat.color),
          value: entry.value,
          title: '', // İsimleri altta liste olarak vereceğiz
          radius: radius,
          badgeWidget: isTouched
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Text(
                    '%${(entry.value / totalMonthlyExpense * 100).toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                )
              : null,
          badgePositionPercentageOffset: 1.1,
        ),
      );
      index++;
    }

    // Gelir PieChart dilimlerini oluştur
    final incomePieSections = <PieChartSectionData>[];
    int incomeIndex = 0;
    for (var entry in incomeCategoryList) {
      final isTouched = incomeIndex == _touchedIncomePieIndex;
      final radius = isTouched ? 60.0 : 50.0;

      Category? cat;
      try {
        cat = catProvider.categories.firstWhere((c) => c.id == entry.key);
      } catch (_) {
        cat = Category(name: 'Bilinmeyen', type: 'gelir', color: '#4CAF50');
      }

      incomePieSections.add(
        PieChartSectionData(
          color: _hexToColor(cat.color),
          value: entry.value,
          title: '',
          radius: radius,
          badgeWidget: isTouched
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Text(
                    '%${(entry.value / totalMonthlyIncome * 100).toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                )
              : null,
          badgePositionPercentageOffset: 1.1,
        ),
      );
      incomeIndex++;
    }

    // Son 6 ayın bar grafik verileri
    final List<Map<String, dynamic>> barChartData = [];
    double maxBarValue = 0;

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(_selectedMonth.year, _selectedMonth.month - i, 1);
      final monthTx = txProvider.transactions.where((tx) {
        return tx.date.year == month.year && tx.date.month == month.month;
      }).toList();

      double mIncome = 0;
      double mExpense = 0;
      for (var tx in monthTx) {
        if (tx.type == 'gelir') mIncome += tx.amount;
        if (tx.type == 'gider') mExpense += tx.amount;
      }

      if (mIncome > maxBarValue) maxBarValue = mIncome;
      if (mExpense > maxBarValue) maxBarValue = mExpense;

      barChartData.add({
        'label': DateFormat('MMM', 'tr_TR').format(month),
        'income': mIncome,
        'expense': mExpense,
      });
    }

    // Maksimum değeri yuvarlayarak grafiğin Y eksenini güzelleştir
    if (maxBarValue == 0) maxBarValue = 100;
    maxBarValue = (maxBarValue * 1.2); // Üstte biraz boşluk kalsın

    // Kategori isimleriyle map olustur
    final Map<String, double> categoryNameTotals = {};
    for (var entry in categoryTotals.entries) {
      Category? cat;
      try {
        cat = catProvider.categories.firstWhere((c) => c.id == entry.key);
      } catch (_) {
        cat = Category(name: 'Bilinmeyen', type: 'gider', color: '#9E9E9E');
      }
      // Aynı adlı kategoriler (ör. birden fazla "Bilinmeyen") üst üste yazılmasın, toplansın
      categoryNameTotals[cat.name] = (categoryNameTotals[cat.name] ?? 0) + entry.value;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'statistics_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => FractionallySizedBox(
              heightFactor: 0.8,
              child: AiAdvisorBottomSheet(
                totalIncome: totalMonthlyIncome,
                totalExpense: totalMonthlyExpense,
                expensesByCategory: categoryNameTotals,
              ),
            ),
          );
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Yapay Zeka\'ya Danış'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF0F2F5), const Color(0xFFE2E8F0)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildMonthSelector(theme),
            ),

            // Tasarruf Oranı ve Bütçe Durumu Kartı
            SliverToBoxAdapter(
              child: _buildSavingsCard(
                theme,
                isDark,
                totalMonthlyIncome,
                totalMonthlyExpense,
                monthlyIncomeGoal,
              ),
            ),

            // Günlük Harcama Ortalaması Kartı
            SliverToBoxAdapter(
              child: _buildDailyAverageCard(
                theme,
                isDark,
                totalMonthlyExpense,
                dailyAverage,
                daysElapsed,
              ),
            ),
            
            // Pasta Grafik Kartı (Harcama Dağılımı)
            SliverToBoxAdapter(
              child: _buildPieChartCard(
                theme,
                isDark,
                pieSections,
                totalMonthlyExpense,
                categoryList,
                catProvider,
              ),
            ),

            // Gelir Dağılımı Pasta Grafik Kartı
            SliverToBoxAdapter(
              child: _buildIncomePieChartCard(
                theme,
                isDark,
                incomePieSections,
                totalMonthlyIncome,
                incomeCategoryList,
                catProvider,
              ),
            ),
            
            // Bar Grafik Kartı (Gelir/Gider Karşılaştırması)
            SliverToBoxAdapter(
              child: _buildBarChartCard(
                theme, 
                isDark, 
                barChartData, 
                maxBarValue,
              ),
            ),

            // Ayın En Büyük 5 Harcaması
            SliverToBoxAdapter(
              child: _buildTopExpensesCard(
                theme,
                isDark,
                top5Expenses,
                catProvider,
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    final monthStr = DateFormat('MMMM yyyy', 'tr_TR').format(_selectedMonth);
    final now = DateTime.now();
    final maxDate = DateTime(now.year, now.month + 6, 1);
    final isNextDisabled = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1).isAfter(maxDate);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _changeMonth(-1),
            tooltip: 'Önceki Ay',
          ),
          TextButton.icon(
            onPressed: _selectMonthAndYear,
            icon: const Icon(Icons.calendar_month, size: 18),
            label: Text(
              monthStr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: isNextDisabled 
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kredi kartı taksitleri için en fazla 6 ay sonrasını görüntüleyebilirsiniz.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } 
              : () => _changeMonth(1),
            color: isNextDisabled ? theme.colorScheme.onSurface.withValues(alpha: 0.3) : null,
            tooltip: 'Sonraki Ay',
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(
    ThemeData theme,
    bool isDark,
    List<PieChartSectionData> pieSections,
    double totalMonthlyExpense,
    List<MapEntry<int, double>> categoryList,
    CategoryProvider catProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.blue.shade900.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Harcama Dağılımı',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          if (pieSections.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bu ay hiç harcama yok.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = -1;
                              return;
                            }
                            _touchedPieIndex =
                                pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: pieSections,
                    ),
                  ),
                  // Ortadaki Toplam Gider Metni
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Toplam',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '₺${CurrencyFormatter.format(totalMonthlyExpense)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Kategori Listesi (Legend)
            ...List.generate(categoryList.length, (index) {
              final entry = categoryList[index];
              Category? cat;
              try {
                cat = catProvider.categories.firstWhere((c) => c.id == entry.key);
              } catch (_) {
                cat = Category(name: 'Bilinmeyen', type: 'gider', color: '#9E9E9E');
              }
              final isTouched = index == _touchedPieIndex;
              final percent = (entry.value / totalMonthlyExpense) * 100;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isTouched 
                      ? _hexToColor(cat.color).withValues(alpha: 0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _hexToColor(cat.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '%${percent.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₺${CurrencyFormatter.format(entry.value)}',
                      style: TextStyle(
                        fontWeight: isTouched ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildBarChartCard(
    ThemeData theme,
    bool isDark,
    List<Map<String, dynamic>> barChartData,
    double maxBarValue,
  ) {
    // Sadece sıfır olup olmadığını kontrol et
    bool hasAnyData = barChartData.any((e) => e['income'] > 0 || e['expense'] > 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.blue.shade900.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gelir ve Gider Trendi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Son 6 Ay',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Lejant
          Row(
            children: [
              Container(width: 12, height: 12, color: Colors.green),
              const SizedBox(width: 6),
              const Text('Gelir', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(width: 12, height: 12, color: Colors.redAccent),
              const SizedBox(width: 6),
              const Text('Gider', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 32),

          if (!hasAnyData)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Son 6 ayda işlem yok.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxBarValue,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.shade800,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '₺${CurrencyFormatter.format(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= barChartData.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              barChartData[index]['label'],
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxBarValue / 4 > 0 ? maxBarValue / 4 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    barChartData.length,
                    (index) {
                      final data = barChartData[index];
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data['income'],
                            color: Colors.green,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: data['expense'],
                            color: Colors.redAccent,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                        showingTooltipIndicators: [],
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Tasarruf Oranı ve Bütçe Kartı ───
  Widget _buildSavingsCard(
    ThemeData theme,
    bool isDark,
    double totalMonthlyIncome,
    double totalMonthlyExpense,
    double monthlyIncomeGoal,
  ) {
    // Geliri hesaplarken gerçek veriyi veya ayarlardaki hedefi kullan
    final effectiveIncome = totalMonthlyIncome > 0 ? totalMonthlyIncome : monthlyIncomeGoal;
    final savings = effectiveIncome - totalMonthlyExpense;
    final savingsRate = effectiveIncome > 0 ? (savings / effectiveIncome).clamp(0.0, 1.0) : 0.0;
    final spendRate  = effectiveIncome > 0 ? (totalMonthlyExpense / effectiveIncome).clamp(0.0, 1.0) : 0.0;

    // Renk: yeşil → sarı → turuncu → kırmızı
    Color barColor;
    String statusText;
    IconData statusIcon;
    if (spendRate < 0.6) {
      barColor    = const Color(0xFF10B981); // yeşil
      statusText  = 'Harika gidiyorsun! 🎉';
      statusIcon  = Icons.sentiment_very_satisfied_rounded;
    } else if (spendRate < 0.8) {
      barColor    = const Color(0xFFF59E0B); // sarı
      statusText  = 'Dikkatli harca 🙂';
      statusIcon  = Icons.sentiment_neutral_rounded;
    } else if (spendRate < 1.0) {
      barColor    = const Color(0xFFF97316); // turuncu
      statusText  = 'Bütçe sınırında ⚠️';
      statusIcon  = Icons.sentiment_dissatisfied_rounded;
    } else {
      barColor    = const Color(0xFFEF4444); // kırmızı
      statusText  = 'Bütçeyi aştın! ❌';
      statusIcon  = Icons.sentiment_very_dissatisfied_rounded;
    }

    final hasData = effectiveIncome > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.green.shade900.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings_rounded, color: const Color(0xFF10B981), size: 22),
              const SizedBox(width: 8),
              Text(
                'Tasarruf Durumu',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (hasData)
                Icon(statusIcon, color: barColor, size: 22),
            ],
          ),
          const SizedBox(height: 16),

          if (!hasData)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ayarlar ekranından aylık gelirinizi girerek tasarruf analizini aktifleştirin.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Durum yazısı
            Text(
              statusText,
              style: TextStyle(
                fontSize: 13,
                color: barColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: spendRate,
                minHeight: 12,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Harcanan: ₺${CurrencyFormatter.format(totalMonthlyExpense)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  'Gelir: ₺${CurrencyFormatter.format(effectiveIncome)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tasarruf / Açık rakamları
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tasarruf', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                        const SizedBox(height: 4),
                        Text(
                          '₺${CurrencyFormatter.format(savings < 0 ? 0 : savings)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          savings < 0 ? 'Açık' : 'Tasarruf Oranı',
                          style: TextStyle(fontSize: 11, color: barColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          savings < 0
                              ? '-₺${CurrencyFormatter.format(savings.abs())}'
                              : '%${(savingsRate * 100).toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Günlük Harcama Ortalaması Kartı ───
  Widget _buildDailyAverageCard(

    ThemeData theme,
    bool isDark,
    double totalMonthlyExpense,
    double dailyAverage,
    int daysElapsed,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.blue.shade900.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Harcama Özeti',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 16, color: theme.colorScheme.error),
                          const SizedBox(width: 6),
                          Text(
                            'Toplam Harcama',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₺${CurrencyFormatter.format(totalMonthlyExpense)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.today_rounded,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Günlük Ortalama',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₺${CurrencyFormatter.format(dailyAverage)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$daysElapsed gün üzerinden hesaplanmıştır.',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Gelir Dağılımı Pasta Grafik Kartı ───
  Widget _buildIncomePieChartCard(
    ThemeData theme,
    bool isDark,
    List<PieChartSectionData> pieSections,
    double totalMonthlyIncome,
    List<MapEntry<int, double>> categoryList,
    CategoryProvider catProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.blue.shade900.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gelir Dağılımı',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          if (pieSections.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bu ay hiç gelir yok.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIncomePieIndex = -1;
                              return;
                            }
                            _touchedIncomePieIndex =
                                pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: pieSections,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Toplam',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '₺${CurrencyFormatter.format(totalMonthlyIncome)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(categoryList.length, (index) {
              final entry = categoryList[index];
              Category? cat;
              try {
                cat = catProvider.categories.firstWhere((c) => c.id == entry.key);
              } catch (_) {
                cat = Category(name: 'Bilinmeyen', type: 'gelir', color: '#4CAF50');
              }
              final isTouched = index == _touchedIncomePieIndex;
              final percent = (entry.value / totalMonthlyIncome) * 100;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isTouched
                      ? _hexToColor(cat.color).withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _hexToColor(cat.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '%${percent.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₺${CurrencyFormatter.format(entry.value)}',
                      style: TextStyle(
                        fontWeight: isTouched ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── Ayın En Büyük 5 Harcaması Kartı ───
  Widget _buildTopExpensesCard(
    ThemeData theme,
    bool isDark,
    List<dynamic> top5Expenses,
    CategoryProvider catProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.blue.shade900.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: theme.colorScheme.error, size: 22),
              const SizedBox(width: 8),
              Text(
                'En Büyük 5 Harcama',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (top5Expenses.isEmpty)
            SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu ay hiç harcama yok.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(top5Expenses.length, (index) {
              final tx = top5Expenses[index];
              Category? cat;
              try {
                cat = catProvider.categories.firstWhere((c) => c.id == tx.categoryId);
              } catch (_) {
                cat = Category(name: 'Bilinmeyen', type: 'gider', color: '#9E9E9E');
              }

              final rankColors = [
                const Color(0xFFFFD700), // 1. Altın
                const Color(0xFFC0C0C0), // 2. Gümüş
                const Color(0xFFCD7F32), // 3. Bronz
                theme.colorScheme.onSurface.withValues(alpha: 0.4),
                theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: index < 3
                      ? rankColors[index].withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: index < 3
                      ? Border.all(color: rankColors[index].withValues(alpha: 0.2))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: rankColors[index].withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: rankColors[index],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _hexToColor(cat.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cat.name} · ${DateFormat('dd MMM', 'tr_TR').format(tx.date)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₺${CurrencyFormatter.format(tx.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
