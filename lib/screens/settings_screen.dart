import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/currency_formatter.dart';

/// Ayarlar Ekranı - Uygulama ayarlarını yönetir
/// Finansal ayarlar, görünüm, kategori yönetimi, yedekleme ve uygulama hakkında
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── 👤 PROFİL ──
          _buildUserProfileSection(context, theme),
          const Divider(height: 16),

          // ── 💰 FİNANSAL AYARLAR ──
          _buildSectionHeader(
            context,
            'Finansal Ayarlar',
            Icons.account_balance_wallet,
          ),
          _buildMonthlyIncomeTile(context),
          _buildBudgetLimitTile(context),
          const Divider(height: 32),

          // ── 🎨 GÖRÜNÜM ──
          _buildSectionHeader(context, 'Görünüm', Icons.palette),
          _buildThemeTile(context, theme),
          const Divider(height: 32),

          // ── 📂 KATEGORİ YÖNETİMİ ──
          _buildSectionHeader(context, 'Kategoriler', Icons.category),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_note, color: theme.colorScheme.primary),
              ),
              title: const Text('Kategori Yönetimi'),
              subtitle: const Text('Gelir ve gider kategorilerini düzenleyin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/category_management'),
            ),
          ),
          const Divider(height: 32),

          // ── 💾 YEDEKLEME ──
          _buildSectionHeader(context, 'Veri Yönetimi', Icons.storage),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.backup, color: theme.colorScheme.primary),
              ),
              title: const Text('Yedekleme Ayarları'),
              subtitle: const Text('JSON veya Supabase ile yedek alın'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/backup_settings'),
            ),
          ),
          const Divider(height: 32),

          // ── ℹ️ UYGULAMA HAKKINDA ──
          _buildSectionHeader(context, 'Uygulama Hakkında', Icons.info_outline),
          _buildAboutSection(context, theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Kullanıcı Profil Bölümü (Gelecekteki Login için hazırlık)
  Widget _buildUserProfileSection(BuildContext context, ThemeData theme) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final userName = settings.userName.isNotEmpty ? settings.userName : 'Misafir Kullanıcı';
        final userEmail = settings.userEmail.isNotEmpty ? settings.userEmail : 'Giriş yapılmadı';
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
        final hasPhoto = settings.userPhotoPath.isNotEmpty;

        return InkWell(
          onTap: () => context.push('/profile'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  backgroundImage: hasPhoto ? FileImage(File(settings.userPhotoPath)) : null,
                  child: !hasPhoto
                      ? Text(
                          initial,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bölüm Başlığı
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Aylık Gelir Tanımlama
  Widget _buildMonthlyIncomeTile(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final hasIncome = settings.monthlyIncome > 0;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.trending_up, color: Colors.green),
            ),
            title: const Text('Aylık Gelir'),
            subtitle: Text(
              hasIncome
                  ? '₺${CurrencyFormatter.format(settings.monthlyIncome)}'
                  : 'Henüz tanımlanmadı',
              style: TextStyle(
                color: hasIncome ? Colors.green : null,
                fontWeight: hasIncome ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMonthlyIncomeDialog(context, settings),
          ),
        );
      },
    );
  }

  /// Bütçe Limiti Ayarlama
  Widget _buildBudgetLimitTile(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance, color: Colors.orange),
            ),
            title: const Text('Aylık Bütçe Limiti'),
            subtitle: Text(
              '₺${CurrencyFormatter.format(provider.budgetLimit)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBudgetLimitDialog(context, provider),
          ),
        );
      },
    );
  }

  /// Tema Seçimi (SegmentedButton)
  Widget _buildThemeTile(BuildContext context, ThemeData theme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.brightness_6,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Uygulama Teması',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
                        label: Text('Sistem'),
                        icon: Icon(Icons.phone_android, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Aydınlık'),
                        icon: Icon(Icons.light_mode, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Karanlık'),
                        icon: Icon(Icons.dark_mode, size: 18),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (value) {
                      themeProvider.setTheme(value.first);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Uygulama Hakkında Bölümü
  Widget _buildAboutSection(BuildContext context, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.app_shortcut, color: theme.colorScheme.primary),
            ),
            title: const Text('Finans Asistanı'),
            subtitle: const Text('Versiyon 1.0.0'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const SizedBox(width: 40),
            title: const Text('Geliştirici'),
            subtitle: const Text('Furkan OĞUZGÖKSU'),
            dense: true,
          ),
          ListTile(
            leading: const SizedBox(width: 40),
            title: const Text('Platform'),
            subtitle: const Text('Flutter & Dart'),
            dense: true,
          ),
          ListTile(
            leading: const SizedBox(width: 40),
            title: const Text('Lisanslar'),
            trailing: const Icon(Icons.chevron_right),
            dense: true,
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Finans Asistanı',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Furkan OĞUZGÖKSU',
              );
            },
          ),
        ],
      ),
    );
  }

  /// Aylık Gelir Dialog
  void _showMonthlyIncomeDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final controller = TextEditingController(
      text: settings.monthlyIncome > 0
          ? CurrencyFormatter.format(settings.monthlyIncome)
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aylık Gelir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aylık net gelirinizi girin. Bu bilgi bütçe ve tasarruf '
              'hesaplamalarında kullanılacaktır.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Aylık Gelir (₺)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = CurrencyFormatter.parse(controller.text);
              if (parsed != null && parsed >= 0) {
                settings.setMonthlyIncome(parsed);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aylık gelir kaydedildi')),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
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
