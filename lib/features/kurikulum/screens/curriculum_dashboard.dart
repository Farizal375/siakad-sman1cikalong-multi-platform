// File: lib/features/kurikulum/screens/curriculum_dashboard.dart
// ===========================================
// CURRICULUM DASHBOARD
// Connected to /dashboard/kurikulum API
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_colors.dart';

class CurriculumDashboard extends StatefulWidget {
  const CurriculumDashboard({super.key});

  @override
  State<CurriculumDashboard> createState() => _CurriculumDashboardState();
}

class _CurriculumDashboardState extends State<CurriculumDashboard> {
  bool _loading = true;
  String? _errorMessage;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getCurriculumDashboard();
      final rawData = response['data'];
      if (!mounted) return;
      setState(() {
        _data = rawData is Map ? Map<String, dynamic>.from(rawData) : {};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat dashboard kurikulum dari backend.';
        _loading = false;
      });
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  String _asText(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = '$value'.trim();
    return text.isEmpty ? fallback : text;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  List<dynamic> _asList(String key) => _data[key] as List? ?? const [];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _data.isEmpty) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadDashboard);
    }

    final activeTahunAjaran = _asMap(_data['activeTahunAjaran']);
    final activeSemester = _asMap(_data['activeSemester']);
    final semesterLabel = _asText(
      activeSemester?['label'],
      'Belum ada semester aktif',
    );
    final tahunLabel = _asText(
      activeTahunAjaran?['kode'],
      'Belum ada tahun ajaran aktif',
    );

    final kpiCards = [
      _KpiCardData(
        title: 'Mata Pelajaran',
        value: '${_asInt(_data['totalMapel'])}',
        subtitle: 'master mapel',
        icon: Icons.menu_book_rounded,
        color: AppColors.blue600,
        bgColor: AppColors.blue50,
        route: '/curriculum/master-mapel',
      ),
      _KpiCardData(
        title: 'Master Kelas',
        value: '${_asInt(_data['totalKelas'])}',
        subtitle: 'kelas terdaftar',
        icon: Icons.apartment_rounded,
        color: AppColors.green700,
        bgColor: AppColors.green50,
        route: '/curriculum/master-akademik',
      ),
      _KpiCardData(
        title: 'Jadwal Pelajaran',
        value: '${_asInt(_data['totalJadwal'])}',
        subtitle: 'slot mengajar',
        icon: Icons.calendar_month_rounded,
        color: AppColors.amber600,
        bgColor: AppColors.amber50,
        route: '/curriculum/jadwal-pelajaran',
      ),
    ];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(tahunLabel, semesterLabel),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _WarningBanner(message: _errorMessage!),
            ],
            const SizedBox(height: 24),
            _buildKpiGrid(kpiCards),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                if (!isWide) {
                  return Column(
                    children: [
                      _buildAcademicStatus(tahunLabel, semesterLabel),
                      const SizedBox(height: 24),
                      _buildRombelOverview(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildAcademicStatus(tahunLabel, semesterLabel),
                    ),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildRombelOverview()),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String tahunLabel, String semesterLabel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Kurikulum',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$tahunLabel | $semesterLabel',
                style: const TextStyle(fontSize: 15, color: AppColors.gray600),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadDashboard,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Muat ulang data',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(List<_KpiCardData> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wideColumns = cards.length < 4 ? cards.length : 4;
        final crossAxisCount = constraints.maxWidth >= 1120
            ? wideColumns
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
                  child: _KpiCard(
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

  Widget _buildQuickActions() {
    final actions = [
      _ActionData(
        label: 'Tambah Mapel',
        icon: Icons.add_rounded,
        route: '/curriculum/master-mapel',
      ),
      _ActionData(
        label: 'Atur Rombel',
        icon: Icons.groups_rounded,
        route: '/curriculum/manajemen-rombel',
      ),
      _ActionData(
        label: 'Kelola Jadwal',
        icon: Icons.edit_calendar_rounded,
        route: '/curriculum/jadwal-pelajaran',
      ),
      _ActionData(
        label: 'Master Akademik',
        icon: Icons.school_rounded,
        route: '/curriculum/master-akademik',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final children = actions
            .map(
              (action) => isWide
                  ? Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: action == actions.last ? 0 : 12,
                        ),
                        child: _QuickActionButton(
                          data: action,
                          onTap: () => context.go(action.route),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuickActionButton(
                        data: action,
                        onTap: () => context.go(action.route),
                      ),
                    ),
            )
            .toList();

        return isWide
            ? Row(children: children)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              );
      },
    );
  }

  Widget _buildAcademicStatus(String tahunLabel, String semesterLabel) {
    final totalSiswa = _asInt(_data['totalSiswa']);
    final totalGuru = _asInt(_data['totalGuru']);
    final totalGuruMapel = _asInt(_data['totalGuruMapel']);
    final totalRuang = _asInt(_data['totalRuang']);
    final totalRombel = _asInt(_data['totalRombel']);
    final rombelTerkunci = _asInt(_data['rombelTerkunci']);
    final rombelTanpaWali = _asInt(_data['rombelTanpaWali']);
    final jadwalTanpaRuang = _asInt(_data['jadwalTanpaRuang']);

    return _SectionCard(
      title: 'Status Akademik',
      icon: Icons.fact_check_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AcademicPeriodPanel(
            tahunLabel: tahunLabel,
            semesterLabel: semesterLabel,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final tileWidth = isNarrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;

              final metrics = [
                _StatusMetricData(
                  label: 'Siswa Aktif',
                  value: '$totalSiswa',
                  icon: Icons.badge_rounded,
                  color: AppColors.primary,
                  bgColor: AppColors.blue50,
                ),
                _StatusMetricData(
                  label: 'Guru Aktif',
                  value: '$totalGuru',
                  icon: Icons.person_rounded,
                  color: AppColors.green700,
                  bgColor: AppColors.green50,
                ),
                _StatusMetricData(
                  label: 'Guru-Mapel',
                  value: '$totalGuruMapel',
                  icon: Icons.assignment_ind_rounded,
                  color: AppColors.amber600,
                  bgColor: AppColors.amber50,
                ),
                _StatusMetricData(
                  label: 'Ruang Kelas',
                  value: '$totalRuang',
                  icon: Icons.meeting_room_rounded,
                  color: AppColors.blue600,
                  bgColor: AppColors.blue50,
                ),
              ];

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: metrics
                    .map(
                      (metric) => SizedBox(
                        width: tileWidth,
                        child: _StatusMetricTile(data: metric),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'Kesiapan Data',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 10),
          _ReadinessRow(
            label: 'Rombel terkunci',
            value: totalRombel > 0
                ? '$rombelTerkunci dari $totalRombel'
                : '$rombelTerkunci',
            icon: Icons.lock_rounded,
            color: AppColors.primary,
            bgColor: AppColors.blue50,
          ),
          _ReadinessRow(
            label: 'Rombel tanpa wali',
            value: '$rombelTanpaWali',
            icon: rombelTanpaWali > 0
                ? Icons.error_outline_rounded
                : Icons.check_circle_rounded,
            color: rombelTanpaWali > 0
                ? AppColors.destructive
                : AppColors.green700,
            bgColor: rombelTanpaWali > 0
                ? AppColors.destructiveBg
                : AppColors.green50,
          ),
          _ReadinessRow(
            label: 'Jadwal tanpa ruang',
            value: '$jadwalTanpaRuang',
            icon: jadwalTanpaRuang > 0
                ? Icons.error_outline_rounded
                : Icons.check_circle_rounded,
            color: jadwalTanpaRuang > 0
                ? AppColors.destructive
                : AppColors.green700,
            bgColor: jadwalTanpaRuang > 0
                ? AppColors.destructiveBg
                : AppColors.green50,
          ),
        ],
      ),
    );
  }

  Widget _buildRombelOverview() {
    final rombelOverview = _asList('rombelOverview');
    final totalRombel = _asInt(_data['totalRombel']);
    final rombelTerkunci = _asInt(_data['rombelTerkunci']);
    final rombelTanpaWali = _asInt(_data['rombelTanpaWali']);

    return _SectionCard(
      title: 'Rombel Aktif',
      icon: Icons.groups_2_rounded,
      actionLabel: 'Kelola rombel',
      onAction: () => context.go('/curriculum/manajemen-rombel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RombelSummaryBar(
            totalRombel: totalRombel,
            lockedCount: rombelTerkunci,
            withoutWaliCount: rombelTanpaWali,
          ),
          const SizedBox(height: 16),
          if (rombelOverview.isEmpty)
            const _EmptyState(
              message: 'Belum ada rombel pada tahun ajaran aktif.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final useGrid = constraints.maxWidth >= 760;
                final itemWidth = useGrid
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: rombelOverview.map((item) {
                    final rombel = _asMap(item);
                    return SizedBox(
                      width: itemWidth,
                      child: _RombelRow(
                        className: _asText(rombel?['className']),
                        grade: _asText(rombel?['grade']),
                        waliKelas: _asText(rombel?['waliKelas']),
                        room: _asText(rombel?['room']),
                        studentCount: _asInt(rombel?['studentCount']),
                        isLocked: rombel?['isLocked'] == true,
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

class _KpiCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String route;

  const _KpiCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.route,
  });
}

class _ActionData {
  final String label;
  final IconData icon;
  final String route;

  const _ActionData({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiCardData data;
  final VoidCallback onTap;

  const _KpiCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.value,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: data.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final _ActionData data;
  final VoidCallback onTap;

  const _QuickActionButton({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  data.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _StatusMetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatusMetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _AcademicPeriodPanel extends StatelessWidget {
  final String tahunLabel;
  final String semesterLabel;

  const _AcademicPeriodPanel({
    required this.tahunLabel,
    required this.semesterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tahunLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  semesterLabel,
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

class _StatusMetricTile extends StatelessWidget {
  final _StatusMetricData data;

  const _StatusMetricTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: data.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, size: 18, color: data.color),
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: data.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _ReadinessRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RombelSummaryBar extends StatelessWidget {
  final int totalRombel;
  final int lockedCount;
  final int withoutWaliCount;

  const _RombelSummaryBar({
    required this.totalRombel,
    required this.lockedCount,
    required this.withoutWaliCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 540;
          final stats = [
            _SummaryStatData(
              label: 'Total',
              value: '$totalRombel',
              color: AppColors.primary,
            ),
            _SummaryStatData(
              label: 'Terkunci',
              value: '$lockedCount',
              color: AppColors.green700,
            ),
            _SummaryStatData(
              label: 'Tanpa Wali',
              value: '$withoutWaliCount',
              color: withoutWaliCount > 0
                  ? AppColors.destructive
                  : AppColors.green700,
            ),
          ];

          if (isCompact) {
            return Column(
              children: stats
                  .map(
                    (stat) => Padding(
                      padding: EdgeInsets.only(
                        bottom: stat == stats.last ? 0 : 10,
                      ),
                      child: _SummaryStat(data: stat),
                    ),
                  )
                  .toList(),
            );
          }

          return Row(
            children: stats
                .map(
                  (stat) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: stat == stats.last ? 0 : 12,
                      ),
                      child: _SummaryStat(data: stat),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _SummaryStatData {
  final String label;
  final String value;
  final Color color;

  const _SummaryStatData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _SummaryStat extends StatelessWidget {
  final _SummaryStatData data;

  const _SummaryStat({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gray600,
              ),
            ),
          ),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: data.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RombelRow extends StatelessWidget {
  final String className;
  final String grade;
  final String waliKelas;
  final String room;
  final int studentCount;
  final bool isLocked;

  const _RombelRow({
    required this.className,
    required this.grade,
    required this.waliKelas,
    required this.room,
    required this.studentCount,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      grade,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(
                label: isLocked ? 'Terkunci' : 'Draft',
                color: isLocked ? AppColors.green700 : AppColors.amber600,
                bgColor: isLocked ? AppColors.green50 : AppColors.amber50,
                icon: isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.person_rounded,
                label: waliKelas == '-' ? 'Wali belum diatur' : waliKelas,
              ),
              _InfoChip(
                icon: Icons.meeting_room_rounded,
                label: room == '-' ? 'Ruang belum diatur' : room,
              ),
              _InfoChip(
                icon: Icons.badge_rounded,
                label: '$studentCount siswa',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.gray600),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gray700,
              ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.amber600,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.gray700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.gray500),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.destructive,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
