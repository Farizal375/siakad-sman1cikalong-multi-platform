// File: lib/features/admin/screens/dashboard_overview.dart
// ===========================================
// ADMIN DASHBOARD OVERVIEW
// Connected to backend API for admin data KPI
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_colors.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  bool _loading = true;
  String? _errorMessage;
  _AdminStats _stats = _AdminStats.empty();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getDashboardStats();
      final data = response['data'];
      if (!mounted) return;
      setState(() {
        _stats = _AdminStats.fromMap(
          data is Map ? Map<String, dynamic>.from(data) : const {},
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat ringkasan data admin.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _WarningBanner(message: _errorMessage!),
            ],
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildKpiGrid(context),
              const SizedBox(height: 24),
              _buildAdminSummary(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Admin',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ringkasan data pengguna, akses akun, dan konten publik sekolah.',
                style: TextStyle(fontSize: 16, color: AppColors.gray600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: _loading ? null : _loadStats,
          tooltip: 'Muat ulang',
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.gray400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(BuildContext context) {
    final cards = [
      _KpiCardData(
        title: 'Total Pengguna',
        value: '${_stats.totalUsers}',
        subtitle: '${_stats.activeUsers} akun aktif',
        icon: Icons.manage_accounts_rounded,
        color: AppColors.primary,
        route: '/dashboard/users',
      ),
      _KpiCardData(
        title: 'Data Siswa',
        value: '${_stats.totalSiswa}',
        subtitle: 'akun siswa aktif',
        icon: Icons.groups_rounded,
        color: AppColors.green700,
        route: '/dashboard/master-data',
      ),
      _KpiCardData(
        title: 'Data Guru',
        value: '${_stats.totalGuru}',
        subtitle: 'guru dan wali kelas',
        icon: Icons.school_rounded,
        color: AppColors.blue600,
        route: '/dashboard/master-data',
      ),
      _KpiCardData(
        title: 'Konten Publik',
        value: '${_stats.activeKonten}',
        subtitle: 'aktif dari ${_stats.totalKonten} konten',
        icon: Icons.article_rounded,
        color: AppColors.amber600,
        route: '/dashboard/cms',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1180
            ? 4
            : constraints.maxWidth >= 720
            ? 2
            : 1;
        final cardWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * 16)) /
            crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  height: 188,
                  child: _DashboardKpiCard(
                    data: card,
                    onTap: () => context.go(card.route),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildAdminSummary(BuildContext context) {
    return _DataReadinessPanel(stats: _stats);
  }
}

class _DashboardKpiCard extends StatelessWidget {
  final _KpiCardData data;
  final VoidCallback onTap;

  const _DashboardKpiCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(data.icon, color: data.color, size: 24),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.gray400,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.gray600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataReadinessPanel extends StatelessWidget {
  final _AdminStats stats;

  const _DataReadinessPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final activePercent = _percent(stats.activeUsers, stats.totalUsers);
    final contentPercent = _percent(stats.activeKonten, stats.totalKonten);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Data Sistem',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stats.activePeriodLabel,
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
          const SizedBox(height: 22),
          _ProgressMetric(
            label: 'Akun aktif',
            value: '${stats.activeUsers}/${stats.totalUsers}',
            percent: activePercent,
            color: AppColors.primary,
          ),
          const SizedBox(height: 18),
          _ProgressMetric(
            label: 'Konten publik aktif',
            value: '${stats.activeKonten}/${stats.totalKonten}',
            percent: contentPercent,
            color: AppColors.amber600,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SmallMetric(
                label: 'Admin',
                value: '${stats.totalAdmin}',
                icon: Icons.admin_panel_settings_rounded,
                color: AppColors.primary,
              ),
              _SmallMetric(
                label: 'Nonaktif',
                value: '${stats.inactiveUsers}',
                icon: Icons.person_off_rounded,
                color: AppColors.amber600,
              ),
              _SmallMetric(
                label: 'Siswa',
                value: '${stats.totalSiswa}',
                icon: Icons.groups_rounded,
                color: AppColors.green700,
              ),
              _SmallMetric(
                label: 'Guru',
                value: '${stats.totalGuru}',
                icon: Icons.school_rounded,
                color: AppColors.blue600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _percent(int value, int total) {
    if (total <= 0) return 0;
    return ((value / total) * 100).round().clamp(0, 100).toInt();
  }
}

class _ProgressMetric extends StatelessWidget {
  final String label;
  final String value;
  final int percent;
  final Color color;

  const _ProgressMetric({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
            ),
            Text(
              '$value ($percent%)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: percent / 100,
            backgroundColor: AppColors.gray100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SmallMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
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

class _WarningBanner extends StatelessWidget {
  final String message;

  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int totalAdmin;
  final int totalSiswa;
  final int totalGuru;
  final int totalKonten;
  final int activeKonten;
  final String activePeriodLabel;

  const _AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.totalAdmin,
    required this.totalSiswa,
    required this.totalGuru,
    required this.totalKonten,
    required this.activeKonten,
    required this.activePeriodLabel,
  });

  factory _AdminStats.empty() {
    return const _AdminStats(
      totalUsers: 0,
      activeUsers: 0,
      inactiveUsers: 0,
      totalAdmin: 0,
      totalSiswa: 0,
      totalGuru: 0,
      totalKonten: 0,
      activeKonten: 0,
      activePeriodLabel: 'Periode akademik belum aktif',
    );
  }

  factory _AdminStats.fromMap(Map<String, dynamic> data) {
    final totalSiswa = _asInt(data['totalSiswa']);
    final totalGuru = _asInt(data['totalGuru']);
    final totalUsers = _asInt(data['totalUsers'], totalSiswa + totalGuru);
    final activeUsers = _asInt(data['activeUsers'], totalUsers);
    final totalKonten = _asInt(data['totalKonten']);
    final activeKonten = _asInt(data['activeKonten'], totalKonten);
    final activeSemester = _asMap(data['activeSemester']);
    final activeTahunAjaran = _asMap(data['activeTahunAjaran']);
    final periodLabel = _asText(
      activeSemester?['label'],
      _asText(activeTahunAjaran?['kode'], 'Periode akademik belum aktif'),
    );

    return _AdminStats(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      inactiveUsers: _asInt(data['inactiveUsers']),
      totalAdmin: _asInt(data['totalAdmin']),
      totalSiswa: totalSiswa,
      totalGuru: totalGuru,
      totalKonten: totalKonten,
      activeKonten: activeKonten,
      activePeriodLabel: periodLabel == 'Periode akademik belum aktif'
          ? periodLabel
          : 'Periode aktif: $periodLabel',
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  static String _asText(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = '$value'.trim();
    return text.isEmpty ? fallback : text;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }
}

class _KpiCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _KpiCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
