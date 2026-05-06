// File: lib/features/guru/screens/homeroom_dashboard.dart
// ===========================================
// HOMEROOM DASHBOARD – Wali Kelas
// Connected to /dashboard/wali-kelas API
// Bar chart + monitoring absensi kritis
// ===========================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

class HomeroomDashboard extends StatefulWidget {
  const HomeroomDashboard({super.key});

  @override
  State<HomeroomDashboard> createState() => _HomeroomDashboardState();
}

class _HomeroomDashboardState extends State<HomeroomDashboard> {
  int _touchedIndex = -1;
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final response = await ApiService.getWaliKelasDashboard();
      if (mounted) {
        setState(() {
          _data = response['data'] ?? {};
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
    final isNarrow = MediaQuery.sizeOf(context).width < 860;

    final hasClass = _data['hasClass'] == true;
    if (!hasClass) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 64, color: AppColors.gray400),
            SizedBox(height: 16),
            Text(
              'Anda belum ditugaskan sebagai wali kelas',
              style: TextStyle(fontSize: 18, color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    final kelas = _data['kelas'] ?? '-';
    final totalSiswa = _data['totalSiswa'] ?? 0;
    final flaggedStudents = (_data['flaggedStudents'] as List? ?? []);
    final students = (_data['students'] as List? ?? []);

    // Build subject averages from student grade data
    final Map<String, List<double>> subjectGrades = {};
    for (final s in students) {
      final grades = s['grades'] as List? ?? [];
      for (final g in grades) {
        final mapel = g['mapel'] ?? '-';
        subjectGrades.putIfAbsent(mapel, () => []);
        subjectGrades[mapel]!.add((g['nilaiAkhir'] ?? 0).toDouble());
      }
    }
    final subjectData = subjectGrades.entries.map((e) {
      final avg = e.value.isNotEmpty
          ? e.value.reduce((a, b) => a + b) / e.value.length
          : 0.0;
      return (e.key, avg);
    }).toList();

    // Overall attendance rate
    final attendanceStats =
        _data['attendanceStats'] as Map<String, dynamic>? ?? {};
    final totalHadir = attendanceStats['hadir'] ?? 0;
    final totalAll =
        totalHadir +
        (attendanceStats['sakit'] ?? 0) +
        (attendanceStats['izin'] ?? 0) +
        (attendanceStats['alpa'] ?? 0);
    final attendanceRate = totalAll > 0
        ? ((totalHadir / totalAll) * 100).round()
        : 100;

    // Overall grade average
    final allGrades = students
        .map<double>((s) => (s['averageGrade'] ?? 0).toDouble())
        .where((g) => g > 0)
        .toList();
    final overallGrade = allGrades.isNotEmpty
        ? (allGrades.reduce((a, b) => a + b) / allGrades.length)
              .toStringAsFixed(1)
        : '0';

    final kpiData = [
      {
        'title': 'Rata-rata Kehadiran',
        'value': '$attendanceRate%',
        'color1': const Color(0xFF10B981),
        'color2': const Color(0xFF059669),
        'textColor': const Color(0xFF059669),
        'icon': Icons.trending_up,
      },
      {
        'title': 'Rata-rata Nilai Kelas',
        'value': overallGrade,
        'color1': const Color(0xFF3B82F6),
        'color2': const Color(0xFF2563EB),
        'textColor': const Color(0xFF2563EB),
        'icon': Icons.bar_chart,
      },
      {
        'title': 'Siswa Perlu Perhatian',
        'value': '${flaggedStudents.length}',
        'subtitle': 'Siswa',
        'color1': const Color(0xFFEF4444),
        'color2': const Color(0xFFB91C1C),
        'textColor': const Color(0xFFB91C1C),
        'icon': Icons.warning_amber,
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Pantauan Akademik $kelas',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalSiswa siswa terdaftar • Monitoring performa akademik dan kehadiran',
            style: const TextStyle(color: AppColors.gray600),
          ),
          const SizedBox(height: 24),

          isNarrow
              ? Column(
                  children: kpiData
                      .map(
                        (kpi) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildKpiCard(kpi),
                        ),
                      )
                      .toList(),
                )
              : Row(
                  children: kpiData
                      .map(
                        (kpi) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _buildKpiCard(kpi),
                          ),
                        ),
                      )
                      .toList(),
                ),
          const SizedBox(height: 24),

          // Main Content
          isNarrow
              ? Column(
                  children: [
                    _buildChartCard(subjectData),
                    const SizedBox(height: 16),
                    _buildCriticalCardPanel(flaggedStudents),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildChartCard(subjectData)),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildCriticalCardPanel(flaggedStudents),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(Map<String, dynamic> kpi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kpi['title'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      kpi['value'] as String,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: kpi['textColor'] as Color,
                      ),
                    ),
                    if (kpi.containsKey('subtitle')) ...[
                      const SizedBox(width: 4),
                      Text(
                        kpi['subtitle'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kpi['color1'] as Color, kpi['color2'] as Color],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(kpi['icon'] as IconData, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<(String, double)> subjectData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rata-rata Nilai Per Mata Pelajaran',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 20),
          if (subjectData.isEmpty)
            Container(
              height: 320,
              alignment: Alignment.center,
              child: const Text(
                'Belum ada data nilai',
                style: TextStyle(color: AppColors.gray500),
              ),
            )
          else
            Container(
              height: 320,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            barTouchResponse == null ||
                            barTouchResponse.spot == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            barTouchResponse.spot!.touchedBarGroupIndex;
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1E293B),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      tooltipMargin: 8,
                      tooltipRoundedRadius: 12,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${subjectData[group.x.toInt()].$1}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: rod.toY.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= subjectData.length)
                            return const SizedBox();
                          final isTouched = _touchedIndex == value.toInt();
                          final title = subjectData[value.toInt()].$1;
                          final shortTitle = title.length > 5
                              ? title.substring(0, 3).toUpperCase()
                              : title.toUpperCase();
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              shortTitle,
                              style: TextStyle(
                                color: isTouched
                                    ? AppColors.accent
                                    : AppColors.gray500,
                                fontSize: 11,
                                fontWeight: isTouched
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: AppColors.gray400,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                      dashArray: [6, 4],
                    ),
                  ),
                  barGroups: subjectData.asMap().entries.map((e) {
                    final idx = e.key;
                    final val = e.value.$2;
                    final isTouched = idx == _touchedIndex;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          gradient: LinearGradient(
                            colors: isTouched
                                ? [
                                    const Color(0xFF38BDF8),
                                    const Color(0xFF0284C7),
                                  ]
                                : [
                                    const Color(0xFF818CF8),
                                    const Color(0xFF4F46E5),
                                  ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: isTouched ? 36 : 24,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: const Color(0xFFF1F5F9),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 20),
          if (subjectData.isNotEmpty)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.5,
              children: subjectData.asMap().entries.map((e) {
                final isTouched = _touchedIndex == e.key;
                final s = e.value;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isTouched
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTouched ? AppColors.accent : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s.$1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isTouched
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isTouched
                                ? AppColors.accent
                                : AppColors.gray700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${s.$2.toInt()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isTouched
                              ? AppColors.accent
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCriticalCardPanel(List flaggedStudents) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monitoring Absensi Bermasalah',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kehadiran < 70%',
            style: TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
          const SizedBox(height: 16),
          if (flaggedStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Tidak ada siswa bermasalah ✓',
                  style: TextStyle(
                    color: AppColors.green700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ...flaggedStudents.map((s) => _buildCriticalCard(s)),
        ],
      ),
    );
  }

  Widget _buildCriticalCard(dynamic student) {
    final att = student['attendanceRate'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7D7), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          student['name'] ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB91C1C),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'KRITIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NISN: ${student['nisn'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: att / 100,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFB91C1C),
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$att%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB91C1C),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
