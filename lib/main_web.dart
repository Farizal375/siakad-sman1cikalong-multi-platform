// File: lib/main_web.dart
// ===========================================
// ENTRY POINT - Web Portal
// All routes: Guest, Auth, Admin, Kurikulum, Guru, Siswa
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';

// ── Real screens ──
import 'features/auth/screens/login_page.dart';
import 'features/auth/screens/forgot_password_page.dart';
import 'features/guest/screens/landing_page.dart';
import 'features/admin/screens/dashboard_layout.dart';
import 'features/admin/screens/dashboard_overview.dart';
import 'features/admin/screens/user_management.dart';
import 'features/admin/screens/public_cms.dart';
import 'features/admin/screens/master_data.dart';
import 'features/admin/screens/user_profile.dart';
import 'features/kurikulum/screens/curriculum_layout.dart';
import 'features/kurikulum/screens/curriculum_dashboard.dart';
import 'features/kurikulum/screens/master_mapel.dart';
import 'features/kurikulum/screens/manajemen_rombel.dart';
import 'features/kurikulum/screens/jadwal_pelajaran.dart';
import 'features/kurikulum/screens/curriculum_profile.dart';
import 'features/kurikulum/screens/master_akademik.dart';
import 'features/kurikulum/screens/migrasi_kelas_wizard.dart';
import 'features/guru/screens/teacher_layout.dart';
import 'features/guru/screens/teacher_dashboard.dart';
import 'features/guru/screens/my_classes.dart';
import 'features/guru/screens/class_detail.dart';
import 'features/guru/screens/teacher_profile.dart';
import 'features/guru/screens/homeroom_dashboard.dart';
import 'features/guru/screens/wali_kelas/penentuan_promosi_screen.dart';
import 'features/guru/screens/monitoring_kehadiran.dart';
import 'features/guru/screens/catatan_akademik.dart';
import 'features/guru/screens/cetak_rapor.dart';
import 'features/guru/screens/student_deep_dive.dart';
import 'features/guru/providers/homeroom_provider.dart';
import 'features/siswa/screens/student_layout.dart';
import 'features/siswa/screens/student_dashboard.dart';
import 'features/siswa/screens/student_schedule.dart';
import 'features/siswa/screens/qr_scanner.dart';
import 'features/siswa/screens/hasil_studi.dart';
import 'features/siswa/screens/riwayat_kehadiran.dart';
import 'features/siswa/screens/student_profile.dart';
import 'shared_widgets/not_found_page.dart';
import 'core/providers/auth_provider.dart';
import 'core/models/user.dart';

// Listenable untuk memberitahu GoRouter ketika auth state berubah
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AsyncValue<User?>>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

final _authChangeNotifierProvider = Provider<_AuthChangeNotifier>((ref) {
  return _AuthChangeNotifier(ref);
});

final _routerProvider = Provider<GoRouter>((ref) {
  // ── Role-based redirect helper ──
  // Gunakan ref.watch agar reaktif + jangan redirect saat masih loading
  String? roleRedirect(GoRouterState state, List<UserRole> allowedRoles) {
    final authState = ref.read(authProvider);
    // Jika masih loading (sedang restore session), jangan redirect dulu
    if (authState.isLoading) return null;
    final user = authState.valueOrNull;
    if (user == null) return '/login';
    if (!allowedRoles.contains(user.role)) return '/unauthorized';
    return null;
  }

  final notifier = ref.watch(_authChangeNotifierProvider);

  Widget waliGuard(Widget child) => HomeroomRouteGuard(child: child);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    routes: [
      // ── Guest ──
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/post/:id',
        name: 'public-post',
        builder: (context, state) => PublicContentDetailPage(
          contentId: state.pathParameters['id'] ?? '',
        ),
      ),

      // ── Auth ──
      GoRoute(
        path: '/login',
        name: 'login',
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          // Jika masih loading, jangan redirect (tunggu session terpulihkan)
          if (authState.isLoading) return null;
          final user = authState.valueOrNull;
          return user == null ? null : getDashboardRouteByRole(user.role);
        },
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      GoRoute(
        path: '/unauthorized',
        name: 'unauthorized',
        builder: (context, state) => const UnauthorizedPage(),
      ),

      // ── Admin Routes ──
      ShellRoute(
        redirect: (context, state) => roleRedirect(state, [UserRole.admin]),
        builder: (context, state, child) => DashboardLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'admin-dashboard',
            builder: (context, state) => const DashboardOverview(),
            routes: [
              GoRoute(
                path: 'users',
                name: 'admin-users',
                builder: (context, state) => const UserManagement(),
              ),
              GoRoute(
                path: 'cms',
                name: 'admin-cms',
                builder: (context, state) => const PublicCMS(),
              ),
              GoRoute(
                path: 'master-data',
                name: 'admin-master-data',
                builder: (context, state) => const MasterData(),
              ),
              GoRoute(
                path: 'profile',
                name: 'admin-profile',
                builder: (context, state) => const UserProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Kurikulum Routes ──
      ShellRoute(
        redirect: (context, state) =>
            roleRedirect(state, [UserRole.curriculum]),
        builder: (context, state, child) => CurriculumLayout(child: child),
        routes: [
          GoRoute(
            path: '/curriculum',
            name: 'curriculum-home',
            builder: (context, state) => const CurriculumDashboard(),
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'curriculum-dashboard',
                builder: (context, state) => const CurriculumDashboard(),
              ),
              GoRoute(
                path: 'master-mapel',
                name: 'curriculum-mapel',
                builder: (context, state) => const MasterMapel(),
              ),
              GoRoute(
                path: 'manajemen-rombel',
                name: 'curriculum-rombel',
                builder: (context, state) => const ManajemenRombel(),
              ),
              GoRoute(
                path: 'master-akademik',
                name: 'curriculum-akademik',
                builder: (context, state) => const MasterAkademik(),
              ),
              GoRoute(
                path: 'jadwal-pelajaran',
                name: 'curriculum-jadwal',
                builder: (context, state) => const JadwalPelajaran(),
              ),
              GoRoute(
                path: 'profile',
                name: 'curriculum-profile',
                builder: (context, state) => const CurriculumProfile(),
              ),
              GoRoute(
                path: 'migrasi-kelas',
                name: 'curriculum-migrasi',
                builder: (context, state) => const MigrasiKelasWizard(),
              ),
            ],
          ),
        ],
      ),

      // ── Guru & Wali Kelas Routes ──
      ShellRoute(
        redirect: (context, state) => roleRedirect(state, [UserRole.teacher]),
        builder: (context, state, child) => TeacherLayout(child: child),
        routes: [
          GoRoute(
            path: '/guru',
            name: 'guru-home',
            builder: (context, state) => const TeacherDashboard(),
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'guru-dashboard',
                builder: (context, state) => const TeacherDashboard(),
              ),
              GoRoute(
                path: 'profile',
                name: 'guru-profile',
                builder: (context, state) => const TeacherProfile(),
              ),
              GoRoute(
                path: 'kelas',
                name: 'guru-kelas',
                builder: (context, state) => const MyClasses(),
              ),
              GoRoute(
                path: 'kelas/:classId',
                name: 'guru-kelas-detail',
                builder: (context, state) =>
                    ClassDetail(classId: state.pathParameters['classId'] ?? ''),
              ),
              GoRoute(
                path: 'kelas-wali',
                name: 'guru-homeroom',
                builder: (context, state) =>
                    waliGuard(const HomeroomDashboard()),
              ),
              GoRoute(
                path: 'homeroom',
                name: 'guru-homeroom-alt',
                builder: (context, state) =>
                    waliGuard(const HomeroomDashboard()),
              ),
              GoRoute(
                path: 'monitoring-kehadiran',
                name: 'guru-kehadiran',
                builder: (context, state) =>
                    waliGuard(const MonitoringKehadiran()),
              ),
              GoRoute(
                path: 'catatan-akademik',
                name: 'guru-catatan',
                builder: (context, state) => waliGuard(const CatatanAkademik()),
              ),
              GoRoute(
                path: 'cetak-rapor',
                name: 'guru-rapor',
                builder: (context, state) => waliGuard(const CetakRapor()),
              ),
              GoRoute(
                path: 'penentuan-promosi',
                name: 'guru-promosi',
                builder: (context, state) =>
                    waliGuard(const PenentuanPromosiScreen()),
              ),
              GoRoute(
                path: 'rapor-detail/:studentId',
                name: 'guru-rapor-detail',
                builder: (context, state) => waliGuard(
                  StudentDeepDive(studentId: state.pathParameters['studentId']),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Siswa Routes ──
      ShellRoute(
        redirect: (context, state) => roleRedirect(state, [UserRole.student]),
        builder: (context, state, child) => StudentLayout(child: child),
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
                path: 'jadwal',
                name: 'siswa-jadwal',
                builder: (context, state) => const StudentSchedule(),
              ),
              GoRoute(
                path: 'presensi',
                name: 'siswa-presensi',
                builder: (context, state) => const RiwayatKehadiran(),
              ),
              GoRoute(
                path: 'rapor',
                name: 'siswa-rapor',
                builder: (context, state) => const HasilStudi(),
              ),
              GoRoute(
                path: 'absensi-qr',
                name: 'siswa-qr',
                builder: (context, state) => const QRScanner(),
              ),
              GoRoute(
                path: 'hasil-studi',
                name: 'siswa-hasil-legacy',
                builder: (context, state) => const HasilStudi(),
              ),
              GoRoute(
                path: 'riwayat-kehadiran',
                name: 'siswa-kehadiran-legacy',
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

    // ── 404 ──
    errorBuilder: (context, state) => const NotFoundPage(),
  );
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const ProviderScope(child: SiakadWebApp()));
}

class UnauthorizedPage extends ConsumerWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Akses tidak diizinkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Akun Anda tidak memiliki izin untuk membuka halaman ini.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    if (user == null) {
                      context.go('/login');
                    } else {
                      context.go(getDashboardRouteByRole(user.role));
                    }
                  },
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
    );
  }
}
