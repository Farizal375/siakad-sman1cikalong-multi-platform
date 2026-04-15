// File: lib/features/admin/screens/dashboard_overview.dart
// ===========================================
// ADMIN DASHBOARD OVERVIEW
// Translated from DashboardOverview.tsx
// KPI Cards, Quick Actions, Recent Activity, Stats
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

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
              fontSize: 36, // text-4xl
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8), // mb-2
          const Text(
            'Berikut adalah aktivitas yang terjadi di sistem sekolah Anda hari ini.',
            style: TextStyle(fontSize: 18, color: AppColors.gray600),
          ),
          const SizedBox(height: 32), // mb-8

          // ── KPI Cards (grid 1/2/4 cols) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1024
                  ? 4
                  : constraints.maxWidth >= 768
                      ? 2
                      : 1;
              return Wrap(
                spacing: 24, // gap-6
                runSpacing: 24,
                children: _kpiCards.map((card) {
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
          const SizedBox(height: 32), // mb-8

          // ── Quick Actions ──
          _buildQuickActions(context),
          const SizedBox(height: 24), // mt-6

          // ── Weekly Stats ──
          _buildWeeklyStats(),
        ],
      ),
    ),
    );
  }

  // ── Quick Actions Panel ──
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // rounded-2xl
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
              const SizedBox(width: 8), // gap-2
              const Text(
                'Tautan Cepat',
                style: TextStyle(
                  fontSize: 20, // text-xl
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24), // mb-6
          ..._quickActions.map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 12), // space-y-3
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



  // ── Weekly Stats ──
  Widget _buildWeeklyStats() {
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
          const Text(
            'Statistik Minggu Ini',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 768 ? 3 : 1;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: _weeklyStats.map((stat) {
                  final cardWidth =
                      (constraints.maxWidth - (crossAxisCount - 1) * 24) /
                          crossAxisCount;
                  return SizedBox(
                    width: cardWidth,
                    child: _StatItem(
                      label: stat['label']!,
                      value: stat['value']!,
                      change: stat['change']!,
                      positive: stat['positive'] == 'true',
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// KPI CARD - Translated from KPICard component
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
      borderRadius: BorderRadius.circular(16), // rounded-2xl
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24), // p-6
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon (p-3 rounded-xl)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16), // mb-4

              // Title (text-sm)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 4), // mb-1

              // Value (text-3xl)
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 py-3
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200, width: 2),
            borderRadius: BorderRadius.circular(12), // rounded-xl
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.gray600),
              const SizedBox(width: 12), // gap-3
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
// STAT ITEM
// ═══════════════════════════════════════════════
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool positive;

  const _StatItem({
    required this.label,
    required this.value,
    required this.change,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12), // rounded-xl
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.gray600),
          ),
          const SizedBox(height: 8), // mb-2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28, // text-2xl
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // px-2 py-1
                decoration: BoxDecoration(
                  color: positive
                      ? AppColors.green100
                      : AppColors.red100,
                  borderRadius: BorderRadius.circular(999), // rounded-full
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 12, // text-xs
                    fontWeight: FontWeight.w500,
                    color: positive
                        ? AppColors.green700
                        : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// STATIC DATA
// ═══════════════════════════════════════════════

const Map<String, IconData> _kpiIcons = {
  'users': Icons.people_rounded,
  'cap': Icons.school_rounded,
  'building': Icons.apartment_rounded,
  'megaphone': Icons.campaign_rounded,
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

const List<Map<String, String>> _kpiCards = [
  {'title': 'Total Siswa', 'value': '1,250', 'icon': 'users', 'color': 'blue', 'route': '/dashboard/users'},
  {'title': 'Total Guru', 'value': '85', 'icon': 'cap', 'color': 'green', 'route': '/dashboard/users'},
  {'title': 'Kelas Aktif', 'value': '36', 'icon': 'building', 'color': 'purple', 'route': '/dashboard/master-data'},
  {'title': 'Berita Terpublikasi', 'value': '12', 'icon': 'megaphone', 'color': 'orange', 'route': '/dashboard/cms'},
];

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



const List<Map<String, String>> _weeklyStats = [
  {'label': 'Login Pengguna', 'value': '342', 'change': '+12%', 'positive': 'true'},
  {'label': 'Pengumuman Baru', 'value': '8', 'change': '+2', 'positive': 'true'},
  {'label': 'Pembaruan CMS', 'value': '15', 'change': '+5', 'positive': 'true'},
];
