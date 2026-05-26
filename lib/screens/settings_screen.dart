import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_overlay.dart';
import '../models/transaction.dart' as models;
import '../utils/currency_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return LoadingOverlay(
      isLoading: authProvider.loadingState == AuthLoadingState.signingOut,
      message: 'Çıkış Yapılıyor...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'AYARLAR',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            _buildProfileCard(context, theme),
            _buildAppearanceCard(context, theme),
            _buildFinancialCard(context, theme),
            _buildManagementCard(context, theme),
            _buildAboutCard(context, theme),
            const SizedBox(height: 40), // Alt boşluk
          ],
        ),
      ),
    );
  }

  // Ortak Kart Yapısı
  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.blue.shade900.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1.2,
                color: isDark
                    ? theme.colorScheme.primary
                    : const Color(0xFF1E3A8A), // Koyu mavi andıran başlık
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, ThemeData theme) {
    return Consumer2<SettingsProvider, AuthProvider>(
      builder: (context, settings, authProvider, child) {
        final user = authProvider.user;

        // Kullanıcı bilgileri (Supabase'den, yoksa yerel ayarlardan alıyoruz)
        final userName = user != null 
            ? authProvider.displayName 
            : (settings.userName.isNotEmpty ? settings.userName : 'Misafir Kullanıcı');
        
        final userEmail = user != null 
            ? (user.email ?? '') 
            : (settings.userEmail.isNotEmpty ? settings.userEmail : 'Giriş yapılmadı');
        
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
        
        // Profil resmi belirleme
        ImageProvider? avatarImage;
        if (user != null && authProvider.avatarUrl != null) {
          avatarImage = NetworkImage(authProvider.avatarUrl!);
        } else if (settings.userPhotoPath.isNotEmpty) {
          avatarImage = FileImage(File(settings.userPhotoPath));
        }

        return _buildSettingsCard(
          title: 'PROFİL VE HESAP',
          theme: theme,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profil Resmi / Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: theme.colorScheme.primary,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 18),
                
                // İsim ve Detaylar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Giriş yöntemi etiketi (Google veya E-posta)
                      if (user != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: authProvider.loginMethod == 'Google'
                                ? Colors.red.withValues(alpha: 0.08)
                                : theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: authProvider.loginMethod == 'Google'
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : theme.colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                authProvider.loginMethod == 'Google'
                                    ? Icons.g_mobiledata
                                    : Icons.email_outlined,
                                size: authProvider.loginMethod == 'Google' ? 20 : 14,
                                color: authProvider.loginMethod == 'Google'
                                    ? Colors.red
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${authProvider.loginMethod} ile giriş yapıldı',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: authProvider.loginMethod == 'Google'
                                      ? Colors.red
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            
            // Profili Düzenle & Güvenlik Butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/profile'),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Profili Düzenle'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSignOutDialog(context, authProvider),
                      icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.red),
                      label: const Text(
                        'Çıkış Yap',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                        backgroundColor: Colors.red.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  // Çıkış yap onay dialogu
  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Oturumu Kapat'),
          ],
        ),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz? Yerel verileriniz telefonunuzda saklanmaya devam edecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authProvider.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Başarıyla çıkış yapıldı.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(BuildContext context, ThemeData theme) {
    return Consumer2<SettingsProvider, TransactionProvider>(
      builder: (context, settings, provider, child) {
        final hasIncome = settings.monthlyIncome > 0;
        return _buildSettingsCard(
          title: 'FİNANSAL AYARLAR',
          theme: theme,
          children: [
            _buildListItem(
              icon: settings.hasRecurringIncome
                  ? Icons.repeat
                  : Icons.account_balance_wallet_outlined,
              title: 'Aylık Gelir',
              subtitle: hasIncome
                  ? settings.hasRecurringIncome
                      ? '₺${CurrencyFormatter.format(settings.monthlyIncome)} · Her ayın ${settings.incomeDay}. günü'
                      : '₺${CurrencyFormatter.format(settings.monthlyIncome)}'
                  : 'Tanımlanmadı · Otomatik tekrar için ayarlayın',
              theme: theme,
              onTap: () => _showMonthlyIncomeDialog(context, settings),
            ),
            const Divider(height: 1),
            _buildListItem(
              icon: Icons.pie_chart_outline,
              title: 'Bütçe Limiti',
              subtitle: '₺${CurrencyFormatter.format(provider.budgetLimit)}',
              theme: theme,
              onTap: () => _showBudgetLimitDialog(context, provider),
              showDivider: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagementCard(BuildContext context, ThemeData theme) {
    return _buildSettingsCard(
      title: 'YÖNETİM',
      theme: theme,
      children: [
        _buildListItem(
          icon: Icons.category_outlined,
          title: 'Kategori Yönetimi',
          theme: theme,
          onTap: () => context.push('/category_management'),
        ),
        const Divider(height: 1),
        _buildListItem(
          icon: Icons.cloud_outlined,
          title: 'Veri Yedekleme',
          theme: theme,
          onTap: () => context.push('/backup_settings'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildAppearanceCard(BuildContext context, ThemeData theme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return _buildSettingsCard(
          title: 'GÖRÜNÜM',
          theme: theme,
          children: [
            Row(
              children: [
                Icon(
                  Icons.brightness_6,
                  size: 22,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Uygulama Teması',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Sistem', style: TextStyle(fontSize: 12)),
                    icon: Icon(Icons.phone_android, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Aydınlık', style: TextStyle(fontSize: 12)),
                    icon: Icon(Icons.light_mode, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Karanlık', style: TextStyle(fontSize: 12)),
                    icon: Icon(Icons.dark_mode, size: 16),
                  ),
                ],
                selected: {themeProvider.themeMode},
                onSelectionChanged: (value) {
                  themeProvider.setTheme(value.first);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutCard(BuildContext context, ThemeData theme) {
    return _buildSettingsCard(
      title: 'DESTEK & HAKKINDA',
      theme: theme,
      children: [
        _buildListItem(
          icon: Icons.info_outline,
          title: 'Uygulama Sürümü',
          theme: theme,
          trailing: Text(
            'v1.0.0',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Divider(height: 1),
        _buildListItem(
          icon: Icons.help_outline,
          title: 'Yardım Merkezi',
          theme: theme,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yardım merkezi yakında eklenecek')),
            );
          },
        ),
        const Divider(height: 1),
        _buildListItem(
          icon: Icons.chat_bubble_outline,
          title: 'Lisanslar',
          theme: theme,
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'Finans Asistanı',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 Furkan OĞUZGÖKSU',
            );
          },
        ),
        const Divider(height: 1),
        _buildListItem(
          icon: Icons.person_outline,
          title: 'Geliştirici',
          subtitle: 'Furkan OĞUZGÖKSU',
          theme: theme,
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () async {
            final url = Uri.parse('https://github.com/FurkanOguzgoksu');
            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bağlantı açılamadı')),
                );
              }
            }
          },
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required ThemeData theme,
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null && onTap != null)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }

  /// Aylık Gelir Dialog
  void _showMonthlyIncomeDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _MonthlyIncomeDialog(settings: settings),
    );
  }

  /// Bütçe Limiti Dialog
  void _showBudgetLimitDialog(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final controller = TextEditingController(
      text: CurrencyFormatter.format(provider.budgetLimit),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bütçe Limitini Ayarla'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Aylık Limit (₺)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_balance),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newLimit = CurrencyFormatter.parse(controller.text);
              if (newLimit != null && newLimit > 0) {
                provider.setBudgetLimit(newLimit);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bütçe limiti güncellendi')),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Aylık Gelir Dialog — Tarih/Saat seçimi + direkt işlem ekleme
// ──────────────────────────────────────────────────────────────────────────────
class _MonthlyIncomeDialog extends StatefulWidget {
  final SettingsProvider settings;
  const _MonthlyIncomeDialog({required this.settings});

  @override
  State<_MonthlyIncomeDialog> createState() => _MonthlyIncomeDialogState();
}

class _MonthlyIncomeDialogState extends State<_MonthlyIncomeDialog> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  bool _addAsTransaction = true;

  @override
  void initState() {
    super.initState();
    if (widget.settings.monthlyIncome > 0) {
      _amountController.text = CurrencyFormatter.format(
        widget.settings.monthlyIncome,
      );
    }
    _titleController.text = 'Aylık Maaş';

    // Kategorileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (catProvider.categories.isEmpty) {
        catProvider.loadCategories().then((_) => _preselectIncomeCategory());
      } else {
        _preselectIncomeCategory();
      }
    });
  }

  void _preselectIncomeCategory() {
    final catProvider = Provider.of<CategoryProvider>(context, listen: false);
    final incomeCategories = catProvider.categories
        .where((c) => c.type == 'gelir')
        .toList();
    if (incomeCategories.isEmpty) return;

    // "Maaş" veya "maaş" içeren kategoriyi bul, yoksa ilkini seç
    final maas = incomeCategories.firstWhere(
      (c) =>
          c.name.toLowerCase().contains('maaş') ||
          c.name.toLowerCase().contains('maas') ||
          c.name.toLowerCase().contains('salary'),
      orElse: () => incomeCategories.first,
    );
    setState(() => _selectedCategoryId = maas.id);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (!mounted) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _selectedDate.hour,
        pickedTime?.minute ?? _selectedDate.minute,
      );
    });
  }

  void _save() {
    final parsed = CurrencyFormatter.parse(_amountController.text);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçerli bir tutar girin')));
      return;
    }

    final categoryId = _selectedCategoryId;
    if (_addAsTransaction && categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçin')),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? 'Aylık Maaş'
        : _titleController.text.trim();

    // 1. Tekrarlayan gelir konfigürasyonunu kaydet (tutar + gün + kategori + başlık)
    if (categoryId != null) {
      widget.settings.setRecurringIncomeConfig(
        amount: parsed,
        day: _selectedDate.day, // seçilen tarihin günü → her ay bu günde eklenecek
        categoryId: categoryId,
        title: title,
      );
    } else {
      widget.settings.setMonthlyIncome(parsed);
    }

    // 2. Şu anki tarih için işlem olarak da ekle (istenirse)
    if (_addAsTransaction && categoryId != null) {
      final tx = models.Transaction(
        title: title,
        amount: parsed,
        type: 'gelir',
        categoryId: categoryId,
        date: _selectedDate,
        description: 'Aylık gelir — her ayın ${_selectedDate.day}. günü otomatik eklenir',
      );
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).addTransaction(tx);
    }

    Navigator.of(context).pop();

    final dayLabel = _selectedDate.day;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.repeat, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _addAsTransaction
                    ? 'Aylık gelir kaydedildi ve işlem eklendi ✓ (Her ayın $dayLabel. günü otomatik eklenecek)'
                    : 'Aylık gelir kaydedildi ✓ (Her ayın $dayLabel. günü otomatik eklenecek)',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = Provider.of<CategoryProvider>(context).categories;
    final incomeCategories = categories
        .where((c) => c.type == 'gelir')
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Aylık Gelir',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Açıklama
            Text(
              'Aylık net gelirinizi girin. Tutar bütçe ve tasarruf hesaplamalarında kullanılır.',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),

            // Kategori (sadece işlem eklenecekse)
            if (_addAsTransaction) ...[
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                hint: const Text('Kategori seçin'),
                items: incomeCategories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
            ],

            const SizedBox(height: 14),

            // İşlem Başlığı
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'İşlem Başlığı',
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // Tutar
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Tutar (₺)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 14),

            // Tarih & Saat Seçimi
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarih & Saat',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat(
                            'dd MMMM yyyy, HH:mm',
                            'tr_TR',
                          ).format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // İşlem Eklensin mi toggle
            SwitchListTile(
              value: _addAsTransaction,
              onChanged: (v) => setState(() => _addAsTransaction = v),
              title: const Text(
                'İşlem olarak da ekle',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _addAsTransaction
                    ? 'Gelir listesine de kaydedilecek'
                    : 'Sadece aylık gelir ayarı güncellenir',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: theme.colorScheme.primary,
            ),

            const SizedBox(height: 24),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Kaydet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
