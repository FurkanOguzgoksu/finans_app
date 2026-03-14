/// Fiş/Fatura (Receipt) modeli - OCR ile taranan belgeleri temsil eder
class Receipt {
  final int? id;
  final String imagePath;
  final String? extractedText;
  final double? extractedAmount;
  final String? merchantName;
  final DateTime? receiptDate;
  final DateTime createdAt;

  Receipt({
    this.id,
    required this.imagePath,
    this.extractedText,
    this.extractedAmount,
    this.merchantName,
    this.receiptDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Veritabanına yazma için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'extracted_text': extractedText,
      'extracted_amount': extractedAmount,
      'merchant_name': merchantName,
      'receipt_date': receiptDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Map'ten Receipt nesnesi oluşturma
  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String,
      extractedText: map['extracted_text'] as String?,
      extractedAmount: map['extracted_amount'] != null
          ? (map['extracted_amount'] as num).toDouble()
          : null,
      merchantName: map['merchant_name'] as String?,
      receiptDate: map['receipt_date'] != null
          ? DateTime.parse(map['receipt_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Kopyalama (güncelleme için)
  Receipt copyWith({
    int? id,
    String? imagePath,
    String? extractedText,
    double? extractedAmount,
    String? merchantName,
    DateTime? receiptDate,
    DateTime? createdAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      extractedAmount: extractedAmount ?? this.extractedAmount,
      merchantName: merchantName ?? this.merchantName,
      receiptDate: receiptDate ?? this.receiptDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Receipt(id: $id, merchantName: $merchantName, extractedAmount: $extractedAmount)';
}
