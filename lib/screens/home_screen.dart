import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as models;

/// Ana Ekran - Uygulama açılışında gösterilen dashboard
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        centerTitle: true,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Bakiye Kartı (Geçici)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text('Toplam Bakiye', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        '${provider.balance.toStringAsFixed(2)} ₺',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('Gelir'),
                              Text(
                                '${provider.totalIncome.toStringAsFixed(2)} ₺',
                                style: const TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Gider'),
                              Text(
                                '${provider.totalExpense.toStringAsFixed(2)} ₺',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Mock Veri Ekleme Butonu
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Test İşlemi Ekle (Mock)'),
                onPressed: () {
                  // Rastgele gelir veya gider oluşturarak test ediyoruz
                  final isIncome = DateTime.now().second % 2 == 0;
                  
                  final mockTransaction = models.Transaction(
                    title: isIncome ? 'Test Geliri' : 'Test Harcaması',
                    amount: 250.0,
                    type: isIncome ? 'gelir' : 'gider',
                    categoryId: isIncome ? 1 : 2, // 1: Maaş, 2: Market vs. (Seed verisinde var)
                    date: DateTime.now(),
                  );

                  // Veritabanına kaydet ve State'i güncelle
                  provider.addTransaction(mockTransaction);
                },
              ),

              const SizedBox(height: 32),
              
              Text(
                'Son İşlemler (${provider.transactions.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // İşlemlerin Listesi
              ...provider.transactions.map((tx) => ListTile(
                    leading: Icon(
                        tx.type == 'gelir' ? Icons.arrow_upward : Icons.arrow_downward,
                        color: tx.type == 'gelir' ? Colors.green : Colors.red),
                    title: Text(tx.title),
                    subtitle: Text(tx.date.toString().substring(0, 10)),
                    trailing: Text('${tx.amount} ₺'),
                    onLongPress: () {
                      if (tx.id != null) {
                        provider.deleteTransaction(tx.id!);
                      }
                    },
                  )).toList(),
            ],
          );
        },
      ),
    );
  }
}
