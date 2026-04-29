// File: lib/features/kurikulum/screens/curriculum_layout.dart
// ===========================================
// CURRICULUM LAYOUT
// Uses shared CollapsibleSidebar with SidebarController
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/api_service.dart';
import '../../../shared_widgets/collapsed_sidebar.dart';

class CurriculumLayout extends ConsumerStatefulWidget {
  final Widget child;
  const CurriculumLayout({super.key, required this.child});

  @override
  ConsumerState<CurriculumLayout> createState() => _CurriculumLayoutState();
}

class _CurriculumLayoutState extends ConsumerState<CurriculumLayout> {
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
        setState(() => _semesterLabel = data != null
            ? 'Aktif: ${data['label']}'
            : 'Tidak ada semester aktif');
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

  String get _pageTitle {
    final r = GoRouterState.of(context).uri.toString();
    if (r.contains('/master-mapel')) return 'Master Mapel';
    if (r.contains('/manajemen-rombel')) return 'Manajemen Rombel';
    if (r.contains('/jadwal-pelajaran')) return 'Jadwal Pelajaran';
    if (r.contains('/master-akademik')) return 'Master Akademik';
    if (r.contains('/profile')) return 'Profil Pengguna';
    return 'Dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    // Baca user dari authProvider — reaktif, langsung update saat nama berubah
    final authUser = ref.watch(authProvider).valueOrNull;
    final userName = authUser?.name ?? 'Manajer Kurikulum';
    final userInitials = userName.trim().split(' ')
        .where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0].toUpperCase()).join();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          CollapsibleSidebar(
            title: 'Panel Kurikulum',
            subtitle: 'SMA Negeri 1 Cikalong',
            currentRoute: currentRoute,
            onNavigate: (route) => context.go(route),
            controller: _sidebarController,
            menuItems: [
              SidebarMenuItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/curriculum'),
              SidebarMenuItem(icon: Icons.school_outlined, label: 'Master Akademik', route: '/curriculum/master-akademik'),
              SidebarMenuItem(icon: Icons.menu_book_outlined, label: 'Master Mapel', route: '/curriculum/master-mapel'),
              SidebarMenuItem(icon: Icons.people_outline, label: 'Manajemen Rombel', route: '/curriculum/manajemen-rombel'),
              SidebarMenuItem(icon: Icons.calendar_today_outlined, label: 'Jadwal Pelajaran', route: '/curriculum/jadwal-pelajaran'),
              SidebarMenuItem(icon: Icons.move_up, label: 'Migrasi Kelas', route: '/curriculum/migrasi-kelas'),
            ],
            bottomMenuItems: [
              SidebarMenuItem(icon: Icons.settings_outlined, label: 'Pengaturan'),
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

          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, currentRoute, userName, userInitials),
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

  Widget _buildTopBar(BuildContext context, String currentRoute, String userName, String userInitials) {
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
          IconButton(
            onPressed: () => _sidebarController.toggle(),
            icon: AnimatedRotation(
              turns: _sidebarController.isCollapsed ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.menu_open, size: 22),
            ),
            tooltip: _sidebarController.isCollapsed ? 'Perluas Sidebar' : 'Perkecil Sidebar',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.gray50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),

          const Text('Kurikulum', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.gray400),
          ),
          Text(_pageTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground)),

          const Spacer(),

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

          InkWell(
            onTap: () => context.go('/curriculum/profile'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground)),
                      const Text('Manajer Kurikulum', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accent, AppColors.accentHover]),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(child: Text(userInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
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
