import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/providers/transaction_provider.dart';
import 'package:finans_app/models/transaction.dart' as models;

// UI Bileşenleri (Widgets)
import 'package:finans_app/widgets/summary_card.dart';
import 'package:finans_app/widgets/dashboard_chart.dart';
import 'package:finans_app/widgets/transaction_list_item.dart';
import 'package:finans_app/utils/responsive_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = provider.transactions;

          return ResponsiveLayout(
            mobileScaffold: _buildMobileLayout(context, provider, transactions),
            tabletScaffold: _buildTabletLayout(context, provider, transactions),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showMockAddDialog(context);
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
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Aylık Analiz'),
                const DashboardChart(),
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
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'Aylık Analiz'),
                      const DashboardChart(),
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
                              onDelete: () {
                                if (tx.id != null)
                                  provider.deleteTransaction(tx.id!);
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
            onDelete: () {
              if (tx.id != null) provider.deleteTransaction(tx.id!);
            },
          );
        }, childCount: transactions.length),
      ),
    );
  }

  // Hızlı test için pop-up (mock ekle) mekanizması
  void _showMockAddDialog(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final isIncome = DateTime.now().second % 2 == 0;

    final mockTx = models.Transaction(
      title: isIncome ? 'Test Geliri' : 'Fatura/Market (Test)',
      amount: 450.0,
      type: isIncome ? 'gelir' : 'gider',
      categoryId: isIncome ? 1 : 2,
      date: DateTime.now(),
    );
    provider.addTransaction(mockTx);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Test İşlemi Eklendi!')));
  }
}
