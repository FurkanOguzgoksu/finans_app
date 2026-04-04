import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/currency_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final userName = settings.userName.isNotEmpty
            ? settings.userName
            : 'Misafir Kullanıcı';
        final userEmail = settings.userEmail.isNotEmpty
            ? settings.userEmail
            : 'Giriş yapılmadı';
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
        final hasPhoto = settings.userPhotoPath.isNotEmpty;

        return _buildSettingsCard(
          title: 'PROFİL',
          theme: theme,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  backgroundImage: hasPhoto
                      ? FileImage(File(settings.userPhotoPath))
                      : null,
                  child: !hasPhoto
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () => context.push('/profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Profili Düzenle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildListItem(
              icon: Icons.shield_outlined,
              title: 'Hesap Güvenliği',
              theme: theme,
              trailing: Switch(
                value: true, // Şimdilik görsel amaçlı
                onChanged: (val) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yakında eklenecek')),
                  );
                },
                activeThumbColor: theme.colorScheme.primary,
              ),
            ),
          ],
        );
      },
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
              icon: Icons.account_balance_wallet_outlined,
              title: 'Aylık Gelir',
              subtitle: hasIncome
                  ? '₺${CurrencyFormatter.format(settings.monthlyIncome)}'
                  : 'Tanımlanmadı',
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
              'Aylık net gelirinizi girin. Bu bilgi bütçe ve tasarruf hesaplamalarında kullanılacaktır.',
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
