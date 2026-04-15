// File: lib/features/guru/screens/teacher_layout.dart
// ===========================================
// TEACHER LAYOUT
// Uses shared CollapsibleSidebar with SidebarController
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/collapsed_sidebar.dart';

class TeacherLayout extends StatefulWidget {
  final Widget child;
  const TeacherLayout({super.key, required this.child});

  @override
  State<TeacherLayout> createState() => _TeacherLayoutState();
}

class _TeacherLayoutState extends State<TeacherLayout> {
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

  String _getBreadcrumb(String path) {
    if (path == '/guru' || path == '/guru/dashboard') return 'Dashboard';
    if (path == '/guru/kelas') return 'Daftar Kelas';
    if (path.startsWith('/guru/kelas/')) return 'Detail Kelas';
    if (path == '/guru/kelas-wali' || path == '/guru/homeroom') return 'Dashboard Kelas XI-1';
    if (path == '/guru/monitoring-kehadiran') return 'Monitoring Kehadiran XI-1';
    if (path == '/guru/catatan-akademik') return 'Catatan Akademik';
    if (path == '/guru/cetak-rapor') return 'Cetak e-Rapor';
    if (path.startsWith('/guru/rapor-detail/')) return 'Detail Hasil Studi';
    if (path == '/guru/profile') return 'Profil Pengguna';
    return 'Dashboard';
  }

  String _getSectionLabel(String path) {
    if (path.contains('/kelas-wali') ||
        path.contains('/monitoring-kehadiran') ||
        path.contains('/catatan-akademik') ||
        path.contains('/cetak-rapor') ||
        path.contains('/rapor-detail')) {
      return 'Wali Kelas';
    }
    return 'Guru';
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          CollapsibleSidebar(
            title: 'Panel Guru',
            subtitle: 'SMA Negeri 1 Cikalong',
            currentRoute: currentRoute,
            onNavigate: (route) => context.go(route),
            controller: _sidebarController,
            menuItems: [
              SidebarMenuItem(icon: Icons.dashboard, label: 'Dashboard', route: '/guru/dashboard'),
              SidebarMenuItem(icon: Icons.menu_book, label: 'Daftar Kelas', route: '/guru/kelas'),
              // Wali Kelas section
              SidebarMenuItem(icon: Icons.assignment, label: 'Dashboard Kelas', route: '/guru/kelas-wali', sectionLabel: 'WALI KELAS'),
              SidebarMenuItem(icon: Icons.how_to_reg, label: 'Monitoring Kehadiran', route: '/guru/monitoring-kehadiran'),
              SidebarMenuItem(icon: Icons.description, label: 'Catatan Akademik', route: '/guru/catatan-akademik'),
              SidebarMenuItem(icon: Icons.print, label: 'Cetak e-Rapor', route: '/guru/cetak-rapor'),
            ],
            bottomMenuItems: [
              SidebarMenuItem(icon: Icons.settings, label: 'Pengaturan', route: '/guru/profile'),
              SidebarMenuItem(icon: Icons.logout, label: 'Keluar', onTap: () => context.go('/login')),
            ],
          ),

          Expanded(
            child: Column(
              children: [
                _buildHeader(context, path),
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

  Widget _buildHeader(BuildContext context, String path) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
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

          Text(_getSectionLabel(path), style: const TextStyle(color: AppColors.gray500, fontSize: 14)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.gray400),
          ),
          Text(_getBreadcrumb(path), style: const TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600, fontSize: 14)),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text('Aktif: 2026/2027', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 16),

          Stack(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined, color: AppColors.gray600)),
              Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFB91C1C), shape: BoxShape.circle))),
            ],
          ),
          const SizedBox(width: 8),

          GestureDetector(
            onTap: () => context.go('/guru/profile'),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Dra. Siti Aminah', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.foreground)),
                    Text('Guru Mata Pelajaran', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accent, AppColors.accentHover]),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Center(child: Text('SA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
