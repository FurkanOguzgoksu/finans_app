import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import 'package:finans_app/utils/currency_formatter.dart';
import '../models/transaction.dart' as models;

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();

  // Form Verileri
  bool _isIncome = false; // Varsayılan Gider
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Kategori listesi boşsa sayfaya girince otomatik yeniden yüklemeyi tetikle (Eski sürümden kalma sorunlarını çözer)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (catProvider.categories.isEmpty) {
        catProvider.loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
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
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _submitData() {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      // Form geçersizse veya kategori seçilmemişse kaydetme
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir tutar, başlık ve kategori seçin.'),
        ),
      );
      return;
    }

    final enteredTitle = _titleController.text.trim();
    final enteredAmount = CurrencyFormatter.parse(_amountController.text);

    if (enteredAmount == null || enteredAmount <= 0) {
      return;
    }

    final newTx = models.Transaction(
      title: enteredTitle,
      amount: enteredAmount,
      type: _isIncome ? 'gelir' : 'gider',
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
    );

    // Sağlayıcıya işlemi ekle
    Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).addTransaction(newTx);

    // Formu kapat
    Navigator.of(context).pop();

    // Kullanıcıya bilgi ver
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_isIncome ? "Gelir" : "Gider"} başarıyla eklendi!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ekran klavyesi açıldığında formun yukarı kayması için padding hesaplıyoruz
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categories = Provider.of<CategoryProvider>(context).categories;
    final theme = Theme.of(context);

    // Sadece mevcut işleme uygun kategorileri (Gelir veya Gider) filtreleyelim
    final filteredCategories = categories.where((cat) {
      return cat.type == (_isIncome ? 'gelir' : 'gider');
    }).toList();

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: bottomInset + 32, // Klavye boşluğu
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
              // Üstte küçük bir çekme çubuğu (Drag Handle)
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

              // Gelir / Gider Segmentli Seçimi
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
                    _selectedCategoryId =
                        null; // Kategori tipi değiştiğinde seçimi sıfırla
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return _isIncome
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2);
                    }
                    return theme.colorScheme.surface;
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Tutar Alanı
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Tutar (₺)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [CurrencyInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Tutar girmelisiniz';
                  if (CurrencyFormatter.parse(value) == null)
                    return 'Geçerli bir sayı girin';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Başlık Alanı
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'İşlem Başlığı (örn: Market, Kira)',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Başlık boş olamaz';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategori ve Tarih Seçimi (Yan yana)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Kategori Dropdown
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
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tarih Seçici Buton
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: _presentDatePicker,
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(
                        DateFormat('dd/MM').format(_selectedDate),
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Kaydet Butonu
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
}
