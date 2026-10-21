import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isLocked = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // İlk açılışta kilitli mi diye kontrol et. Ayarlar senkron yüklendiği için
    // değer burada doğrudur; kilit ilk frame'den itibaren içeriği gizler.
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.appLockEnabled) {
      _isLocked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime? _lastPausedTime;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lastPausedTime ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      
      if (settings.appLockEnabled && !_isLocked && _lastPausedTime != null) {
        final difference = DateTime.now().difference(_lastPausedTime!);
        if (difference.inMinutes >= 2) { // 2 dakika sınırı
          setState(() {
            _isLocked = true;
          });
        }
      }
      
      // Süreyi sıfırla
      _lastPausedTime = null;

      if (settings.appLockEnabled && _isLocked && !_isAuthenticating) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Uygulamaya erişmek için kimliğinizi doğrulayın',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric Error: $e');
      // Eğer cihazda güvenlik ayarlanmamışsa vb. durumu atlayabiliriz
      // Ancak güvenlik açısından genelde kullanıcıyı kilitli tutmak 
      // veya hata göstermek gerekir.
    }

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
      if (authenticated) {
        _isLocked = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLocked)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Uygulama Kilitli',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Devam etmek için kimliğinizi doğrulayın',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint, size: 28),
                    label: const Text('Kilidi Aç'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
