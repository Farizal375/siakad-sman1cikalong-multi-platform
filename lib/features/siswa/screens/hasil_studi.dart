// File: lib/features/siswa/screens/hasil_studi.dart
// ===========================================
// HASIL STUDI – Siswa
// Connected to /nilai/siswa/:siswaId API
// 3 Tab: Aktivitas Belajar | Transkrip Nilai | Visualisasi Data
// ===========================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class HasilStudi extends ConsumerStatefulWidget {
  const HasilStudi({super.key});

  @override
  ConsumerState<HasilStudi> createState() => _HasilStudiState();
}

class _HasilStudiState extends ConsumerState<HasilStudi> {
  String _activeTab = 'aktivitas';
  bool _loading = true;

  // Will be populated from API — grouped by semester
  final Map<String, List<Map<String, dynamic>>> _gradesBySemester = {};
  List<Map<String, dynamic>> _allGrades = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      final response = await ApiService.getNilaiSiswa(userId);
      final List data = response['data'] ?? [];
      final grades = data.cast<Map<String, dynamic>>();

      // Group by semester
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final g in grades) {
        final semKey = '${g['semester'] ?? 'Lainnya'} ${g['tahunAjaran'] ?? ''}';
        grouped.putIfAbsent(semKey, () => []);
        grouped[semKey]!.add(g);
      }

      if (mounted) {
        setState(() {
          _allGrades = grades;
          _gradesBySemester.clear();
          _gradesBySemester.addAll(grouped);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getPredikat(num? nilai) {
    if (nilai == null) return '-';
    if (nilai >= 90) return 'Sangat Baik';
    if (nilai >= 80) return 'Baik';
    if (nilai >= 70) return 'Cukup';
    if (nilai >= 60) return 'Kurang';
    return 'Sangat Kurang';
  }

  String _getHuruf(num? nilai) {
    if (nilai == null) return '-';
    if (nilai >= 90) return 'A';
    if (nilai >= 85) return 'A-';
    if (nilai >= 80) return 'B+';
    if (nilai >= 75) return 'B';
    if (nilai >= 70) return 'B-';
    if (nilai >= 65) return 'C+';
    if (nilai >= 60) return 'C';
    return 'D';
  }

  double _calcAvg(List<Map<String, dynamic>> g) {
    if (g.isEmpty) return 0;
    return g.fold<double>(0, (s, row) => s + ((row['nilaiAkhir'] as num?)?.toDouble() ?? 0)) / g.length;
  }

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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
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

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: _allGrades.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.school_outlined, size: 64, color: AppColors.gray300),
                        SizedBox(height: 16),
                        Text('Belum ada data nilai', style: TextStyle(color: AppColors.gray600, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )
              : _buildTabContent(),
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
        decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.gray600, fontSize: 14))),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'aktivitas':
        return Column(
          children: _gradesBySemester.entries.map((entry) {
            final enriched = entry.value.asMap().entries.map((e) => {
              'no': e.key + 1,
              'nama': e.value['mataPelajaran'] ?? '-',
              'kkm': e.value['kkm'] ?? 75,
              'nilai': (e.value['nilaiAkhir'] as num?)?.round() ?? 0,
              'predikat': _getPredikat(e.value['nilaiAkhir'] as num?),
            }).toList();
            return Column(
              children: [
                _buildGradeTable(entry.key, enriched),
                const SizedBox(height: 32),
              ],
            );
          }).toList(),
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
              const Text('Rata-rata', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              Text(
                _calcAvg(_gradesBySemester[title] ?? []).toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptTab() {
    final transcriptData = _allGrades.asMap().entries.map((e) => {
      'semester': e.value['semester'] ?? '-',
      'kode': (e.value['mataPelajaranId'] ?? '').toString().substring(0, (e.value['mataPelajaranId'] ?? '').toString().length.clamp(0, 6)),
      'nama': e.value['mataPelajaran'] ?? '-',
      'nilai': (e.value['nilaiAkhir'] as num?)?.round() ?? 0,
      'huruf': _getHuruf(e.value['nilaiAkhir'] as num?),
    }).toList();

    final kumulatif = _allGrades.isNotEmpty
        ? _allGrades.fold<double>(0, (s, g) => s + ((g['nilaiAkhir'] as num?)?.toDouble() ?? 0)) / _allGrades.length
        : 0.0;

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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontWeight: FontWeight.w600)),
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
            ...transcriptData.asMap().entries.map((e) {
              final row = e.value;
              final huruf = row['huruf'] as String;
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
                        decoration: BoxDecoration(color: _hurfBg(huruf), borderRadius: BorderRadius.circular(6), border: Border.all(color: _hurfColor(huruf).withValues(alpha: 0.5))),
                        child: Text(huruf, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _hurfColor(huruf))),
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
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent, width: 2)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rata-rata Kumulatif:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground)),
              Text(kumulatif.toStringAsFixed(1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.accent)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualisasiTab() {
    // Build GPA trend from grouped semesters
    final semesterKeys = _gradesBySemester.keys.toList();
    final gpaData = <FlSpot>[];
    for (int i = 0; i < semesterKeys.length; i++) {
      gpaData.add(FlSpot(i.toDouble(), _calcAvg(_gradesBySemester[semesterKeys[i]]!)));
    }
    final semesterLabels = semesterKeys.map((k) => k.length > 8 ? k.substring(0, 8) : k).toList();

    // Grade distribution
    int countA = 0, countB = 0, countC = 0, countD = 0;
    for (final g in _allGrades) {
      final v = (g['nilaiAkhir'] as num?)?.toDouble() ?? 0;
      if (v >= 90) { countA++; }
      else if (v >= 75) { countB++; }
      else if (v >= 60) { countC++; }
      else { countD++; }
    }
    final total = _allGrades.length;
    final pA = total > 0 ? countA / total * 100 : 0.0;
    final pB = total > 0 ? countB / total * 100 : 0.0;
    final pC = total > 0 ? countC / total * 100 : 0.0;
    final pD = total > 0 ? countD / total * 100 : 0.0;

    final pieData = [
      PieChartSectionData(value: pA, color: const Color(0xFF10B981), title: 'A\n${pA.round()}%', radius: 90, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: pB, color: const Color(0xFF3B82F6), title: 'B\n${pB.round()}%', radius: 90, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: pC, color: const Color(0xFFF59E0B), title: 'C\n${pC.round()}%', radius: 90, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      PieChartSectionData(value: pD, color: const Color(0xFFB91C1C), title: 'D\n${pD.round()}%', radius: 90, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line Chart
        const Text('Tren Rata-rata Nilai Per Semester', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 16),
        if (gpaData.isNotEmpty)
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
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= 0 && idx < semesterLabels.length) {
                          return Text(semesterLabels[idx], style: const TextStyle(fontSize: 11, color: AppColors.gray600));
                        }
                        return const SizedBox();
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.gray500)))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                minY: 50, maxY: 100,
              ),
            ),
          )
        else
          Container(
            height: 200,
            alignment: Alignment.center,
            child: const Text('Data belum cukup untuk grafik', style: TextStyle(color: AppColors.gray500)),
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
              Expanded(child: PieChart(PieChartData(sections: pieData, centerSpaceRadius: 40, sectionsSpace: 2))),
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
