import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/transaction_detail_dialog.dart';
import '../models/transaction.dart' as models;

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  int? _selectedCategoryId; // null ise hepsi

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);

    // Listeyi filtrele
    List<models.Transaction> filteredTransactions = txProvider.transactions.where((tx) {
      if (_selectedCategoryId != null && tx.categoryId != _selectedCategoryId) return false;
      if (_searchQuery.isNotEmpty) {
        if (!tx.title.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tüm İşlemler', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'İşlem ara (örn: Market, Maaş)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: const Text('Hepsi'),
                    selected: _selectedCategoryId == null,
                    onSelected: (selected) => setState(() => _selectedCategoryId = null),
                    selectedColor: theme.colorScheme.primaryContainer,
                  ),
                ),
                ...catProvider.categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: _selectedCategoryId == cat.id,
                      onSelected: (selected) => setState(() => _selectedCategoryId = selected ? cat.id : null),
                      selectedColor: theme.colorScheme.primaryContainer,
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('Arama kriterlerine uygun işlem bulunamadı.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      return TransactionListItem(
                        transaction: tx,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => TransactionDetailDialog(transaction: tx),
                          );
                        },
                        onDelete: () {
                          if (tx.id != null) txProvider.deleteTransaction(tx.id!);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


