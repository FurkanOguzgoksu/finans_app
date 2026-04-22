import 'package:finans_app/models/transaction.dart';

class ParsedReceipt {
  final double? amount;
  final DateTime? date;
  final String? merchantName;
  final String rawText;
  final List<TransactionItem>? items;
  final double confidence; // 0.0-1.0 parsing quality
  final List<String>? rawLines; // for UI/debug

  ParsedReceipt({
    this.amount,
    this.date,
    this.merchantName,
    required this.rawText,
    this.items,
    this.confidence = 0.5,
    this.rawLines,
  });

  bool get hasAmount => amount != null && amount! > 0;
  bool get hasDate => date != null;
  bool get hasMerchantName => merchantName != null && merchantName!.isNotEmpty;

  /// Tutar ve tarih bulunmuşsa anlamlı bir fiş olarak kabul edilir
  bool get isValid => hasAmount || hasDate;

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date?.toIso8601String(),
      'merchantName': merchantName,
      'rawText': rawText,
      'confidence': confidence,
      'rawLines': rawLines,
      'items': items?.map((i) => i.toMap()).toList(),
    };
  }

  factory ParsedReceipt.fromMap(Map<String, dynamic> map) {
    return ParsedReceipt(
      amount: map['amount'],
      date: map['date'] != null ? DateTime.tryParse(map['date']) : null,
      merchantName: map['merchantName'],
      rawText: map['rawText'] ?? '',
      confidence: map['confidence'] ?? 0.5,
      rawLines: map['rawLines'],
      items: map['items'] != null
          ? (map['items'] as List)
                .map((i) => TransactionItem.fromMap(i))
                .toList()
          : null,
    );
  }

  @override
  String toString() {
    return 'ParsedReceipt(amount: $amount, date: $date, merchantName: $merchantName, itemsCount: ${items?.length ?? 0})';
  }
}
