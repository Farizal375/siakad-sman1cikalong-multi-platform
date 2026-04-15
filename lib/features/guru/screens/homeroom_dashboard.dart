// File: lib/features/guru/screens/homeroom_dashboard.dart
// ===========================================
// HOMEROOM DASHBOARD – Wali Kelas
// Translated from HomeroomDashboard.tsx
// Bar chart + monitoring absensi kritis
// ===========================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';

class HomeroomDashboard extends StatefulWidget {
  const HomeroomDashboard({super.key});

  @override
  State<HomeroomDashboard> createState() => _HomeroomDashboardState();
}

class _HomeroomDashboardState extends State<HomeroomDashboard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final kpiData = [
      {'title': 'Rata-rata Kehadiran', 'value': '92%', 'color1': const Color(0xFF10B981), 'color2': const Color(0xFF059669), 'textColor': const Color(0xFF059669), 'icon': Icons.trending_up},
      {'title': 'Rata-rata Nilai Kelas', 'value': '84.5', 'color1': const Color(0xFF3B82F6), 'color2': const Color(0xFF2563EB), 'textColor': const Color(0xFF2563EB), 'icon': Icons.bar_chart},
      {'title': 'Siswa Perlu Perhatian', 'value': '3', 'subtitle': 'Siswa', 'color1': const Color(0xFFEF4444), 'color2': const Color(0xFFB91C1C), 'textColor': const Color(0xFFB91C1C), 'icon': Icons.warning_amber},
    ];

    final subjectData = [
      ('Matematika', 82.0),
      ('Fisika', 78.0),
      ('B. Indonesia', 89.0),
      ('B. Inggris', 85.0),
      ('Kimia', 76.0),
      ('Biologi', 88.0),
    ];

    final criticalStudents = [
      {'name': 'Budi Santoso', 'nisn': '0012345671', 'attendance': 62},
      {'name': 'Dewi Lestari', 'nisn': '0012345674', 'attendance': 58},
      {'name': 'Andi Wijaya', 'nisn': '0012345675', 'attendance': 65},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('Pantauan Akademik Kelas XI-1', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.foreground)),
          const SizedBox(height: 8),
          const Text('Monitoring performa akademik dan kehadiran siswa wali kelas Anda', style: TextStyle(color: AppColors.gray600)),
          const SizedBox(height: 24),

          // KPI Cards
          Row(
            children: kpiData.map((kpi) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(kpi['title'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(kpi['value'] as String, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: kpi['textColor'] as Color)),
                                if (kpi.containsKey('subtitle')) ...[
                                  const SizedBox(width: 4),
                                  Text(kpi['subtitle'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48, height: 48,
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
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Main Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT – Interactive Bar Chart (60%)
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rata-rata Nilai Per Mata Pelajaran', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                      const SizedBox(height: 20),
                      Container(
                        height: 320,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
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
                                  _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                                });
                              },
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => const Color(0xFF1E293B),
                                tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                tooltipMargin: 8,
                                tooltipRoundedRadius: 12,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${subjectData[group.x.toInt()].$1}\n',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                    children: [
                                      TextSpan(
                                        text: rod.toY.toStringAsFixed(1),
                                        style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 16),
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
                                    final isTouched = _touchedIndex == value.toInt();
                                    final title = subjectData[value.toInt()].$1;
                                    final shortTitle = title.length > 5 ? title.substring(0, 3).toUpperCase() : title.toUpperCase();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Text(
                                        shortTitle,
                                        style: TextStyle(
                                          color: isTouched ? AppColors.accent : AppColors.gray500,
                                          fontSize: 11,
                                          fontWeight: isTouched ? FontWeight.w800 : FontWeight.w600,
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
                                        style: const TextStyle(color: AppColors.gray400, fontSize: 11, fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.right,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                                          ? [const Color(0xFF38BDF8), const Color(0xFF0284C7)]
                                          : [const Color(0xFF818CF8), const Color(0xFF4F46E5)],
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isTouched ? AppColors.accent.withValues(alpha: 0.1) : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isTouched ? AppColors.accent : Colors.transparent),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(s.$1, style: TextStyle(fontSize: 13, fontWeight: isTouched ? FontWeight.bold : FontWeight.w500, color: isTouched ? AppColors.accent : AppColors.gray700)),
                                Text('${s.$2.toInt()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isTouched ? AppColors.accent : AppColors.primary)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // RIGHT – Critical Attendance (40%)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monitoring Absensi Bermasalah', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                      const SizedBox(height: 4),
                      const Text('Kehadiran < 70%', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
                      const SizedBox(height: 16),
                      ...criticalStudents.map((s) => _buildCriticalCard(s)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalCard(Map<String, dynamic> student) {
    final att = student['attendance'] as int;
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
                        Text(student['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.foreground)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFB91C1C), borderRadius: BorderRadius.circular(99)),
                          child: const Text('KRITIS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('NISN: ${student['nisn']}', style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: att / 100,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB91C1C)),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$att%', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB91C1C), fontSize: 14)),
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
