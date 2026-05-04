// File: lib/main_mobile_siswa.dart
// ===========================================
// ENTRY POINT - Mobile (Siswa APK/IPA)
// Professional native mobile app with bottom nav
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/config/supabase_config.dart';
import 'core/models/user.dart';
import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/screens/mobile_login_page.dart';
import 'features/auth/screens/forgot_password_page.dart';
import 'features/siswa/screens/mobile/mobile_dashboard.dart';
import 'features/siswa/screens/mobile/mobile_schedule.dart';
import 'features/siswa/screens/mobile/mobile_riwayat_kehadiran.dart';
import 'features/siswa/screens/mobile/mobile_hasil_studi.dart';
import 'features/siswa/screens/mobile/mobile_profile.dart';
import 'features/siswa/screens/mobile/mobile_top_bar.dart';
import 'shared_widgets/not_found_page.dart';
import 'core/providers/theme_provider.dart';

final _mobileRouterProvider = Provider<GoRouter>((ref) {
  String? studentRedirect() {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return '/login';
    if (user.role != UserRole.student) return '/login';
    return null;
  }

  return GoRouter(
    initialLocation: '/login',
    routes: [
      // ── Auth ──
      GoRoute(
        path: '/login',
        name: 'login',
        redirect: (context, state) {
          final user = ref.read(authProvider).valueOrNull;
          return user?.role == UserRole.student ? '/siswa/dashboard' : null;
        },
        builder: (context, state) => const MobileLoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // ── Siswa Routes (BottomNav layout) ──
      ShellRoute(
        redirect: (context, state) => studentRedirect(),
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
                path: 'presensi',
                name: 'siswa-presensi',
                builder: (context, state) => const MobileRiwayatKehadiran(),
              ),
              GoRoute(
                path: 'rapor',
                name: 'siswa-rapor',
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  // Set system UI overlay style for mobile
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
// 4-tab bottom nav: Beranda, Jadwal, Presensi, Rapor
// TopBar header on every page
// ══════════════════════════════════════════════════════
class StudentMobileLayout extends StatelessWidget {
  final Widget child;
  const StudentMobileLayout({super.key, required this.child});

  static const _tabs = [
    (
      path: '/siswa/dashboard',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Beranda',
    ),
    (
      path: '/siswa/jadwal',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Jadwal',
    ),
    (
      path: '/siswa/presensi',
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check_rounded,
      label: 'Presensi',
    ),
    (
      path: '/siswa/rapor',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'Rapor',
    ),
  ];

  int _getSelectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (path == _tabs[i].path || (i > 0 && path.startsWith(_tabs[i].path))) {
        return i;
      }
    }
    // Default to Beranda for /siswa and /siswa/profil
    if (path == '/siswa' || path == '/siswa/' || path == '/siswa/profil') {
      return -1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Top Bar ──
          const MobileTopBar(),

          // ── Page Content ──
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final isSelected = selectedIndex == i;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.path),
                    behavior: HitTestBehavior.opaque,
                    child: _buildNavItem(context, tab, isSelected, isDark),
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
    BuildContext context,
    ({String path, IconData icon, IconData activeIcon, String label}) tab,
    bool isSelected,
    bool isDark,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: isSelected ? 48 : 40,
          height: isSelected ? 32 : 28,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSelected ? tab.activeIcon : tab.icon,
            size: isSelected ? 24 : 22,
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.gray400 : AppColors.gray400),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tab.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.gray500 : AppColors.gray400),
          ),
        ),
      ],
    );
  }
}
