import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/providers/ocr_provider.dart';

/// Fiş Tarama Ekranı — OCR ile fiş/fatura tarama
///
/// Akış: Kamera/Galeri → Önizleme → (İsteğe bağlı) Kırpma → OCR Tarama → Sonuç
class ReceiptScanScreen extends StatelessWidget {
  const ReceiptScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OcrProvider(),
      child: const _ReceiptScanBody(),
    );
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
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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

  const _ProcessingView({
    super.key,
    required this.theme,
    required this.isDark,
  });

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

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
                        color: widget.theme.colorScheme.primary
                            .withValues(alpha: 0.4),
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
              backgroundColor:
                  widget.theme.colorScheme.primary.withValues(alpha: 0.15),
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
class _ResultView extends StatelessWidget {
  final String rawText;
  final String? imagePath;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onReset;

  const _ResultView({
    super.key,
    required this.rawText,
    required this.imagePath,
    required this.theme,
    required this.isDark,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = rawText.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Üst bilgi
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
                      isEmpty ? 'Metin Bulunamadı' : 'Tarama Tamamlandı',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEmpty
                          ? 'Fişte okunabilir metin tespit edilemedi'
                          : 'OCR sonucu aşağıda gösterilmektedir',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Küçük resim önizleme
          if (imagePath != null)
            Container(
              height: 100,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(File(imagePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // OCR Metin kartı
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.text_snippet_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ham OCR Çıktısı',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      if (!isEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Metni Kopyala',
                          onPressed: () {
                            // Panoya kopyala
                            _copyToClipboard(context, rawText);
                          },
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.text_rotation_none,
                                  size: 48,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Metin tespit edilemedi.\nFarklı bir açıdan tekrar deneyin.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: SelectableText(
                              rawText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                height: 1.6,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Alt butonlar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Yeniden Tara'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
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

  void _copyToClipboard(BuildContext context, String text) {
    // Clipboard API
    final data = ClipboardData(text: text);
    Clipboard.setData(data).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Metin panoya kopyalandı'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white,
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
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
