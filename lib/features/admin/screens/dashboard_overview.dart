// File: lib/features/admin/screens/dashboard_overview.dart
// ===========================================
// ADMIN DASHBOARD OVERVIEW
// Connected to backend API for real KPI data
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  bool _loading = true;
  int _totalSiswa = 0;
  int _totalGuru = 0;
  int _totalKelas = 0;
  int _totalMapel = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await ApiService.getDashboardStats();
      final data = response['data'];
      if (mounted) {
        setState(() {
          _totalSiswa = data['totalSiswa'] ?? 0;
          _totalGuru = data['totalGuru'] ?? 0;
          _totalKelas = data['totalKelas'] ?? 0;
          _totalMapel = data['totalMapel'] ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Greeting Section (mb-8) ──
          const Text(
            'Selamat Datang Kembali, Administrator!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Berikut adalah aktivitas yang terjadi di sistem sekolah Anda hari ini.',
            style: TextStyle(fontSize: 18, color: AppColors.gray600),
          ),
          const SizedBox(height: 32),

          // ── KPI Cards (grid 1/2/4 cols) ──
          _loading
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 1024
                        ? 4
                        : constraints.maxWidth >= 768
                            ? 2
                            : 1;
                    
                    final kpiData = [
                      {'title': 'Total Siswa', 'value': '$_totalSiswa', 'icon': 'users', 'color': 'blue', 'route': '/dashboard/users'},
                      {'title': 'Total Guru', 'value': '$_totalGuru', 'icon': 'cap', 'color': 'green', 'route': '/dashboard/users'},
                      {'title': 'Kelas Aktif', 'value': '$_totalKelas', 'icon': 'building', 'color': 'purple', 'route': '/dashboard/master-data'},
                      {'title': 'Mata Pelajaran', 'value': '$_totalMapel', 'icon': 'megaphone', 'color': 'orange', 'route': '/dashboard/master-data'},
                    ];

                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: kpiData.map((card) {
                        final cardWidth =
                            (constraints.maxWidth - (crossAxisCount - 1) * 24) /
                                crossAxisCount;
                        return SizedBox(
                          width: cardWidth,
                          child: _KPICard(
                            title: card['title']!,
                            value: card['value']!,
                            icon: _kpiIcons[card['icon']]!,
                            color: _kpiColors[card['color']]!,
                            bgColor: _kpiBgColors[card['color']]!,
                            onTap: () => context.go(card['route']!),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
          const SizedBox(height: 32),

          // ── Quick Actions ──
          _buildQuickActions(context),
        ],
      ),
    ),
    );
  }

  // ── Quick Actions Panel ──
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 24, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Tautan Cepat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._quickActions.map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuickActionButton(
                  icon: _quickActionIcons[action['icon']]!,
                  label: action['label']!,
                  onTap: () => context.go(action['route']!),
                ),
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// KPI CARD
// ═══════════════════════════════════════════════
class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// QUICK ACTION BUTTON
// ═══════════════════════════════════════════════
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.gray600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// STATIC DATA (non-API)
// ═══════════════════════════════════════════════

const Map<String, IconData> _kpiIcons = {
  'users': Icons.people_rounded,
  'cap': Icons.school_rounded,
  'building': Icons.apartment_rounded,
  'megaphone': Icons.menu_book_rounded,
};

const Map<String, Color> _kpiColors = {
  'blue': Color(0xFF2563EB),
  'green': Color(0xFF16A34A),
  'purple': Color(0xFF9333EA),
  'orange': Color(0xFFEA580C),
};

const Map<String, Color> _kpiBgColors = {
  'blue': Color(0xFFEFF6FF),
  'green': Color(0xFFF0FDF4),
  'purple': Color(0xFFFAF5FF),
  'orange': Color(0xFFFFF7ED),
};

const Map<String, IconData> _quickActionIcons = {
  'plus': Icons.add_rounded,
  'megaphone': Icons.campaign_rounded,
  'clock': Icons.schedule_rounded,
};

const List<Map<String, String>> _quickActions = [
  {'icon': 'plus', 'label': 'Tambah Pengguna Baru', 'route': '/dashboard/users'},
  {'icon': 'megaphone', 'label': 'Posting Pengumuman', 'route': '/dashboard/cms'},
  {'icon': 'clock', 'label': 'Perbarui Tahun Akademik', 'route': '/dashboard/master-data'},
];
