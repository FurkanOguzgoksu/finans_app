import 'dart:convert';

/// Fiş/Fatura Kalemi (Alt İşlem) modeli
class TransactionItem {
  final String name;
  final double amount;

  TransactionItem({required this.name, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}

/// İşlem (Transaction) modeli - Gelir ve gider kayıtlarını temsil eder
class Transaction {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'gelir' veya 'gider'
  final int categoryId;
  final DateTime date;
  final String? description;
  final String? receiptId;
  final List<TransactionItem>? items;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.description,
    this.receiptId,
    this.items,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Veritabanına yazma için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'description': description,
      'receipt_id': receiptId,
      'items_json': items != null ? jsonEncode(items!.map((e) => e.toMap()).toList()) : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Map'ten Transaction nesnesi oluşturma
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as int,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      receiptId: map['receipt_id'] as String?,
      items: map['items_json'] != null
          ? (jsonDecode(map['items_json'] as String) as List)
              .map((e) => TransactionItem.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Kopyalama (güncelleme için)
  Transaction copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    int? categoryId,
    DateTime? date,
    String? description,
    String? receiptId,
    List<TransactionItem>? items,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptId: receiptId ?? this.receiptId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Transaction(id: $id, title: $title, amount: $amount, type: $type)';
}
