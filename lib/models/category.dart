/// Kategori modeli - Gelir/Gider kategorilerini temsil eder
class Category {
  final int? id;
  final String name;
  final String type; // 'gelir' veya 'gider'
  final String icon;
  final String color;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.color = '#4CAF50',
  });

  /// Veritabanından Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    };
  }

  /// Map'ten Category nesnesi oluşturma
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String? ?? 'category',
      color: map['color'] as String? ?? '#4CAF50',
    );
  }

  /// Kopyalama (güncelleme için)
  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, type: $type)';
}
