import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'utils/app_router.dart';
import 'providers/backup_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase projesi bağlandığında bu yorum kaldırılacak:
  // try {
  //   await Firebase.initializeApp();
  // } catch (e) {
  //   print('Firebase Error: $e');
  // }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BackupProvider()),
        // Diğer provider'lar buraya eklenecek
      ],
      child: const FinansApp(),
    ),
  );
}

class FinansApp extends StatelessWidget {
  const FinansApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Finans Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), 
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Açık mod arka planı
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), 
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212), // Koyu mod arka planı (neredeyse siyah)
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
