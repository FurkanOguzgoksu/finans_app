import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:finans_app/providers/ocr_provider.dart';
import 'package:finans_app/providers/category_provider.dart';
import 'package:finans_app/providers/transaction_provider.dart';
import 'package:finans_app/services/receipt_parser.dart';
import 'package:finans_app/services/invoice_parser.dart';
import 'package:finans_app/services/ai_parser_service.dart';
import 'package:finans_app/models/transaction.dart' as models;
import 'package:finans_app/models/category.dart' as model_cat;
import 'package:finans_app/utils/currency_formatter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Fiş Tarama Ekranı — OCR ile fiş/fatura tarama
///
/// Akış: Kamera/Galeri → Önizleme → (İsteğe bağlı) Kırpma → OCR Tarama → Sonuç
class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran açıldığında önceki kamerada kalan veya taranan veriyi sıfırla
    // Ancak PDF'den gelen veriler varsa (state == done) sıfırlama!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<OcrProvider>();
        if (provider.state != OcrState.done) {
          provider.reset();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _ReceiptScanBody();
  }
}

class _ReceiptScanBody extends StatelessWidget {
  const _ReceiptScanBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiş Tara'),
        centerTitle: true,
        actions: [
          Consumer<OcrProvider>(
            builder: (context, provider, _) {
              if (provider.hasImage || provider.hasResult) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Sıfırla',
                  onPressed: provider.reset,
                );
              }
              return const SizedBox.shrink();
            },
          ),
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
        child: SafeArea(
          child: Consumer<OcrProvider>(
            builder: (context, provider, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildContent(context, provider, theme, isDark),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OcrProvider provider,
    ThemeData theme,
    bool isDark,
  ) {
    // Hata durumu
    if (provider.state == OcrState.error) {
      return _ErrorView(
        key: const ValueKey('error'),
        message: provider.errorMessage ?? 'Bilinmeyen hata',
        onRetry: provider.reset,
        theme: theme,
        isDark: isDark,
      );
    }

    // OCR işleniyor
    if (provider.state == OcrState.processing) {
      return _ProcessingView(
        key: const ValueKey('processing'),
        theme: theme,
        isDark: isDark,
      );
    }

    // OCR tamamlandı — sonuç göster
    if (provider.state == OcrState.done) {
      return _ResultView(
        key: const ValueKey('result'),
        rawText: provider.rawText ?? '',
        imagePath: provider.imagePath,
        isPdf: provider.isPdf,
        pdfPath: provider.pdfPath,
        theme: theme,
        isDark: isDark,
        onReset: provider.reset,
      );
    }

    // Fotoğraf seçildi — önizleme + aksiyonlar
    if (provider.hasImage) {
      return _PreviewView(
        key: const ValueKey('preview'),
        imagePath: provider.imagePath!,
        provider: provider,
        theme: theme,
        isDark: isDark,
      );
    }

    // Başlangıç durumu — kamera/galeri seçimi
    return _IdleView(
      key: const ValueKey('idle'),
      provider: provider,
      theme: theme,
      isDark: isDark,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. BAŞLANGIÇ DURUMU — Kamera ve Galeri Seçimi
// ═══════════════════════════════════════════════════════════════
class _IdleView extends StatelessWidget {
  final OcrProvider provider;
  final ThemeData theme;
  final bool isDark;

  const _IdleView({
    super.key,
    required this.provider,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fiş ikonu — gradient container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Fişinizi Tarayın',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Fiş veya faturanızın fotoğrafını çekin\nya da galeriden seçin',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),

          // Kamera butonu
          _ActionButton(
            icon: Icons.camera_alt_rounded,
            label: 'Kamera ile Çek',
            subtitle: 'Fişin fotoğrafını çekin',
            color: theme.colorScheme.primary,
            isDark: isDark,
            onTap: provider.pickFromCamera,
          ),
          const SizedBox(height: 16),

          // Galeri butonu
          _ActionButton(
            icon: Icons.photo_library_rounded,
            label: 'Galeriden Seç',
            subtitle: 'Mevcut bir fotoğrafı seçin',
            color: const Color(0xFF10B981), // Yeşil ton
            isDark: isDark,
            onTap: provider.pickFromGallery,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. ÖNİZLEME — Seçilen fotoğraf + Kırp/Tara butonları
// ═══════════════════════════════════════════════════════════════
class _PreviewView extends StatelessWidget {
  final String imagePath;
  final OcrProvider provider;
  final ThemeData theme;
  final bool isDark;

  const _PreviewView({
    super.key,
    required this.imagePath,
    required this.provider,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Başlık
          Text(
            'Fotoğraf Hazır',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Taramaya başlayabilir veya önce kırpabilirsiniz',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),

          // Fotoğraf önizleme
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Butonlar
          Row(
            children: [
              // Kırp butonu
              Expanded(
                child: _GlassButton(
                  icon: Icons.crop_rounded,
                  label: 'Kırp',
                  isDark: isDark,
                  onTap: () => provider.cropImage(context),
                ),
              ),
              const SizedBox(width: 12),
              // Tara butonu
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: provider.runOcr,
                  icon: const Icon(Icons.text_snippet_rounded),
                  label: const Text(
                    'Metni Tara',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. İŞLENİYOR — OCR Yükleniyor Animasyonu
// ═══════════════════════════════════════════════════════════════
class _ProcessingView extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;

  const _ProcessingView({super.key, required this.theme, required this.isDark});

  @override
  State<_ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends State<_ProcessingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.theme.colorScheme.primary,
                        widget.theme.colorScheme.primary.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.theme.colorScheme.primary.withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.text_fields_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Text(
            'Metin Tanınıyor...',
            style: widget.theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Google ML Kit ile fişiniz analiz ediliyor',
            style: widget.theme.textTheme.bodyMedium?.copyWith(
              color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular(8),
              minHeight: 4,
              color: widget.theme.colorScheme.primary,
              backgroundColor: widget.theme.colorScheme.primary.withValues(
                alpha: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 4. SONUÇ — OCR Ham Metin Gösterimi
// ═══════════════════════════════════════════════════════════════

class _ReceiptItemRow {
  final TextEditingController nameController;
  final TextEditingController amountController;
  final TextEditingController quantityController;

  _ReceiptItemRow({
    required String name,
    required double amount,
    double quantity = 1.0,
  }) : nameController = TextEditingController(text: name),
       amountController = TextEditingController(
         text: CurrencyFormatter.format(amount),
       ),
       quantityController = TextEditingController(
         text: quantity == quantity.toInt()
             ? quantity.toInt().toString()
             : quantity.toString(),
       );

  void dispose() {
    nameController.dispose();
    amountController.dispose();
    quantityController.dispose();
  }
}

class _ResultView extends StatefulWidget {
  final String rawText;
  final String? imagePath;
  final bool isPdf;
  final String? pdfPath;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onReset;

  const _ResultView({
    super.key,
    required this.rawText,
    required this.imagePath,
    this.isPdf = false,
    this.pdfPath,
    required this.theme,
    required this.isDark,
    required this.onReset,
  });

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late final _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  final List<_ReceiptItemRow> _itemRows = [];
  final _formKey = GlobalKey<FormState>();

  bool _showRawText = false;
  bool _isParsingWithAI = false;

  @override
  void initState() {
    super.initState();
    _parseReceiptData();
    // _parseReceiptData() içinde _selectedDate güncel tarihle doldurulmuş olabilir
    _dateController.text = DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(_selectedDate);
  }

  void _parseReceiptData() {
    if (widget.rawText.isEmpty) return;

    // Yaratılan Parser regex motoru çalıştırarak verileri çıkarır
    final parsed = widget.isPdf 
        ? InvoiceParser.parse(widget.rawText)
        : ReceiptParser.parse(widget.rawText);

    if (parsed.merchantName != null && parsed.merchantName!.isNotEmpty) {
      _titleController.text = parsed.merchantName!;
    } else {
      _titleController.text = 'Fiş Harcaması';
    }

    if (parsed.amount != null) {
      _amountController.text = CurrencyFormatter.format(parsed.amount!);
    }

    if (parsed.date != null) {
      _selectedDate = parsed.date!;
    }

    if (parsed.items != null && parsed.items!.isNotEmpty) {
      for (var item in parsed.items!) {
        _itemRows.add(
          _ReceiptItemRow(
            name: item.name,
            amount: item.amount,
            quantity: item.quantity,
          ),
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoCategorize(parsed.merchantName ?? '');
    });
  }

  Future<void> _parseWithAI() async {
    if (widget.rawText.isEmpty) return;

    setState(() {
      _isParsingWithAI = true;
    });

    try {
      final parsed = await AiParserService.parse(widget.rawText);

      setState(() {
        if (parsed.merchantName != null && parsed.merchantName!.isNotEmpty) {
          _titleController.text = parsed.merchantName!;
        }

        if (parsed.amount != null) {
          _amountController.text = CurrencyFormatter.format(parsed.amount!);
        }

        if (parsed.date != null) {
          _selectedDate = parsed.date!;
          _dateController.text = DateFormat('dd MMM yyyy, HH:mm').format(_selectedDate);
        }

        if (parsed.items != null && parsed.items!.isNotEmpty) {
          // Önceki satırları temizle
          for (var row in _itemRows) {
            row.dispose();
          }
          _itemRows.clear();

          for (var item in parsed.items!) {
            _itemRows.add(
              _ReceiptItemRow(
                name: item.name,
                amount: item.amount,
                quantity: item.quantity,
              ),
            );
          }
        }
        
        _autoCategorize(parsed.merchantName ?? '');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yapay zeka ile başarıyla yeniden ayrıştırıldı!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isParsingWithAI = false;
        });
      }
    }
  }

  void _autoCategorize(String merchantName) {
    if (merchantName.isEmpty) return;
    final catProvider = Provider.of<CategoryProvider>(context, listen: false);
    final expenseCategories = catProvider.categories
        .where((c) => c.type == 'gider')
        .toList();
    if (expenseCategories.isEmpty) return;

    final lowerName = merchantName.toLowerCase();
    int? matchedId;

    if (lowerName.contains('market') ||
        lowerName.contains('migros') ||
        lowerName.contains('bim') ||
        lowerName.contains('a101') ||
        lowerName.contains('şok') ||
        lowerName.contains('carrefour')) {
      matchedId = expenseCategories
          .firstWhere(
            (c) => c.name.toLowerCase().contains('market'),
            orElse: () => expenseCategories.first,
          )
          .id;
    } else if (lowerName.contains('kahve') ||
        lowerName.contains('starbucks') ||
        lowerName.contains('cafe') ||
        lowerName.contains('yemek') ||
        lowerName.contains('burger') ||
        lowerName.contains('kebap')) {
      matchedId = expenseCategories
          .firstWhere(
            (c) =>
                c.name.toLowerCase().contains('yemek') ||
                c.name.toLowerCase().contains('restoran'),
            orElse: () => expenseCategories.first,
          )
          .id;
    } else if (lowerName.contains('petrol') ||
        lowerName.contains('shell') ||
        lowerName.contains('opet') ||
        lowerName.contains('bp') ||
        lowerName.contains('yakıt')) {
      matchedId = expenseCategories
          .firstWhere(
            (c) =>
                c.name.toLowerCase().contains('ulaşım') ||
                c.name.toLowerCase().contains('yakıt'),
            orElse: () => expenseCategories.first,
          )
          .id;
    }

    if (matchedId != null) {
      setState(() => _selectedCategoryId = matchedId);
    } else {
      setState(() => _selectedCategoryId = expenseCategories.first.id);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    for (var row in _itemRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateController.text = DateFormat(
            'dd MMM yyyy, HH:mm',
          ).format(_selectedDate);
        });
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = CurrencyFormatter.parse(_amountController.text);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tutar girin')),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? 'Fiş Harcaması'
        : _titleController.text.trim();

    List<models.TransactionItem>? finalItems;
    if (_itemRows.isNotEmpty) {
      finalItems = [];
      for (var row in _itemRows) {
        final name = row.nameController.text.trim();
        final amount = CurrencyFormatter.parse(row.amountController.text);
        final quantity = double.tryParse(row.quantityController.text) ?? 1.0;
        if (name.isNotEmpty && amount != null && amount > 0) {
          finalItems.add(
            models.TransactionItem(
              name: name,
              amount: amount,
              quantity: quantity,
            ),
          );
        }
      }
      if (finalItems.isEmpty) finalItems = null;
    }

    String? receiptPath;
    // PDF veya resim kaynağını kaydet
    final sourcePath = widget.isPdf ? widget.pdfPath : widget.imagePath;
    if (sourcePath != null && sourcePath.isNotEmpty) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
        final savedFile = await File(
          sourcePath,
        ).copy('${appDir.path}/$fileName');
        receiptPath = savedFile.path;
      } catch (e) {
        // Hata olursa kaynaksız kaydet
        receiptPath = sourcePath;
      }
    }

    final description = widget.isPdf
        ? 'PDF fatura ile eklendi.\n---\n${widget.rawText}'
        : 'Fiş tarama (OCR) ile eklendi.\n---\n${widget.rawText}';

    final tx = models.Transaction(
      title: title,
      amount: parsed,
      type: 'gider',
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      description: description,
      items: finalItems,
      receiptId: receiptPath,
    );

    if (!mounted) return;

    Provider.of<TransactionProvider>(context, listen: false).addTransaction(tx);

    widget.onReset();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isPdf ? 'PDF fatura başarıyla kaydedildi ✓' : 'Fiş başarıyla kaydedildi ✓'),
        backgroundColor: Colors.green,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = widget.rawText.isEmpty;
    final catProvider = Provider.of<CategoryProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEmpty
                      ? Colors.orange.withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEmpty
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_rounded,
                  color: isEmpty ? Colors.orange : const Color(0xFF10B981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEmpty
                          ? 'Metin Bulunamadı'
                          : widget.isPdf
                              ? 'PDF Başarıyla Okundu'
                              : 'Tarama Tamamlandı',
                      style: widget.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEmpty
                          ? widget.isPdf
                              ? 'PDF belgede okunabilir metin tespit edilemedi'
                              : 'Fişte okunabilir metin tespit edilemedi'
                          : 'Bilgileri doğrulayıp kaydedin',
                      style: widget.theme.textTheme.bodySmall?.copyWith(
                        color: widget.theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isEmpty)
                IconButton(
                  icon: Icon(
                    _showRawText ? Icons.edit_document : Icons.text_snippet,
                    color: widget.theme.colorScheme.primary,
                  ),
                  tooltip: _showRawText ? 'Formu Göster' : 'Ham Metni Göster',
                  onPressed: () {
                    setState(() {
                      _showRawText = !_showRawText;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: widget.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.text_rotation_none,
                            size: 48,
                            color: widget.theme.colorScheme.onSurface
                                .withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Metin tespit edilemedi.\\nFarklı bir açıdan tekrar deneyin.',
                            textAlign: TextAlign.center,
                            style: widget.theme.textTheme.bodyMedium?.copyWith(
                              color: widget.theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _showRawText
                  ? _buildRawTextView()
                  : _buildFormView(catProvider.categories),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Yeniden Tara'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: widget.theme.colorScheme.primary.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isEmpty && !_showRawText) const SizedBox(width: 12),
              if (!isEmpty && !_showRawText)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveTransaction,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Kaydet'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRawTextView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ham OCR Çıktısı',
              style: widget.theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.theme.colorScheme.primary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Kopyala',
              onPressed: () {
                final data = ClipboardData(text: widget.rawText);
                Clipboard.setData(data).then((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Panoya kopyalandı')),
                    );
                  }
                });
              },
            ),
          ],
        ),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: SelectableText(
              widget.rawText,
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView(List<model_cat.Category> allCategories) {
    final expenseCategories = allCategories
        .where((c) => c.type == 'gider')
        .toList();

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isParsingWithAI)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _parseWithAI,
                  icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                  label: const Text('Yapay Zeka ile Yeniden Ayrıştır'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.theme.colorScheme.primary,
                    side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                    backgroundColor: Colors.amber.withValues(alpha: 0.05),
                  ),
                ),
              ),
            if (_isParsingWithAI)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Yapay zeka analiz ediyor...',
                      style: TextStyle(color: widget.theme.colorScheme.primary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Icon(
                  Icons.edit_document,
                  size: 18,
                  color: widget.theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fiş Bilgileri',
                  style: widget.theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Başlık boş olamaz'
                  : null,
              decoration: const InputDecoration(
                labelText: 'İşletme / Başlık',
                prefixIcon: Icon(Icons.storefront_rounded),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              // Sadece görsel check için validator ekledik
              decoration: const InputDecoration(
                labelText: 'Genel Toplam',
                prefixIcon: Icon(Icons.payments_rounded),
                border: OutlineInputBorder(),
                suffixText: '₺',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: ValueKey(_selectedCategoryId),
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category_rounded),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: expenseCategories.map((c) {
                return DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(c.name, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              validator: (val) =>
                  val == null ? 'Lütfen bir kategori seçin' : null,
              onChanged: (val) {
                setState(() {
                  _selectedCategoryId = val;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              onTap: _pickDate,
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'İşlem Tarihi ve Saati',
                prefixIcon: const Icon(Icons.calendar_today_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.edit_calendar_rounded,
                    color: widget.theme.colorScheme.primary,
                  ),
                  tooltip: 'Tarih ve saati düzenle',
                  onPressed: _pickDate,
                ),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                helperText: 'Dokunarak tarih ve saati düzenleyebilirsiniz',
                helperStyle: TextStyle(
                  fontSize: 11,
                  color: widget.theme.colorScheme.primary.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_itemRows.isNotEmpty) ...[
              _buildDetailedItemsSection(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedItemsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Okunan Ürün Kalemleri',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Kolon Başlıkları
          if (_itemRows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 6.0,
                left: 4.0,
                right: 36.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Text(
                      'Ürün Adı',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Ad./Kg',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Brm. ₺',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Tutar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ..._itemRows.asMap().entries.map((entry) {
            int index = entry.key;
            var row = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      controller: row.nameController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Satır Adı',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: row.quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (val) {
                        setState(() {}); // Birim fiyatın hesaplanması için
                      },
                      decoration: const InputDecoration(
                        hintText: 'Adet',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 3,
                    child: Builder(
                      builder: (context) {
                        double q =
                            double.tryParse(row.quantityController.text) ?? 1.0;
                        double a =
                            CurrencyFormatter.parse(
                              row.amountController.text,
                            ) ??
                            0.0;
                        String uPrice = (q > 0)
                            ? CurrencyFormatter.format(a / q)
                            : '0,00';
                        return TextFormField(
                          controller: TextEditingController(text: uPrice),
                          readOnly: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: widget
                                .theme
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 12,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          style: TextStyle(
                            color: widget.theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: row.amountController,
                      style: const TextStyle(fontSize: 13),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [CurrencyInputFormatter()],
                      onChanged: (val) {
                        double sum = 0;
                        for (var r in _itemRows) {
                          sum +=
                              (CurrencyFormatter.parse(
                                r.amountController.text,
                              ) ??
                              0);
                        }
                        setState(() {
                          _amountController.text = CurrencyFormatter.format(
                            sum,
                          );
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Tutar',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: EdgeInsets.zero,
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'Satırı Sil',
                      onPressed: () {
                        setState(() {
                          row.dispose();
                          _itemRows.removeAt(index);
                          double sum = 0;
                          for (var r in _itemRows) {
                            sum +=
                                (CurrencyFormatter.parse(
                                  r.amountController.text,
                                ) ??
                                0);
                          }
                          if (_itemRows.isNotEmpty) {
                            _amountController.text = CurrencyFormatter.format(
                              sum,
                            );
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 5. HATA DURUMU
// ═══════════════════════════════════════════════════════════════
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final ThemeData theme;
  final bool isDark;

  const _ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bir Hata Oluştu',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ORTAK WIDGET'LAR
// ═══════════════════════════════════════════════════════════════

/// Kamera/Galeri için eylem butonu
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : color.withValues(alpha: 0.15),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glassmorphism efektli buton
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
