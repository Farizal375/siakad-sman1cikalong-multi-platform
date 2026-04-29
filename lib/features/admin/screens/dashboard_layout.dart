// File: lib/features/admin/screens/dashboard_layout.dart
// ===========================================
// ADMIN DASHBOARD LAYOUT
// Uses shared CollapsibleSidebar with SidebarController
// Toggle button lives in the TopBar next to breadcrumb
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/api_service.dart';
import '../../../shared_widgets/collapsed_sidebar.dart';

class DashboardLayout extends ConsumerStatefulWidget {
  final Widget child;
  const DashboardLayout({super.key, required this.child});

  @override
  ConsumerState<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends ConsumerState<DashboardLayout> {
  final SidebarController _sidebarController = SidebarController();

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

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    // Baca user dari authProvider — reaktif, langsung update saat nama berubah
    final authUser = ref.watch(authProvider).valueOrNull;
    final userName = authUser?.name ?? 'Admin';
    final userInitials = userName.trim().split(' ')
        .where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0].toUpperCase()).join();
    final userRole = authUser?.role.displayName ?? 'Super Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ──
          CollapsibleSidebar(
            title: 'Panel Admin',
            subtitle: 'SMA Negeri 1 Cikalong',
            currentRoute: currentRoute,
            onNavigate: (route) => context.go(route),
            controller: _sidebarController,
            menuItems: [
              SidebarMenuItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                route: '/dashboard',
              ),
              SidebarMenuItem(
                icon: Icons.article_outlined,
                label: 'Public CMS',
                route: '/dashboard/cms',
              ),
              SidebarMenuItem(
                icon: Icons.people_outline,
                label: 'User Management',
                route: '/dashboard/users',
              ),
              SidebarMenuItem(
                icon: Icons.storage_outlined,
                label: 'Master Data',
                route: '/dashboard/master-data',
              ),
            ],
            bottomMenuItems: [
              SidebarMenuItem(
                icon: Icons.settings_outlined,
                label: 'Pengaturan',
              ),
              SidebarMenuItem(
                icon: Icons.logout,
                label: 'Keluar',
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),

          // ── Main Content ──
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  currentRoute: currentRoute,
                  sidebarController: _sidebarController,
                  roleName: 'Admin',
                  userName: userName,
                  userRole: userRole,
                  userInitials: userInitials,
                  onProfileTap: () => context.go('/dashboard/profile'),
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
}

// ═════════════════════════════════════
// SHARED TOP BAR — Reusable across all roles
// ═════════════════════════════════════
class _TopBar extends StatefulWidget {
  final String currentRoute;
  final SidebarController sidebarController;
  final String roleName;
  final String userName;
  final String userRole;
  final String userInitials;
  final VoidCallback onProfileTap;

  const _TopBar({
    required this.currentRoute,
    required this.sidebarController,
    required this.roleName,
    required this.userName,
    required this.userRole,
    required this.userInitials,
    required this.onProfileTap,
  });

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  String _semesterLabel = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _loadSemester();
  }

  Future<void> _loadSemester() async {
    try {
      final res = await ApiService.getActiveSemester();
      final data = res['data'];
      if (mounted) {
        setState(() => _semesterLabel = data != null
            ? 'Aktif: ${data['label']}'
            : 'Tidak ada semester aktif');
      }
    } catch (_) {
      if (mounted) setState(() => _semesterLabel = 'Aktif: -');
    }
  }

  String get _pageTitle {
    if (widget.currentRoute.contains('/users')) return 'Manajemen Pengguna';
    if (widget.currentRoute.contains('/cms')) return 'CMS Publik';
    if (widget.currentRoute.contains('/master-data')) return 'Master Data';
    if (widget.currentRoute.contains('/profile')) return 'Profil Pengguna';
    return 'Beranda';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
        boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Toggle sidebar button
          IconButton(
            onPressed: () => widget.sidebarController.toggle(),
            icon: AnimatedRotation(
              turns: widget.sidebarController.isCollapsed ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.menu_open, size: 22),
            ),
            tooltip: widget.sidebarController.isCollapsed ? 'Perluas Sidebar' : 'Perkecil Sidebar',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.gray50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),

          // Breadcrumb
          Text(widget.roleName, style: const TextStyle(fontSize: 14, color: AppColors.gray500)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.gray400),
          ),
          Text(
            _pageTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),

          const Spacer(),

          // Active Semester — from DB
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Text(_semesterLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 16),

          // Profile
          InkWell(
            onTap: widget.onProfileTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(widget.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground)),
                      Text(widget.userRole, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accent, AppColors.accentHover]),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(child: Text(widget.userInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
