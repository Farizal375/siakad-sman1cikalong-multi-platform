// File: lib/main_web.dart
// ===========================================
// ENTRY POINT - Web Portal
// All routes: Guest, Auth, Admin, Kurikulum, Guru, Siswa
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';

// ── Real screens ──
import 'features/auth/screens/login_page.dart';
import 'features/guest/screens/landing_page.dart';
import 'shared_widgets/not_found_page.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ── Guest ──
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const LandingPage(),
      ),

      // ── Auth ──
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ── Admin Routes ──
      ShellRoute(
        builder: (context, state, child) =>
            _PlaceholderLayout(title: 'Admin Panel', child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'admin-dashboard',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Dashboard Overview'),
            routes: [
              GoRoute(
                path: 'users',
                name: 'admin-users',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'User Management'),
              ),
              GoRoute(
                path: 'cms',
                name: 'admin-cms',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Public CMS'),
              ),
              GoRoute(
                path: 'master-data',
                name: 'admin-master-data',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Master Data'),
              ),
              GoRoute(
                path: 'profile',
                name: 'admin-profile',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'User Profile'),
              ),
            ],
          ),
        ],
      ),

      // ── Kurikulum Routes ──
      ShellRoute(
        builder: (context, state, child) =>
            _PlaceholderLayout(title: 'Panel Kurikulum', child: child),
        routes: [
          GoRoute(
            path: '/curriculum',
            name: 'curriculum-home',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Curriculum Dashboard'),
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'curriculum-dashboard',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Curriculum Dashboard'),
              ),
              GoRoute(
                path: 'master-mapel',
                name: 'curriculum-mapel',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Master Mapel'),
              ),
              GoRoute(
                path: 'manajemen-rombel',
                name: 'curriculum-rombel',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Manajemen Rombel'),
              ),
              GoRoute(
                path: 'jadwal-pelajaran',
                name: 'curriculum-jadwal',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Jadwal Pelajaran'),
              ),
              GoRoute(
                path: 'profile',
                name: 'curriculum-profile',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Curriculum Profile'),
              ),
            ],
          ),
        ],
      ),

      // ── Guru & Wali Kelas Routes ──
      ShellRoute(
        builder: (context, state, child) =>
            _PlaceholderLayout(title: 'Panel Guru', child: child),
        routes: [
          GoRoute(
            path: '/guru',
            name: 'guru-home',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Teacher Dashboard'),
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'guru-dashboard',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Teacher Dashboard'),
              ),
              GoRoute(
                path: 'profile',
                name: 'guru-profile',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Teacher Profile'),
              ),
              GoRoute(
                path: 'kelas',
                name: 'guru-kelas',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'My Classes'),
              ),
              GoRoute(
                path: 'kelas/:classId',
                name: 'guru-kelas-detail',
                builder: (context, state) => _PlaceholderScreen(
                    title: 'Class Detail: ${state.pathParameters['classId']}'),
              ),
              GoRoute(
                path: 'kelas-wali',
                name: 'guru-homeroom',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Homeroom Dashboard'),
              ),
              GoRoute(
                path: 'homeroom',
                name: 'guru-homeroom-alt',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Homeroom Dashboard'),
              ),
              GoRoute(
                path: 'monitoring-kehadiran',
                name: 'guru-kehadiran',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Monitoring Kehadiran'),
              ),
              GoRoute(
                path: 'catatan-akademik',
                name: 'guru-catatan',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Catatan Akademik'),
              ),
              GoRoute(
                path: 'cetak-rapor',
                name: 'guru-rapor',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Cetak Rapor'),
              ),
              GoRoute(
                path: 'rapor-detail/:studentId',
                name: 'guru-rapor-detail',
                builder: (context, state) => _PlaceholderScreen(
                    title:
                        'Student Deep Dive: ${state.pathParameters['studentId']}'),
              ),
            ],
          ),
        ],
      ),

      // ── Siswa Routes ──
      ShellRoute(
        builder: (context, state, child) =>
            _PlaceholderLayout(title: 'Portal Siswa', child: child),
        routes: [
          GoRoute(
            path: '/siswa',
            name: 'siswa-home',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Student Dashboard'),
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'siswa-dashboard',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Student Dashboard'),
              ),
              GoRoute(
                path: 'absensi-qr',
                name: 'siswa-qr',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'QR Scanner'),
              ),
              GoRoute(
                path: 'hasil-studi',
                name: 'siswa-hasil',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Hasil Studi'),
              ),
              GoRoute(
                path: 'riwayat-kehadiran',
                name: 'siswa-kehadiran',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Riwayat Kehadiran'),
              ),
              GoRoute(
                path: 'profil',
                name: 'siswa-profil',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Student Profile'),
              ),
            ],
          ),
        ],
      ),
    ],

    // ── 404 ──
    errorBuilder: (context, state) => const NotFoundPage(),
  );
});

void main() {
  runApp(
    const ProviderScope(child: SiakadWebApp()),
  );
}

class SiakadWebApp extends ConsumerWidget {
  const SiakadWebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'SIAKAD - SMA Negeri 1 Cikalong',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

// ── Temporary Placeholder Widgets ──
// These will be replaced by real screens in later phases

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Screen will be implemented in Phase 3–8',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderLayout extends StatelessWidget {
  final String title;
  final Widget child;
  const _PlaceholderLayout({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}
