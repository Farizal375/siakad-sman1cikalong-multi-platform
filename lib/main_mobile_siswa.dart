// File: lib/main_mobile_siswa.dart
// ===========================================
// ENTRY POINT - Mobile (Siswa APK/IPA)
// Only Auth + Siswa routes
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'shared_widgets/not_found_page.dart';

final _mobileRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // ── Auth ──
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Login Siswa'),
      ),

      // ── Siswa Routes (uses BottomNav layout on mobile) ──
      ShellRoute(
        builder: (context, state, child) =>
            _PlaceholderMobileLayout(child: child),
        routes: [
          GoRoute(
            path: '/siswa',
            name: 'siswa-home',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Dashboard Siswa'),
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'siswa-dashboard',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Dashboard Siswa'),
              ),
              GoRoute(
                path: 'absensi-qr',
                name: 'siswa-qr',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Scan QR Absensi'),
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
                    const _PlaceholderScreen(title: 'Profil Siswa'),
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

// ── Temporary Placeholders ──

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Will be implemented in Phase 8',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderMobileLayout extends StatelessWidget {
  final Widget child;
  const _PlaceholderMobileLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Absensi'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Nilai'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Kehadiran'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
        selectedIndex: 0,
      ),
    );
  }
}
