// File: lib/features/siswa/screens/hasil_studi.dart
// ===========================================
// HASIL STUDI – Siswa
// Translated from HasilStudi.tsx
// 3 Tab: Aktivitas Belajar | Transkrip Nilai | Visualisasi Data
// ===========================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';

class HasilStudi extends StatefulWidget {
  const HasilStudi({super.key});

  @override
  State<HasilStudi> createState() => _HasilStudiState();
}

class _HasilStudiState extends State<HasilStudi> {
  String _activeTab = 'aktivitas'; // 'aktivitas' | 'transkrip' | 'visualisasi'

  final _ganjil = [
    {'no': 1, 'nama': 'Matematika', 'kkm': 75, 'nilai': 84, 'predikat': 'Sangat Baik'},
    {'no': 2, 'nama': 'Fisika', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
    {'no': 3, 'nama': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 90, 'predikat': 'Sangat Baik'},
    {'no': 4, 'nama': 'Bahasa Inggris', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
    {'no': 5, 'nama': 'Kimia', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
    {'no': 6, 'nama': 'Biologi', 'kkm': 75, 'nilai': 96, 'predikat': 'Sangat Baik'},
  ];

  final _genap = [
    {'no': 1, 'nama': 'Matematika', 'kkm': 75, 'nilai': 85, 'predikat': 'Sangat Baik'},
    {'no': 2, 'nama': 'Fisika', 'kkm': 75, 'nilai': 78, 'predikat': 'Baik'},
    {'no': 3, 'nama': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 92, 'predikat': 'Sangat Baik'},
    {'no': 4, 'nama': 'Bahasa Inggris', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
    {'no': 5, 'nama': 'Kimia', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
    {'no': 6, 'nama': 'Biologi', 'kkm': 75, 'nilai': 90, 'predikat': 'Sangat Baik'},
  ];

  final _transcript = [
    {'semester': 'Semester 1', 'kode': 'MAT-10', 'nama': 'Matematika', 'nilai': 82, 'huruf': 'A-'},
    {'semester': 'Semester 1', 'kode': 'FIS-10', 'nama': 'Fisika', 'nilai': 78, 'huruf': 'B+'},
    {'semester': 'Semester 1', 'kode': 'IND-10', 'nama': 'Bahasa Indonesia', 'nilai': 85, 'huruf': 'A'},
    {'semester': 'Semester 2', 'kode': 'MAT-10', 'nama': 'Matematika', 'nilai': 84, 'huruf': 'A'},
    {'semester': 'Semester 2', 'kode': 'FIS-10', 'nama': 'Fisika', 'nilai': 80, 'huruf': 'A-'},
    {'semester': 'Semester 2', 'kode': 'IND-10', 'nama': 'Bahasa Indonesia', 'nilai': 88, 'huruf': 'A'},
    {'semester': 'Semester 3', 'kode': 'MAT-11', 'nama': 'Matematika', 'nilai': 83, 'huruf': 'A-'},
    {'semester': 'Semester 3', 'kode': 'FIS-11', 'nama': 'Fisika', 'nilai': 79, 'huruf': 'B+'},
    {'semester': 'Semester 3', 'kode': 'IND-11', 'nama': 'Bahasa Indonesia', 'nilai': 90, 'huruf': 'A'},
  ];

  double _calcAvg(List<Map<String, dynamic>> g) =>
      g.fold<int>(0, (s, row) => s + (row['nilai'] as int)) / g.length;

  Color _hurfColor(String h) {
    if (h.startsWith('A')) return const Color(0xFF15803D);
    if (h.startsWith('B')) return const Color(0xFF1D4ED8);
    if (h.startsWith('C')) return const Color(0xFFB45309);
    return const Color(0xFFB91C1C);
  }

  Color _hurfBg(String h) {
    if (h.startsWith('A')) return const Color(0xFFDCFCE7);
    if (h.startsWith('B')) return const Color(0xFFDBEAFE);
    if (h.startsWith('C')) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('Hasil Studi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 8),
        const Text('Riwayat performa akademik dan nilai', style: TextStyle(color: AppColors.gray600)),
        const SizedBox(height: 24),

        // Tab Bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              Expanded(child: _tabBtn('aktivitas', 'Aktivitas Belajar')),
              const SizedBox(width: 8),
              Expanded(child: _tabBtn('transkrip', 'Transkrip Nilai')),
              const SizedBox(width: 8),
              Expanded(child: _tabBtn('visualisasi', 'Visualisasi Data')),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tab Content
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: _buildTabContent(),
        ),
        ],
      ),
    );
  }

  Widget _tabBtn(String id, String label) {
    final active = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.gray600, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'aktivitas':
        return Column(
          children: [
            _buildGradeTable('Semester Ganjil 2025/2026', _ganjil),
            const SizedBox(height: 32),
            _buildGradeTable('Semester Genap 2025/2026', _genap),
          ],
        );
      case 'transkrip':
        return _buildTranscriptTab();
      case 'visualisasi':
        return _buildVisualisasiTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildGradeTable(String title, List<Map<String, dynamic>> grades) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 12),
        Table(
          border: TableBorder.all(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
          columnWidths: const {0: FixedColumnWidth(50), 1: FlexColumnWidth(3), 2: FixedColumnWidth(60), 3: FixedColumnWidth(90), 4: FlexColumnWidth(2)},
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
              children: ['No', 'Mata Pelajaran', 'KKM', 'Nilai Angka', 'Predikat']
                  .map((h) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))))
                  .toList(),
            ),
            ...grades.asMap().entries.map((e) {
              final g = e.value;
              return TableRow(
                decoration: BoxDecoration(color: e.key % 2 == 0 ? const Color(0xFFF9FAFB) : Colors.white),
                children: [
                  Padding(padding: const EdgeInsets.all(10), child: Text('${g['no']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.gray700))),
                  Padding(padding: const EdgeInsets.all(10), child: Text(g['nama'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.foreground))),
                  Padding(padding: const EdgeInsets.all(10), child: Text('${g['kkm']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.gray700))),
                  Padding(padding: const EdgeInsets.all(10), child: Text('${g['nilai']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  Padding(padding: const EdgeInsets.all(10), child: Text(g['predikat'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray700))),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rata-rata ${title.split(' ').take(2).join(' ')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              Text(_calcAvg(grades).toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Transkrip Nilai Akumulatif', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary))),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Unduh Transkrip Resmi (PDF)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
          columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(2.5), 3: FixedColumnWidth(70), 4: FixedColumnWidth(70)},
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
              children: ['Semester', 'Kode', 'Mata Pelajaran', 'Nilai', 'Huruf']
                  .map((h) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))))
                  .toList(),
            ),
            ..._transcript.asMap().entries.map((e) {
              final row = e.value;
              return TableRow(
                decoration: BoxDecoration(color: e.key % 2 == 0 ? const Color(0xFFF9FAFB) : Colors.white),
                children: [
                  Padding(padding: const EdgeInsets.all(10), child: Text(row['semester'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.foreground))),
                  Padding(padding: const EdgeInsets.all(10), child: Text(row['kode'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray700))),
                  Padding(padding: const EdgeInsets.all(10), child: Text(row['nama'] as String, style: const TextStyle(fontSize: 13, color: AppColors.foreground))),
                  Padding(padding: const EdgeInsets.all(10), child: Text('${row['nilai']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _hurfBg(row['huruf'] as String), borderRadius: BorderRadius.circular(6), border: Border.all(color: _hurfColor(row['huruf'] as String).withValues(alpha: 0.5))),
                        child: Text(row['huruf'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _hurfColor(row['huruf'] as String))),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rata-rata Kumulatif:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground)),
              Text('87.2', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.accent)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualisasiTab() {
    final gpaData = [
      FlSpot(0, 84), FlSpot(1, 85), FlSpot(2, 86), FlSpot(3, 86.4), FlSpot(4, 88.1),
    ];
    final semesterLabels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5'];

    final attendanceData = [
      ('Matematika', 95.0),
      ('Fisika', 92.0),
      ('B. Indonesia', 98.0),
      ('B. Inggris', 94.0),
      ('Kimia', 90.0),
      ('Biologi', 96.0),
    ];

    final pieData = [
      PieChartSectionData(value: 40, color: const Color(0xFF10B981), title: 'A\n40%', radius: 90, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: 35, color: const Color(0xFF3B82F6), title: 'B\n35%', radius: 90, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: 20, color: const Color(0xFFF59E0B), title: 'C\n20%', radius: 90, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: 5, color: const Color(0xFFB91C1C), title: 'D\n5%', radius: 90, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line Chart
        const Text('Tren Rata-rata Nilai Per Semester', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 16),
        Container(
          height: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: gpaData,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 5, color: AppColors.primary, strokeColor: Colors.white, strokeWidth: 2)),
                  belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(semesterLabels[v.toInt()], style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.gray500))),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              minY: 70, maxY: 100,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Bar Chart – Kehadiran
        const Text('Persentase Kehadiran Per Mata Pelajaran', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 16),
        Container(
          height: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
          child: BarChart(
            BarChartData(
              barGroups: attendanceData.asMap().entries.map((e) => BarChartGroupData(
                x: e.key,
                barRods: [BarChartRodData(toY: e.value.$2, color: const Color(0xFF10B981), width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
              )).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) {
                      if (v.toInt() < attendanceData.length) {
                        final label = attendanceData[v.toInt()].$1.replaceAll('Bahasa ', 'Bhs ');
                        return Padding(padding: const EdgeInsets.only(top: 6), child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray600)));
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.gray500)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              maxY: 100,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Pie Chart – Distribusi Nilai
        const Text('Distribusi Nilai', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 16),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: pieData,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pieLegend(const Color(0xFF10B981), 'A (90-100)'),
                  const SizedBox(height: 8),
                  _pieLegend(const Color(0xFF3B82F6), 'B (75-89)'),
                  const SizedBox(height: 8),
                  _pieLegend(const Color(0xFFF59E0B), 'C (60-74)'),
                  const SizedBox(height: 8),
                  _pieLegend(const Color(0xFFB91C1C), 'D (<60)'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pieLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
      ],
    );
  }
}
