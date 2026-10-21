import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/models/category.dart';
import 'package:finans_app/providers/category_provider.dart';
import 'package:finans_app/providers/transaction_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Kategori Yönetimi Ekranı
/// Kullanıcı gelir/gider kategorilerini ekleyebilir, düzenleyebilir ve silebilir.
class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  // Kullanıcıya sunulan ikon seçenekleri
  static const List<_IconOption> _availableIcons = [
    _IconOption('shopping_cart', Icons.shopping_cart),
    _IconOption('restaurant', Icons.restaurant),
    _IconOption('directions_bus', Icons.directions_bus),
    _IconOption('local_hospital', Icons.local_hospital),
    _IconOption('receipt_long', Icons.receipt_long),
    _IconOption('school', Icons.school),
    _IconOption('sports_esports', Icons.sports_esports),
    _IconOption('movie', Icons.movie),
    _IconOption('phone_android', Icons.phone_android),
    _IconOption('home', Icons.home),
    _IconOption('pets', Icons.pets),
    _IconOption('checkroom', Icons.checkroom),
    _IconOption('fitness_center', Icons.fitness_center),
    _IconOption('flight', Icons.flight),
    _IconOption('local_gas_station', Icons.local_gas_station),
    _IconOption('attach_money', Icons.attach_money),
    _IconOption('account_balance_wallet', Icons.account_balance_wallet),
    _IconOption('work', Icons.work),
    _IconOption('card_giftcard', Icons.card_giftcard),
    _IconOption('savings', Icons.savings),
    _IconOption('category', Icons.category),
    _IconOption('coffee', Icons.coffee),
    _IconOption('local_parking', Icons.local_parking),
    _IconOption('wifi', Icons.wifi),
  ];

  // Kullanıcıya sunulan renk seçenekleri
  static const List<Color> availableColors = [
    Color(0xFFF44336), // Kırmızı
    Color(0xFFE91E63), // Pembe
    Color(0xFF9C27B0), // Mor
    Color(0xFF673AB7), // Koyu Mor
    Color(0xFF3F51B5), // İndigo
    Color(0xFF2196F3), // Mavi
    Color(0xFF03A9F4), // Açık Mavi
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Yeşil
    Color(0xFF8BC34A), // Açık Yeşil
    Color(0xFFFF9800), // Turuncu
    Color(0xFFFF5722), // Koyu Turuncu
  ];

  /// İkon adından IconData'ya dönüştürme
  static IconData getIconData(String iconName) {
    final match = _availableIcons.where((opt) => opt.name == iconName);
    if (match.isNotEmpty) return match.first.icon;
    return Icons.category;
  }

  /// Renk hex string'inden Color'a dönüştürme
  static Color getColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kategori Yönetimi'),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            tabs: const [
              Tab(icon: Icon(Icons.arrow_downward), text: 'Gider'),
              Tab(icon: Icon(Icons.arrow_upward), text: 'Gelir'),
            ],
          ),
        ),
        body: Consumer<CategoryProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final giderCategories = provider.getCategoriesByType('gider');
            final gelirCategories = provider.getCategoriesByType('gelir');

            return TabBarView(
              children: [
                _buildCategoryList(context, provider, giderCategories, 'gider'),
                _buildCategoryList(context, provider, gelirCategories, 'gelir'),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddCategoryDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Yeni Kategori'),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    CategoryProvider provider,
    List<Category> categories,
    String type,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'gider'
                  ? 'Henüz gider kategorisi yok'
                  : 'Henüz gelir kategorisi yok',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final color = getColor(category.color);
        final icon = getIconData(category.icon);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              category.type == 'gelir' ? 'Gelir Kategorisi' : 'Gider Kategorisi',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCategoryDialog(context, category);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, category);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit, size: 20),
                    title: Text('Düzenle'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red, size: 20),
                    title: Text('Sil', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    String selectedType = 'gider';
    String selectedIcon = 'category';
    Color selectedColor = availableColors[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Yeni Kategori'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori Adı
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Adı',
                      border: OutlineInputBorder(),
                      hintText: 'Örn: Kıyafet',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tür Seçimi
                  Text(
                    'Tür',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'gider',
                        label: Text('Gider'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: 'gelir',
                        label: Text('Gelir'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (value) {
                      setState(() => selectedType = value.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  // İkon Seçimi
                  Text(
                    'İkon',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableIcons.map((opt) {
                      final isSelected = opt.name == selectedIcon;
                      return InkWell(
                        onTap: () => setState(() => selectedIcon = opt.name),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? selectedColor
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            opt.icon,
                            color: isSelected ? selectedColor : null,
                            size: 22,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Renk Seçimi
                  Text(
                    'Renk',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableColors.map((color) {
                      final isSelected = color.toARGB32() == selectedColor.toARGB32();
                      return InkWell(
                        onTap: () => setState(() => selectedColor = color),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kategori adı boş olamaz')),
                    );
                    return;
                  }

                  final colorHex =
                      '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

                  final category = Category(
                    name: name,
                    type: selectedType,
                    icon: selectedIcon,
                    color: colorHex,
                  );

                  _runCategoryChange(
                    context,
                    dialogContext: ctx,
                    action: () => context.read<CategoryProvider>().addCategory(category),
                    successMessage: '"$name" kategorisi eklendi',
                    errorMessage: 'Kategori eklenemedi.',
                  );
                },
                child: const Text('Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final controller = TextEditingController(text: category.name);
    String selectedType = category.type;
    String selectedIcon = category.icon;
    Color selectedColor = getColor(category.color);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Kategori Düzenle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Adı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Tür',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'gider',
                        label: Text('Gider'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: 'gelir',
                        label: Text('Gelir'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (value) {
                      setState(() => selectedType = value.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'İkon',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableIcons.map((opt) {
                      final isSelected = opt.name == selectedIcon;
                      return InkWell(
                        onTap: () => setState(() => selectedIcon = opt.name),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? selectedColor
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            opt.icon,
                            color: isSelected ? selectedColor : null,
                            size: 22,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Renk',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableColors.map((color) {
                      final isSelected = color.toARGB32() == selectedColor.toARGB32();
                      return InkWell(
                        onTap: () => setState(() => selectedColor = color),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kategori adı boş olamaz')),
                    );
                    return;
                  }

                  final colorHex =
                      '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

                  final updated = category.copyWith(
                    name: name,
                    type: selectedType,
                    icon: selectedIcon,
                    color: colorHex,
                  );

                  _runCategoryChange(
                    context,
                    dialogContext: ctx,
                    action: () => context.read<CategoryProvider>().updateCategory(updated),
                    successMessage: '"$name" kategorisi güncellendi',
                    errorMessage: 'Kategori güncellenemedi.',
                  );
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Category category) {
    // İşlemi olan kategori veritabanında silinemez (işlemler sessizce
    // silinmesin diye); kullanıcıya önceden kaç işlem olduğu söylenir.
    final usageCount = context
        .read<TransactionProvider>()
        .transactions
        .where((tx) => tx.categoryId == category.id)
        .length;
    if (usageCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kategori Silinemez'),
          content: Text(
            '"${category.name}" kategorisinde $usageCount işlem var.\n\n'
            'Kategoriyi silmeden önce bu işlemleri başka bir kategoriye taşıyın veya silin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text(
          '"${category.name}" kategorisini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (category.id != null) {
                _runCategoryChange(
                  context,
                  dialogContext: ctx,
                  action: () =>
                      context.read<CategoryProvider>().deleteCategory(category.id!),
                  successMessage: '"${category.name}" kategorisi silindi',
                  errorMessage: 'Kategori silinemedi.',
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Kategori ekleme/güncelleme/silme işlemini çalıştırır: diyaloğu kapatır,
/// işlemin bitmesini bekler ve sonucu kullanıcıya bildirir.
Future<void> _runCategoryChange(
  BuildContext context, {
  required BuildContext dialogContext,
  required Future<void> Function() action,
  required String successMessage,
  required String errorMessage,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final future = action();
  Navigator.of(dialogContext).pop();
  try {
    await future;
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
  } catch (e) {
    debugPrint('Kategori işlemi başarısız: $e');
    // 23503: kategoriye bağlı işlem var (liste güncel değilken silinmeye çalışıldı)
    final reason = e is PostgrestException && e.code == '23503'
        ? 'Bu kategoriye ait işlemler var.'
        : 'İnternet bağlantınızı kontrol edin.';
    messenger.showSnackBar(
      SnackBar(
        content: Text('$errorMessage $reason'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

/// İkon seçeneği yardımcı sınıfı
class _IconOption {
  final String name;
  final IconData icon;
  const _IconOption(this.name, this.icon);
}
