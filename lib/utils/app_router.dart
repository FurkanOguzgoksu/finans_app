import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/receipt_scan_screen.dart';
import '../screens/backup_settings_screen.dart';

/// Uygulama navigasyon yapılandırması (go_router)
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Ana sayfa - Shell Route ile bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Ana Sayfa
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // İşlemler
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                name: 'transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          // İstatistikler
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                name: 'statistics',
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          // Ayarlar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Fiş Tarama Ekranı (tam ekran)
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const ReceiptScanScreen(),
      ),
      // Yedekleme Ayarları (tam ekran)
      GoRoute(
        path: '/backup_settings',
        name: 'backup_settings',
        builder: (context, state) => const BackupSettingsScreen(),
      ),
    ],
  );
}

/// Bottom Navigation Bar içeren ana scaffold
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'İşlemler',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'İstatistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
