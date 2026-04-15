// File: lib/features/siswa/screens/student_layout.dart
// ===========================================
// STUDENT LAYOUT
// Uses shared CollapsibleSidebar with SidebarController
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/collapsed_sidebar.dart';

class StudentLayout extends StatefulWidget {
  final Widget child;
  const StudentLayout({super.key, required this.child});

  @override
  State<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends State<StudentLayout> {
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
    if (path == '/siswa/dashboard' || path == '/siswa') return 'Dashboard';
    if (path == '/siswa/absensi-qr') return 'Absensi QR';
    if (path == '/siswa/hasil-studi') return 'Hasil Studi';
    if (path == '/siswa/riwayat-kehadiran') return 'Riwayat Kehadiran';
    if (path == '/siswa/profil') return 'Profil Pengguna';
    return 'Dashboard';
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
            title: 'Portal Siswa',
            subtitle: 'SMA Negeri 1 Cikalong',
            currentRoute: currentRoute,
            onNavigate: (route) => context.go(route),
            controller: _sidebarController,
            menuItems: [
              SidebarMenuItem(icon: Icons.dashboard, label: 'Dashboard', route: '/siswa/dashboard'),
              SidebarMenuItem(icon: Icons.qr_code_scanner, label: 'Absensi QR', route: '/siswa/absensi-qr'),
              SidebarMenuItem(icon: Icons.school, label: 'Hasil Studi', route: '/siswa/hasil-studi'),
              SidebarMenuItem(icon: Icons.calendar_today, label: 'Riwayat Kehadiran', route: '/siswa/riwayat-kehadiran'),
            ],
            bottomMenuItems: [
              SidebarMenuItem(icon: Icons.settings, label: 'Pengaturan', route: '/siswa/profil'),
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

          const Text('Siswa', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.gray400),
          ),
          Text(_getBreadcrumb(path), style: const TextStyle(fontSize: 14, color: AppColors.foreground, fontWeight: FontWeight.w600)),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text('Aktif: 2025/2026 - Semester Genap', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
            onTap: () => context.go('/siswa/profil'),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ahmad Fauzi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.foreground)),
                    Text('NISN: 2023001', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accent, AppColors.accentHover]),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Center(child: Text('AF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
