import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finans_app/screens/home_screen.dart';
import 'package:finans_app/screens/transactions_screen.dart';
import 'package:finans_app/screens/statistics_screen.dart';
import 'package:finans_app/screens/settings_screen.dart';
import 'package:finans_app/screens/receipt_scan_screen.dart';
import 'package:finans_app/screens/onboarding_screen.dart';
import 'package:finans_app/screens/backup_settings_screen.dart';
import 'package:finans_app/screens/category_management_screen.dart';
import 'package:finans_app/screens/profile_screen.dart';

/// Uygulama navigasyon yapılandırması (go_router)
class AppRouter {
  static GoRouter createRouter(bool showOnboarding) {
    return GoRouter(
      initialLocation: showOnboarding ? '/onboarding' : '/',
      routes: [
        // Tanıtım Ekranı
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

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
        // Kategori Yönetimi (tam ekran)
        GoRoute(
          path: '/category_management',
          name: 'category_management',
          builder: (context, state) => const CategoryManagementScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }
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
