// File: lib/main_mobile_siswa.dart
// ===========================================
// ENTRY POINT - Mobile (Siswa APK/IPA)
// Only Auth + Siswa routes with functional BottomNav
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/screens/login_page.dart';
import 'features/siswa/screens/student_dashboard.dart';
import 'features/siswa/screens/qr_scanner.dart';
import 'features/siswa/screens/hasil_studi.dart';
import 'features/siswa/screens/riwayat_kehadiran.dart';
import 'features/siswa/screens/student_profile.dart';
import 'shared_widgets/not_found_page.dart';

final _mobileRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // ── Auth ──
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ── Siswa Routes (BottomNav layout) ──
      ShellRoute(
        builder: (context, state, child) => StudentMobileLayout(child: child),
        routes: [
          GoRoute(
            path: '/siswa',
            name: 'siswa-home',
            builder: (context, state) => const StudentDashboard(),
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'siswa-dashboard',
                builder: (context, state) => const StudentDashboard(),
              ),
              GoRoute(
                path: 'absensi-qr',
                name: 'siswa-qr',
                builder: (context, state) => const QRScanner(),
              ),
              GoRoute(
                path: 'hasil-studi',
                name: 'siswa-hasil',
                builder: (context, state) => const HasilStudi(),
              ),
              GoRoute(
                path: 'riwayat-kehadiran',
                name: 'siswa-kehadiran',
                builder: (context, state) => const RiwayatKehadiran(),
              ),
              GoRoute(
                path: 'profil',
                name: 'siswa-profil',
                builder: (context, state) => const StudentProfile(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
});

void main() {
  runApp(
    const ProviderScope(child: SiakadMobileSiswa()),
  );
}

class SiakadMobileSiswa extends ConsumerWidget {
  const SiakadMobileSiswa({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_mobileRouterProvider);

    return MaterialApp.router(
      title: 'SIAKAD Siswa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

// ══════════════════════════════════════════════════════
// STUDENT MOBILE LAYOUT
// Functional BottomNavigationBar with 5 tabs
// ══════════════════════════════════════════════════════
class StudentMobileLayout extends StatelessWidget {
  final Widget child;
  const StudentMobileLayout({super.key, required this.child});

  static const _tabs = [
    (path: '/siswa/dashboard', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
    (path: '/siswa/absensi-qr', icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner, label: 'Absensi'),
    (path: '/siswa/hasil-studi', icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Nilai'),
    (path: '/siswa/riwayat-kehadiran', icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Kehadiran'),
    (path: '/siswa/profil', icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
  ];

  int _getSelectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (path == _tabs[i].path || path.startsWith(_tabs[i].path)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text('SIAKAD Siswa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        elevation: 0,
        shadowColor: Colors.transparent,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs.map((tab) => NavigationDestination(
          icon: Icon(tab.icon, color: AppColors.gray500),
          selectedIcon: Icon(tab.activeIcon, color: AppColors.accent),
          label: tab.label,
        )).toList(),
      ),
    );
  }
}
