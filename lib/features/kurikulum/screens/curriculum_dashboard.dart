// File: lib/features/kurikulum/screens/curriculum_dashboard.dart
// ===========================================
// CURRICULUM DASHBOARD
// Connected to /dashboard/stats API
// KPI Cards, Quick Actions
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

class CurriculumDashboard extends StatefulWidget {
  const CurriculumDashboard({super.key});

  @override
  State<CurriculumDashboard> createState() => _CurriculumDashboardState();
}

class _CurriculumDashboardState extends State<CurriculumDashboard> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await ApiService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = response['data'] ?? {};
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final kpiCards = [
      {'title': 'Total Mata Pelajaran (Mapel)', 'value': '${_stats['totalMapel'] ?? 0}', 'icon': 'book', 'color': 'blue'},
      {'title': 'Master Kelas', 'value': '${_stats['totalKelas'] ?? 0}', 'icon': 'users', 'color': 'green'},
      {'title': 'Total Siswa Aktif', 'value': '${_stats['totalSiswa'] ?? 0}', 'icon': 'calendar', 'color': 'purple'},
      {'title': 'Guru yang Ditugaskan', 'value': '${_stats['totalGuru'] ?? 0}', 'icon': 'user', 'color': 'orange'},
    ];

    return SingleChildScrollView(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Greeting Section ──
          const Text(
            'Selamat Datang, Manajer Kurikulum!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Berikut adalah status operasional akademik saat ini.',
            style: TextStyle(fontSize: 18, color: AppColors.foreground),
          ),
          const SizedBox(height: 32),

          // ── KPI Cards ──
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1024
                  ? 4
                  : constraints.maxWidth >= 768
                      ? 2
                      : 1;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: kpiCards.map((card) {
                  final cardWidth =
                      (constraints.maxWidth - (crossAxisCount - 1) * 24) /
                          crossAxisCount;
                  return SizedBox(
                    width: cardWidth,
                    child: _KPICard(
                      title: card['title']!,
                      value: card['value']!,
                      icon: _kpiIcons[card['icon']]!,
                      bgColor: _kpiBgColors[card['color']]!,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),

          // ── Quick Actions ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tautan Cepat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 768) {
                      return Row(
                        children: _quickActions.map((action) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: action != _quickActions.last ? 16 : 0,
                              ),
                              child: _QuickActionButton(
                                icon: _quickActionIcons[action['icon']]!,
                                label: action['label']!,
                                onTap: () => context.go(action['route']!),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                    return Column(
                      children: _quickActions.map((action) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QuickActionButton(
                          icon: _quickActionIcons[action['icon']]!,
                          label: action['label']!,
                          onTap: () => context.go(action['route']!),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

        ],
      ),
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
  final Color bgColor;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foreground,
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray300, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.foreground),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
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
// STATIC DATA
// ═══════════════════════════════════════════════
const Map<String, IconData> _kpiIcons = {
  'book': Icons.menu_book_rounded,
  'users': Icons.people_rounded,
  'calendar': Icons.calendar_today_rounded,
  'user': Icons.person_rounded,
};

const Map<String, Color> _kpiBgColors = {
  'blue': Color(0xFFDBEAFE),
  'green': Color(0xFFDCFCE7),
  'purple': Color(0xFFF3E8FF),
  'orange': Color(0xFFFFEDD5),
};

const Map<String, IconData> _quickActionIcons = {
  'plus': Icons.add_rounded,
  'settings': Icons.settings_rounded,
  'calendar': Icons.calendar_today_rounded,
};

const List<Map<String, String>> _quickActions = [
  {'icon': 'plus', 'label': 'Tambah Mapel Baru', 'route': '/curriculum/master-mapel'},
  {'icon': 'settings', 'label': 'Atur Rombel', 'route': '/curriculum/manajemen-rombel'},
  {'icon': 'calendar', 'label': 'Kelola Jadwal', 'route': '/curriculum/jadwal-pelajaran'},
];
