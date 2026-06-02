import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String message;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: _AnimatedLoadingContent(message: message),
          ),
      ],
    );
  }
}

class _AnimatedLoadingContent extends StatefulWidget {
  final String message;
  const _AnimatedLoadingContent({required this.message});

  @override
  State<_AnimatedLoadingContent> createState() => _AnimatedLoadingContentState();
}

class _AnimatedLoadingContentState extends State<_AnimatedLoadingContent>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Fade + Scale in animasyonu
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    // Pulse animasyonu (ikon için)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Spin animasyonu (dış halka)
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _spinController.repeat();

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mesaja göre ikon ve renk belirle
    final isSignOut = widget.message.toLowerCase().contains('çıkış');
    final isSignUp = widget.message.toLowerCase().contains('oluştur') ||
        widget.message.toLowerCase().contains('kayıt');
    
    final IconData mainIcon;
    final Color accentColor;
    final String subText;
    
    if (isSignOut) {
      mainIcon = Icons.logout_rounded;
      accentColor = Colors.redAccent;
      subText = 'Oturumunuz kapatılıyor...';
    } else if (isSignUp) {
      mainIcon = Icons.person_add_alt_1_rounded;
      accentColor = Colors.green;
      subText = 'Hesabınız hazırlanıyor...';
    } else {
      mainIcon = Icons.lock_open_rounded;
      accentColor = theme.colorScheme.primary;
      subText = 'Kimlik doğrulanıyor...';
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          color: isDark
              ? Colors.black.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.6),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animasyonlu İkon + Spinner
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Dönen dış halka
                          AnimatedBuilder(
                            animation: _spinController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _spinController.value * 2 * math.pi,
                                child: CustomPaint(
                                  size: const Size(90, 90),
                                  painter: _ArcPainter(
                                    color: accentColor,
                                    strokeWidth: 3.5,
                                  ),
                                ),
                              );
                            },
                          ),
                          // İkinci ters dönen halka
                          AnimatedBuilder(
                            animation: _spinController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: -_spinController.value * 2 * math.pi * 0.7,
                                child: CustomPaint(
                                  size: const Size(72, 72),
                                  painter: _ArcPainter(
                                    color: accentColor.withValues(alpha: 0.3),
                                    strokeWidth: 2.5,
                                    startAngle: math.pi / 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Ortadaki ikon (pulse animasyonlu)
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                mainIcon,
                                size: 28,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Ana mesaj
                    Text(
                      widget.message,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Alt mesaj
                    Text(
                      subText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Animasyonlu nokta göstergesi
                    _AnimatedDots(color: accentColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animasyonlu 3 Nokta ───
class _AnimatedDots extends StatefulWidget {
  final Color color;
  const _AnimatedDots({required this.color});

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * math.sin(progress * math.pi);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.3 + 0.7 * scale),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Arc Painter (Dönen halka) ───
class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double startAngle;

  _ArcPainter({
    required this.color,
    this.strokeWidth = 3.0,
    this.startAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, startAngle, math.pi * 0.8, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      color != oldDelegate.color || startAngle != oldDelegate.startAngle;
}
