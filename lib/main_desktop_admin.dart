// File: lib/main_desktop_admin.dart
// ===========================================
// ENTRY POINT - Desktop (.exe for Admin/Kurikulum)
// Auth + Admin + Kurikulum routes only
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'shared_widgets/not_found_page.dart';

final _desktopRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // ── Auth ──
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Login Admin'),
      ),

      // ── Admin Routes ──
      ShellRoute(
        builder: (context, state, child) =>
            _PlaceholderDesktopLayout(title: 'Panel Admin', child: child),
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
            _PlaceholderDesktopLayout(
                title: 'Panel Kurikulum', child: child),
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
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
});

void main() {
  runApp(
    const ProviderScope(child: SiakadDesktopAdmin()),
  );
}

class SiakadDesktopAdmin extends ConsumerWidget {
  const SiakadDesktopAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_desktopRouterProvider);

    return MaterialApp.router(
      title: 'SIAKAD Admin Desktop',
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
            'Will be implemented in Phase 5–6',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderDesktopLayout extends StatelessWidget {
  final String title;
  final Widget child;
  const _PlaceholderDesktopLayout({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Temporary sidebar placeholder
          Container(
            width: 280,
            color: const Color(0xFF1E3A8A),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
