// File: lib/main_mobile_siswa.dart
// ===========================================
// ENTRY POINT - Mobile (Siswa APK/IPA)
// Professional native mobile app with bottom nav
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/screens/mobile_login_page.dart';
import 'features/siswa/screens/mobile/mobile_dashboard.dart';
import 'features/siswa/screens/mobile/mobile_schedule.dart';
import 'features/siswa/screens/mobile/mobile_qr_scanner.dart';
import 'features/siswa/screens/mobile/mobile_hasil_studi.dart';
import 'features/siswa/screens/mobile/mobile_profile.dart';
import 'shared_widgets/not_found_page.dart';
import 'core/providers/theme_provider.dart';

final _mobileRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // ── Auth ──
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const MobileLoginPage(),
      ),

      // ── Siswa Routes (BottomNav layout) ──
      ShellRoute(
        builder: (context, state, child) => StudentMobileLayout(child: child),
        routes: [
          GoRoute(
            path: '/siswa',
            name: 'siswa-home',
            builder: (context, state) => const MobileDashboard(),
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'siswa-dashboard',
                builder: (context, state) => const MobileDashboard(),
              ),
              GoRoute(
                path: 'jadwal',
                name: 'siswa-jadwal',
                builder: (context, state) => const MobileSchedule(),
              ),
              GoRoute(
                path: 'absensi-qr',
                name: 'siswa-qr',
                builder: (context, state) => const MobileQRScanner(),
              ),
              GoRoute(
                path: 'hasil-studi',
                name: 'siswa-hasil',
                builder: (context, state) => const MobileHasilStudi(),
              ),
              GoRoute(
                path: 'profil',
                name: 'siswa-profil',
                builder: (context, state) => const MobileProfile(),
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
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for mobile
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: SiakadMobileSiswa()));
}

class SiakadMobileSiswa extends ConsumerWidget {
  const SiakadMobileSiswa({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_mobileRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'SIAKAD Siswa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

// ══════════════════════════════════════════════════════
// STUDENT MOBILE LAYOUT
// Professional bottom navigation with floating QR button
// ══════════════════════════════════════════════════════
class StudentMobileLayout extends StatelessWidget {
  final Widget child;
  const StudentMobileLayout({super.key, required this.child});

  static const _tabs = [
    (path: '/siswa/dashboard', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Beranda'),
    (path: '/siswa/jadwal', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Jadwal'),
    (path: '/siswa/absensi-qr', icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner, label: 'Scan QR'),
    (path: '/siswa/hasil-studi', icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Nilai'),
    (path: '/siswa/profil', icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profil'),
  ];

  int _getSelectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (path == _tabs[i].path || (i > 0 && path.startsWith(_tabs[i].path))) {
        return i;
      }
    }
    // Default to Beranda for /siswa
    if (path == '/siswa' || path == '/siswa/') return 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(child: child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ?? Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final isSelected = selectedIndex == i;
                final isCenter = i == 2; // QR Scan button

                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.path),
                    behavior: HitTestBehavior.opaque,
                    child: isCenter
                        ? _buildCenterButton(context, isSelected)
                        : _buildNavItem(tab, isSelected),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    ({String path, IconData icon, IconData activeIcon, String label}) tab,
    bool isSelected,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSelected ? tab.activeIcon : tab.icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.gray400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [AppColors.accent, AppColors.accentHover]
                  : [AppColors.primary, const Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppColors.accent : AppColors.primary).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 2),
        Text(
          'Scan QR',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.accent : AppColors.gray500,
          ),
        ),
      ],
    );
  }
}
