// File: lib/features/siswa/screens/student_layout.dart
// ===========================================
// STUDENT LAYOUT
// Uses shared CollapsibleSidebar with SidebarController
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared_widgets/collapsed_sidebar.dart';

class StudentLayout extends ConsumerStatefulWidget {
  final Widget child;
  const StudentLayout({super.key, required this.child});

  @override
  ConsumerState<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends ConsumerState<StudentLayout> {
  final SidebarController _sidebarController = SidebarController();
  String _semesterLabel = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _sidebarController.addListener(() => setState(() {}));
    _loadSemester();
  }

  Future<void> _loadSemester() async {
    try {
      final res = await ApiService.getActiveSemester();
      final data = res['data'];
      if (mounted) {
        setState(
          () => _semesterLabel = data != null
              ? 'Aktif: ${data['label']}'
              : 'Tidak ada semester aktif',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _semesterLabel = 'Aktif: -');
    }
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  String _getBreadcrumb(String path) {
    if (path == '/siswa/dashboard' || path == '/siswa') return 'Dashboard';
    if (path == '/siswa/jadwal') return 'Jadwal Pelajaran';
    if (path == '/siswa/absensi-qr') return 'Scan QR Presensi';
    if (path == '/siswa/rapor' || path == '/siswa/hasil-studi') return 'Rapor';
    if (path == '/siswa/presensi' || path == '/siswa/riwayat-kehadiran') {
      return 'Presensi';
    }
    if (path == '/siswa/profil') return 'Profil Pengguna';
    return 'Dashboard';
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final currentRoute = switch (path) {
      '/siswa' || '/siswa/' => '/siswa/dashboard',
      '/siswa/hasil-studi' => '/siswa/rapor',
      '/siswa/riwayat-kehadiran' => '/siswa/presensi',
      _ => path,
    };
    final authUser = ref.watch(authProvider).valueOrNull;
    final userName = authUser?.name ?? 'Siswa';
    final userInitials = userName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          CollapsibleSidebar(
            title: 'Portal Siswa',
            subtitle: 'SMA Negeri 1 Cikalong',
            currentRoute: currentRoute,
            onNavigate: (route) => context.go(route),
            controller: _sidebarController,
            menuItems: [
              SidebarMenuItem(
                icon: Icons.dashboard,
                label: 'Beranda',
                route: '/siswa/dashboard',
              ),
              SidebarMenuItem(
                icon: Icons.calendar_month,
                label: 'Jadwal',
                route: '/siswa/jadwal',
              ),
              SidebarMenuItem(
                icon: Icons.fact_check,
                label: 'Presensi',
                route: '/siswa/presensi',
              ),
              SidebarMenuItem(
                icon: Icons.menu_book,
                label: 'Rapor',
                route: '/siswa/rapor',
              ),
            ],
            bottomMenuItems: [
              SidebarMenuItem(
                icon: Icons.settings,
                label: 'Profil',
                route: '/siswa/profil',
              ),
              SidebarMenuItem(
                icon: Icons.logout,
                label: 'Keluar',
                onTap: _logout,
              ),
            ],
          ),

          Expanded(
            child: Column(
              children: [
                _buildHeader(context, path, userName, userInitials),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String path,
    String userName,
    String userInitials,
  ) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _sidebarController.toggle(),
            icon: AnimatedRotation(
              turns: _sidebarController.isCollapsed ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.menu_open, size: 22),
            ),
            tooltip: _sidebarController.isCollapsed
                ? 'Perluas Sidebar'
                : 'Perkecil Sidebar',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.gray50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 16),

          const Text(
            'Siswa',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.gray400,
            ),
          ),
          Text(
            _getBreadcrumb(path),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _semesterLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),

          GestureDetector(
            onTap: () => context.go('/siswa/profil'),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.foreground,
                      ),
                    ),
                    const Text(
                      'Siswa',
                      style: TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accent, AppColors.accentHover],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Center(
                    child: Text(
                      userInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
