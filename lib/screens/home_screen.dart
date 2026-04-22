import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/providers/transaction_provider.dart';
import 'package:finans_app/providers/settings_provider.dart';
import 'package:finans_app/models/transaction.dart' as models;
import 'package:finans_app/services/recurring_income_service.dart';

// UI Bileşenleri (Widgets)
import 'package:finans_app/widgets/summary_card.dart';
import 'package:finans_app/widgets/budget_progress_card.dart';
import 'package:finans_app/widgets/transaction_list_item.dart';
import 'package:finans_app/utils/responsive_layout.dart';
import 'package:finans_app/widgets/transaction_options_sheet.dart';

import 'package:finans_app/widgets/transaction_detail_dialog.dart';
import 'package:finans_app/widgets/add_transaction_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _recurringChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_recurringChecked) {
      _recurringChecked = true;
      _checkRecurringIncome();
    }
  }

  /// Uygulama açıldığında tekrarlayan gelir kontrolü yapar.
  /// SettingsProvider yüklenmeyi tamamladıktan sonra çalışır.
  Future<void> _checkRecurringIncome() async {
    final settings = context.read<SettingsProvider>();
    final txProvider = context.read<TransactionProvider>();

    // SettingsProvider async yüklenmiş olabilir, kısa bekleme
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final added = await RecurringIncomeService.checkAndAdd(
      settings: settings,
      txProvider: txProvider,
      context: context,
    );

    if (added && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('${settings.incomeTitle} otomatik eklendi ✓'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer2<TransactionProvider, SettingsProvider>(
        builder: (context, provider, settings, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = provider.transactions;

          return ResponsiveLayout(
            mobileScaffold: _buildMobileLayout(context, provider, settings, transactions),
            tabletScaffold: _buildTabletLayout(context, provider, settings, transactions),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const TransactionOptionsSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('İşlem Ekle'),
      ),
    );
  }

  /// Telefon ve Dikey Ekranlar İçin Yapı
  Widget _buildMobileLayout(
    BuildContext context,
    TransactionProvider provider,
    SettingsProvider settings,
    List<models.Transaction> transactions,
  ) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                SummaryCard(
                  totalIncome: provider.totalIncome,
                  totalExpense: provider.totalExpense,
                  balance: provider.balance,
                  monthlyIncome: settings.monthlyIncome,
                ),
                const SizedBox(height: 24),
                const BudgetProgressCard(), // Bütçe kartı
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Son İşlemler'),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        _buildTransactionsSliverList(context, provider, transactions),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  /// Tablet ve Web/Geniş Ekranlar İçin Yapı
  Widget _buildTabletLayout(
    BuildContext context,
    TransactionProvider provider,
    SettingsProvider settings,
    List<models.Transaction> transactions,
  ) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol Taraf: Kart ve Grafik
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SummaryCard(
                        totalIncome: provider.totalIncome,
                        totalExpense: provider.totalExpense,
                        balance: provider.balance,
                        monthlyIncome: settings.monthlyIncome,
                      ),
                      const SizedBox(height: 24),
                      const BudgetProgressCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Sağ Taraf: Geçmiş İşlemler Listesi
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'Son İşlemler'),
                      const SizedBox(height: 16),
                      if (transactions.isEmpty)
                        const Center(child: Text("Henüz işlem yok."))
                      else
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return TransactionListItem(
                              transaction: tx,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => TransactionDetailDialog(transaction: tx),
                                );
                              },
                              onEdit: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  builder: (_) => AddTransactionSheet(transaction: tx),
                                );
                              },
                              onDelete: () {
                                if (tx.id != null) {
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
                                          onPressed: () {
                                            provider.deleteTransaction(tx.id!);
                                            Navigator.of(ctx).pop();
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // .... Metotların devamı unchanged kalacak (SliverAppBar pb.). Alt satırda SliverList güncellemesi var. Değişken limitini aşmamak için bunu parçalıyorum.


  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80.0,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Finans Asistanı',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTransactionsSliverList(
    BuildContext context,
    TransactionProvider provider,
    List<models.Transaction> transactions,
  ) {
    if (transactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'Henüz işlem bulunmuyor.\nSağ alt köşeden başlayabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final tx = transactions[index];
          return TransactionListItem(
            transaction: tx,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => TransactionDetailDialog(transaction: tx),
              );
            },
            onEdit: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => AddTransactionSheet(transaction: tx),
              );
            },
            onDelete: () {
               if (tx.id != null) {
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
                         onPressed: () {
                           provider.deleteTransaction(tx.id!);
                           Navigator.of(ctx).pop();
                         },
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                         child: const Text('Sil', style: TextStyle(color: Colors.white)),
                       ),
                     ],
                   ),
                 );
               }
            },
          );
        }, childCount: transactions.length),
      ),
    );
  }
}

