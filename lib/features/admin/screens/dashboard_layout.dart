// File: lib/features/admin/screens/dashboard_layout.dart
// ===========================================
// ADMIN DASHBOARD LAYOUT — Responsive (mobile + desktop)
// Desktop (≥ 768px): Sidebar + TopBar + Content
// Mobile (< 768px): AppBar + Drawer + Content
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/active_semester_provider.dart';
import '../../../shared_widgets/collapsed_sidebar.dart';
import '../../../shared_widgets/responsive_helper.dart';

class DashboardLayout extends ConsumerStatefulWidget {
  final Widget child;
  const DashboardLayout({super.key, required this.child});

  @override
  ConsumerState<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends ConsumerState<DashboardLayout> {
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

  List<SidebarMenuItem> get _menuItems => [
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
  ];

  List<SidebarMenuItem> _bottomMenuItems(BuildContext context) => [
    SidebarMenuItem(icon: Icons.settings_outlined, label: 'Pengaturan'),
    SidebarMenuItem(
      icon: Icons.logout,
      label: 'Keluar',
      onTap: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final authUser = ref.watch(authProvider).valueOrNull;
    final userName = authUser?.name ?? 'Admin';
    final userInitials = userName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final userRole = authUser?.role.displayName ?? 'Super Admin';
    final mobile = context.isMobile;
    final semesterLabel =
        ref.watch(activeSemesterLabelProvider).valueOrNull ?? 'Memuat...';

    final sidebar = CollapsibleSidebar(
      title: 'Panel Admin',
      subtitle: 'SMA Negeri 1 Cikalong',
      currentRoute: currentRoute,
      onNavigate: (route) {
        context.go(route);
        if (mobile) Navigator.of(context).pop();
      },
      controller: _sidebarController,
      menuItems: _menuItems,
      bottomMenuItems: _bottomMenuItems(context),
    );

    if (mobile) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        appBar: _MobileAppBar(
          title: _pageTitleFromRoute(currentRoute),
          userInitials: userInitials,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onProfileTap: () => context.go('/dashboard/profile'),
        ),
        drawer: Drawer(width: 280, child: SafeArea(child: sidebar)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      );
    }

    // ── Desktop ──
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          sidebar,
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  currentRoute: currentRoute,
                  sidebarController: _sidebarController,
                  roleName: 'Admin',
                  semesterLabel: semesterLabel,
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

  String _pageTitleFromRoute(String route) {
    if (route.contains('/users')) return 'Manajemen Pengguna';
    if (route.contains('/cms')) return 'CMS Publik';
    if (route.contains('/master-data')) return 'Master Data';
    if (route.contains('/profile')) return 'Profil';
    return 'Beranda';
  }
}

// ═════════════════════════════════════
// SHARED MOBILE APP BAR
// ═════════════════════════════════════
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
        child: Container(height: 1, color: AppColors.borderLight),
      ),
    );
  }
}

// ═════════════════════════════════════
// DESKTOP TOP BAR
// ═════════════════════════════════════
class _TopBar extends StatelessWidget {
  final String currentRoute;
  final SidebarController sidebarController;
  final String roleName;
  final String semesterLabel;
  final String userName;
  final String userRole;
  final String userInitials;
  final VoidCallback onProfileTap;

  const _TopBar({
    required this.currentRoute,
    required this.sidebarController,
    required this.roleName,
    required this.semesterLabel,
    required this.userName,
    required this.userRole,
    required this.userInitials,
    required this.onProfileTap,
  });

  String get _pageTitle {
    if (currentRoute.contains('/users')) return 'Manajemen Pengguna';
    if (currentRoute.contains('/cms')) return 'CMS Publik';
    if (currentRoute.contains('/master-data')) return 'Master Data';
    if (currentRoute.contains('/profile')) return 'Profil Pengguna';
    return 'Beranda';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
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
            onPressed: () => sidebarController.toggle(),
            icon: AnimatedRotation(
              turns: sidebarController.isCollapsed ? 0.5 : 0,
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
          Text(
            roleName,
            style: const TextStyle(fontSize: 14, color: AppColors.gray500),
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
            _pageTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              semesterLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.foreground,
                        ),
                      ),
                      Text(
                        userRole,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  UserAvatar(initials: userInitials, size: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
