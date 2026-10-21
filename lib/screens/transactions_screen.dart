import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/transaction_detail_dialog.dart';
import '../widgets/transaction_actions.dart';
import '../utils/text_helper.dart';
import '../models/transaction.dart' as models;

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

enum SortOption { dateDesc, dateAsc, amountDesc, amountAsc }

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  int? _selectedCategoryId; // null ise hepsi
  String? _selectedType; // null = hepsi, 'gelir', 'gider'
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  SortOption _sortOption = SortOption.dateDesc;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _selectedType != null ||
      _selectedCategoryId != null ||
      _startDate != null ||
      _endDate != null ||
      _minAmount != null ||
      _maxAmount != null;

  void _clearAllFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategoryId = null;
      _startDate = null;
      _endDate = null;
      _minAmount = null;
      _maxAmount = null;
      _searchQuery = '';
      _searchController.clear();
      _isSearching = false;
      _sortOption = SortOption.dateDesc;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showSortOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
              Text(
                'Sıralama',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortTile(ctx, SortOption.dateDesc, 'Tarihe Göre (Yeniden Eskiye)', Icons.arrow_downward_rounded),
              _buildSortTile(ctx, SortOption.dateAsc, 'Tarihe Göre (Eskiden Yeniye)', Icons.arrow_upward_rounded),
              _buildSortTile(ctx, SortOption.amountDesc, 'Tutara Göre (Büyükten Küçüğe)', Icons.trending_down_rounded),
              _buildSortTile(ctx, SortOption.amountAsc, 'Tutara Göre (Küçükten Büyüğe)', Icons.trending_up_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortTile(BuildContext ctx, SortOption option, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _sortOption == option;
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() => _sortOption = option);
        Navigator.pop(ctx);
      },
    );
  }

  void _showAmountFilterDialog() {
    final theme = Theme.of(context);
    final minCtrl = TextEditingController(text: _minAmount?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: _maxAmount?.toStringAsFixed(0) ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
              Text(
                'Tutar Aralığı',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min (₺)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.remove),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max (₺)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.add),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _minAmount = null;
                          _maxAmount = null;
                        });
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Temizle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _minAmount = double.tryParse(minCtrl.text);
                          _maxAmount = double.tryParse(maxCtrl.text);
                        });
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Uygula'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final txProvider = Provider.of<TransactionProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);

    // Listeyi filtrele
    List<models.Transaction> filteredTransactions = txProvider.transactions.where((tx) {
      // Tür filtresi
      if (_selectedType != null && tx.type != _selectedType) return false;
      // Kategori filtresi
      if (_selectedCategoryId != null && tx.categoryId != _selectedCategoryId) return false;
      // Tarih aralığı filtresi
      if (_startDate != null) {
        final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (txDate.isBefore(start)) return false;
      }
      if (_endDate != null) {
        final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        if (txDate.isAfter(end)) return false;
      }
      // Tutar aralığı filtresi
      if (_minAmount != null && tx.amount < _minAmount!) return false;
      if (_maxAmount != null && tx.amount > _maxAmount!) return false;
      // Arama filtresi
      if (_searchQuery.isNotEmpty) {
        final q = TextHelper.trLower(_searchQuery);
        final matchTitle = TextHelper.trLower(tx.title).contains(q);
        final matchDesc = tx.description != null &&
            TextHelper.trLower(tx.description!).contains(q);
        if (!matchTitle && !matchDesc) return false;
      }
      return true;
    }).toList();

    // Sıralama
    switch (_sortOption) {
      case SortOption.dateDesc:
        filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.dateAsc:
        filteredTransactions.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.amountDesc:
        filteredTransactions.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.amountAsc:
        filteredTransactions.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 16,
        centerTitle: true,
        leading: _isSearching
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  size: 22,
                ),
                tooltip: 'İşlem Ara',
                onPressed: () => setState(() => _isSearching = true),
              ),
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                  border: isDark
                      ? null
                      : Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                          width: 1,
                        ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'İşlem ara (başlık, açıklama)...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              )
            : const Text(
                'Tüm İşlemler',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Aramayı Kapat',
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
          // Sıralama butonu
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sırala',
            onPressed: _showSortOptions,
          ),
          const SizedBox(width: 8),
        ],
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
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ─── Filtre Satırı (Tek Satır) ───
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Tür filtresi: Hepsi / Gelir / Gider
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildTypeChip(theme, null, 'Hepsi', Icons.list_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildTypeChip(theme, 'gelir', 'Gelir', Icons.arrow_upward_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildTypeChip(theme, 'gider', 'Gider', Icons.arrow_downward_rounded),
                  ),
                  // Ayırıcı
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      child: Container(
                        width: 1,
                        height: 24,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  // Tarih filtresi
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: Icon(
                        Icons.date_range_rounded,
                        size: 16,
                        color: _startDate != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      label: Text(
                        _startDate != null && _endDate != null
                            ? '${DateFormat('dd MMM', 'tr_TR').format(_startDate!)} - ${DateFormat('dd MMM', 'tr_TR').format(_endDate!)}'
                            : 'Tarih',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.normal,
                          color: _startDate != null ? theme.colorScheme.primary : null,
                        ),
                      ),
                      onPressed: _pickDateRange,
                      side: BorderSide(
                        color: _startDate != null
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: _startDate != null
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : null,
                    ),
                  ),
                  // Tutar filtresi
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: Icon(
                        Icons.attach_money_rounded,
                        size: 16,
                        color: _minAmount != null || _maxAmount != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      label: Text(
                        _minAmount != null || _maxAmount != null
                            ? '₺${_minAmount?.toStringAsFixed(0) ?? '0'} - ₺${_maxAmount?.toStringAsFixed(0) ?? '∞'}'
                            : 'Tutar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _minAmount != null || _maxAmount != null ? FontWeight.w600 : FontWeight.normal,
                          color: _minAmount != null || _maxAmount != null ? theme.colorScheme.primary : null,
                        ),
                      ),
                      onPressed: _showAmountFilterDialog,
                      side: BorderSide(
                        color: _minAmount != null || _maxAmount != null
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: _minAmount != null || _maxAmount != null
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Kategori Chipları ───
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: const Text('Hepsi', style: TextStyle(fontSize: 12)),
                      selected: _selectedCategoryId == null,
                      onSelected: (selected) => setState(() => _selectedCategoryId = null),
                      selectedColor: theme.colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  ...catProvider.categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: FilterChip(
                        label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                        selected: _selectedCategoryId == cat.id,
                        onSelected: (selected) => setState(() => _selectedCategoryId = selected ? cat.id : null),
                        selectedColor: theme.colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ─── Aktif Filtre Özeti ve Temizle ───
            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${filteredTransactions.length} sonuç',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearAllFilters,
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: const Text('Filtreleri Temizle', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // ─── İşlem Listesi ───
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'Arama kriterlerine uygun işlem bulunamadı.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 15,
                            ),
                          ),
                          if (_hasActiveFilters) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _clearAllFilters,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Filtreleri Temizle'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
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
                          onEdit: () => TransactionActions.showEditSheet(context, tx),
                          onDelete: () => TransactionActions.confirmDelete(context, tx),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(ThemeData theme, String? type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return FilterChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedType = selected ? type : null),
      selectedColor: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }
}
