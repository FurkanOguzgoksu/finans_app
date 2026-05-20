import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/supabase_service.dart';
import 'package:go_router/go_router.dart';
import 'utils/app_router.dart';
import 'providers/backup_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ocr_provider.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ─── Crash Log Sistemi (Hafta 13) ────────────────────
  // Flutter framework hataları (widget build hataları vs.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 [FLUTTER HATA] ${details.exception}');
    debugPrint('   Konum : ${details.library}');
    debugPrint('   Özet  : ${details.summary}');
  };

  // Dart/async hataları (Future/Stream'den kaçan hatalar)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 [DART HATA] $error');
    debugPrint('   StackTrace: $stack');
    return true; // true => hata yakalandı, uygulama çökmesin
  };
  // ─────────────────────────────────────────────────────

  // Çevre değişkenlerini yükle (Hata olursa yoksay, fallback devam eder)
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    debugPrint('.env dosyası yüklenemedi: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  // Türkçe tarih formatı için locale başlatma
  await initializeDateFormatting('tr_TR');

  // Supabase başlatma
  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => BackupProvider()),
        ChangeNotifierProvider(create: (_) => OcrProvider()),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider()..loadCategories(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..loadTransactions(),
        ),
      ],
      child: FinansApp(showOnboarding: !hasSeenOnboarding),
    ),
  );
}


class FinansApp extends StatefulWidget {
  final bool showOnboarding;
  const FinansApp({super.key, required this.showOnboarding});

  @override
  State<FinansApp> createState() => _FinansAppState();
}

class _FinansAppState extends State<FinansApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(widget.showOnboarding);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    // Sistem temasına göre status bar ikonlarını belirle
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.black,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );

    return MaterialApp.router(
      title: 'Finans Takip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
