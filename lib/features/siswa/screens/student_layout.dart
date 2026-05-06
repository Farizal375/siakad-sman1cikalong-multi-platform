// File: lib/features/siswa/screens/student_layout.dart
// ===========================================
// STUDENT LAYOUT — Responsive (mobile + desktop)
// Desktop (≥ 768px): Sidebar + TopBar + Content
// Mobile (< 768px): AppBar + Drawer + BottomNavigationBar
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/active_semester_provider.dart';
import '../../../shared_widgets/collapsed_sidebar.dart';
import '../../../shared_widgets/responsive_helper.dart';

class StudentLayout extends ConsumerStatefulWidget {
  final Widget child;
  const StudentLayout({super.key, required this.child});

  @override
  ConsumerState<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends ConsumerState<StudentLayout> {
  final SidebarController _sidebarController = SidebarController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _sidebarController.addListener(() => setState(() {}));
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
    if (path == '/siswa/profil') return 'Profil';
    return 'Dashboard';
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  // ── BottomNav index berdasarkan path ──
  int _bottomNavIndex(String path) {
    if (path == '/siswa/dashboard' || path == '/siswa') return 0;
    if (path == '/siswa/jadwal') return 1;
    if (path == '/siswa/presensi' || path == '/siswa/riwayat-kehadiran') {
      return 2;
    }
    if (path == '/siswa/rapor' || path == '/siswa/hasil-studi') return 3;
    return 0;
  }

  void _onBottomNavTap(int index, BuildContext context) {
    const routes = [
      '/siswa/dashboard',
      '/siswa/jadwal',
      '/siswa/presensi',
      '/siswa/rapor',
    ];
    context.go(routes[index]);
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
    final mobile = context.isMobile;
    final semesterLabel =
        ref.watch(activeSemesterLabelProvider).valueOrNull ?? 'Memuat...';

    final menuItems = [
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
    ];

    final sidebar = CollapsibleSidebar(
      title: 'Portal Siswa',
      subtitle: 'SMA Negeri 1 Cikalong',
      currentRoute: currentRoute,
      onNavigate: (route) {
        context.go(route);
        if (mobile) Navigator.of(context).pop();
      },
      controller: _sidebarController,
      menuItems: menuItems,
      bottomMenuItems: [
        SidebarMenuItem(
          icon: Icons.settings,
          label: 'Profil',
          route: '/siswa/profil',
        ),
        SidebarMenuItem(icon: Icons.logout, label: 'Keluar', onTap: _logout),
      ],
    );

    if (mobile) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _MobileAppBar(
          title: _getBreadcrumb(path),
          userInitials: userInitials,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onProfileTap: () => context.go('/siswa/profil'),
        ),
        drawer: Drawer(width: 280, child: SafeArea(child: sidebar)),
        body: widget.child,
        bottomNavigationBar: _buildBottomNav(context, path),
      );
    }

    // ── Desktop ──
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          sidebar,
          Expanded(
            child: Column(
              children: [
                _buildHeader(
                  context,
                  path,
                  userName,
                  userInitials,
                  semesterLabel,
                ),
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

  // ── Mobile Bottom Navigation Bar ──
  Widget _buildBottomNav(BuildContext context, String path) {
    final idx = _bottomNavIndex(path);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        height: 64,
        selectedIndex: idx,
        onDestinationSelected: (i) => _onBottomNavTap(i, context),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check, color: AppColors.primary),
            label: 'Presensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: AppColors.primary),
            label: 'Rapor',
          ),
        ],
      ),
    );
  }

  // ── Desktop Header ──
  Widget _buildHeader(
    BuildContext context,
    String path,
    String userName,
    String userInitials,
    String semesterLabel,
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
              semesterLabel,
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
                UserAvatar(initials: userInitials, size: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Mobile AppBar ──
class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userInitials;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  const _MobileAppBar({
    required this.title,
    required this.userInitials,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: onMenuTap,
        icon: const Icon(Icons.menu, color: AppColors.foreground),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.foreground,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: onProfileTap,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: UserAvatar(initials: userInitials),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE5E7EB)),
      ),
    );
  }
}
