import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import 'package:finans_app/utils/currency_formatter.dart';
import '../models/transaction.dart' as models;

class _TransactionItemRow {
  final TextEditingController nameController;
  final TextEditingController amountController;

  _TransactionItemRow()
    : nameController = TextEditingController(),
      amountController = TextEditingController();

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();

  // Form Verileri
  // Form Verileri
  bool _isIncome = false; // Varsayılan Gider
  bool _hasDescription = false; // Açıklama kutusu gösterimi

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;

  final List<_TransactionItemRow> _itemRows = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (catProvider.categories.isEmpty) {
        catProvider.loadCategories();
      }
    });
    // Başlangıçta 1 adet boş kalem satırı ekleyelim
    _itemRows.add(_TransactionItemRow());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    for (var row in _itemRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      if (!mounted) return;
      showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      ).then((pickedTime) {
        if (pickedTime == null) return;
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      });
    });
  }

  void _addNewItemRow() {
    setState(() {
      _itemRows.add(_TransactionItemRow());
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      if (_itemRows.length > 1) {
        _itemRows[index].dispose();
        _itemRows.removeAt(index);
      }
    });
  }

  double _calculateTotalDetailedAmount() {
    double total = 0.0;
    for (var row in _itemRows) {
      final val = CurrencyFormatter.parse(row.amountController.text);
      if (val != null) {
        total += val;
      }
    }
    return total;
  }

  void _submitData() {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir tutar, başlık ve kategori seçin.'),
        ),
      );
      return;
    }

    final enteredTitle = _titleController.text.trim();
    final enteredDescription = _hasDescription
        ? _descriptionController.text.trim()
        : "";

    double? enteredAmount;
    List<models.TransactionItem>? transactionItems;

    if (_isIncome) {
      enteredAmount = CurrencyFormatter.parse(_amountController.text);
    } else {
      enteredAmount = _calculateTotalDetailedAmount();
      transactionItems = [];

      for (var row in _itemRows) {
        final name = row.nameController.text.trim();
        final amount = CurrencyFormatter.parse(row.amountController.text);
        if (name.isNotEmpty && amount != null && amount > 0) {
          transactionItems.add(
            models.TransactionItem(name: name, amount: amount),
          );
        }
      }

      if (transactionItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen en az bir geçerli ürün ve tutar girin.'),
          ),
        );
        return;
      }
    }

    if (enteredAmount == null || enteredAmount <= 0) {
      return;
    }

    final newTx = models.Transaction(
      title: enteredTitle,
      amount: enteredAmount,
      type: _isIncome ? 'gelir' : 'gider',
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      description: enteredDescription.isNotEmpty ? enteredDescription : null,
      items: transactionItems,
    );

    Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).addTransaction(newTx);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_isIncome ? "Gelir" : "Gider"} başarıyla eklendi!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categories = Provider.of<CategoryProvider>(context).categories;
    final theme = Theme.of(context);

    final filteredCategories = categories
        .where((cat) => cat.type == (_isIncome ? 'gelir' : 'gider'))
        .toList();

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: bottomInset > 0 ? bottomInset + 24 : 32,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Gider'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Gelir'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: <bool>{_isIncome},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isIncome = newSelection.first;
                    _selectedCategoryId = null;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return _isIncome
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2);
                    }
                    return theme.colorScheme.surface;
                  }),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'İşlem Başlığı (örn: Fiş, Market, Kira)',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Başlık boş olamaz';
                  }
                  return null;
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isIncome ? 'Tutar' : 'Kalemler (Satır ve Tutar)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasDescription = !_hasDescription;
                      });
                    },
                    icon: Icon(
                      _hasDescription ? Icons.close : Icons.notes,
                      size: 16,
                    ),
                    label: Text(
                      _hasDescription ? 'Açıklamayı Gizle' : 'Açıklama Ekle',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tutarı veya Kalemleri göster
              if (_isIncome)
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Toplam Tutar (₺)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Geçerli bir tutar girin';
                    if (CurrencyFormatter.parse(value) == null) return 'Geçerli bir sayı girin';
                    return null;
                  },
                )
              else
                _buildDetailedItemsSection(theme),
              const SizedBox(height: 16),

              // Açıklama alanı (_hasDescription true ise göster)
              if (_hasDescription) ...[
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama / Detaylar',
                    hintText: 'Ek notlar...',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      value: _selectedCategoryId,
                      hint: const Text('Seçiniz'),
                      items: filteredCategories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text(
                            cat.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCategoryId = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: _presentDatePicker,
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(
                        DateFormat('dd/MM HH:mm').format(_selectedDate),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'İşlemi Kaydet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedItemsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._itemRows.asMap().entries.map((entry) {
            int index = entry.key;
            var row = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: row.nameController,
                      decoration: const InputDecoration(
                        hintText: 'Satır Adı',
                        isDense: true,
                        contentPadding: EdgeInsets.all(12),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Eksik';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: row.amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [CurrencyInputFormatter()],
                      onChanged: (val) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Tutar',
                        isDense: true,
                        contentPadding: EdgeInsets.all(12),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Eksik';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (_itemRows.length > 1)
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeItemRow(index),
                    ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addNewItemRow,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Satır Ekle'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam Tutar:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '₺ ${CurrencyFormatter.format(_calculateTotalDetailedAmount())}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
