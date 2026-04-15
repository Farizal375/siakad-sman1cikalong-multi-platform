// File: lib/features/guru/screens/monitoring_kehadiran.dart
// ===========================================
// MONITORING KEHADIRAN – Wali Kelas
// Translated from MonitoringKehadiran.tsx
// Split panel: daftar siswa + detail view + bar chart
// ===========================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';

class MonitoringKehadiran extends StatefulWidget {
  const MonitoringKehadiran({super.key});

  @override
  State<MonitoringKehadiran> createState() => _MonitoringKehadiranState();
}

class _MonitoringKehadiranState extends State<MonitoringKehadiran> {
  String _searchTerm = '';
  int _selectedStudentId = 1;
  final _searchCtrl = TextEditingController();

  static const _students = [
    {'id': 1, 'nama': 'Ahmad Fauzi', 'nis': '2023001', 'rate': 82},
    {'id': 2, 'nama': 'Siti Nurhaliza', 'nis': '2023002', 'rate': 88},
    {'id': 3, 'nama': 'Budi Santoso', 'nis': '2023003', 'rate': 65},
    {'id': 4, 'nama': 'Dewi Lestari', 'nis': '2023004', 'rate': 95},
    {'id': 5, 'nama': 'Eko Prasetyo', 'nis': '2023005', 'rate': 78},
    {'id': 6, 'nama': 'Fitri Handayani', 'nis': '2023006', 'rate': 85},
    {'id': 7, 'nama': 'Gunawan Wibowo', 'nis': '2023007', 'rate': 68},
    {'id': 8, 'nama': 'Hesti Rahayu', 'nis': '2023008', 'rate': 91},
    {'id': 9, 'nama': 'Indra Kusuma', 'nis': '2023009', 'rate': 72},
    {'id': 10, 'nama': 'Joko Widodo', 'nis': '2023010', 'rate': 89},
  ];

  static const _subjectAttendance = [
    {'subject': 'Matematika', 'total': 32, 'hadir': 30, 'sakit': 2, 'izin': 0, 'alpa': 0, 'pct': 94},
    {'subject': 'Fisika', 'total': 30, 'hadir': 18, 'sakit': 0, 'izin': 0, 'alpa': 12, 'pct': 60},
    {'subject': 'B. Indonesia', 'total': 28, 'hadir': 26, 'sakit': 1, 'izin': 1, 'alpa': 0, 'pct': 93},
    {'subject': 'B. Inggris', 'total': 28, 'hadir': 25, 'sakit': 1, 'izin': 2, 'alpa': 0, 'pct': 89},
    {'subject': 'Kimia', 'total': 30, 'hadir': 24, 'sakit': 2, 'izin': 1, 'alpa': 3, 'pct': 80},
    {'subject': 'Sejarah', 'total': 24, 'hadir': 16, 'sakit': 0, 'izin': 2, 'alpa': 6, 'pct': 67},
  ];

  Color _getAttendanceColor(int rate) {
    if (rate > 90) return const Color(0xFF059669);
    if (rate >= 75) return const Color(0xFFD97706);
    return const Color(0xFFB91C1C);
  }

  Color _getAttendanceBg(int rate) {
    if (rate > 90) return const Color(0xFFECFDF5);
    if (rate >= 75) return const Color(0xFFFFFBEB);
    return const Color(0xFFFEF2F2);
  }

  Color _getBarColor(int rate) {
    if (rate > 90) return const Color(0xFF10B981);
    if (rate >= 75) return const Color(0xFFF59E0B);
    return const Color(0xFFB91C1C);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((s) {
      final q = _searchTerm.toLowerCase();
      return (s['nama'] as String).toLowerCase().contains(q) || (s['nis'] as String).contains(q);
    }).toList();

    final selected = _students.firstWhere((s) => s['id'] == _selectedStudentId);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monitoring Kehadiran', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const Text('Kelas XI-1 • Semester Genap 2025/2026', style: TextStyle(color: AppColors.gray600)),
        const SizedBox(height: 20),

        // Split Panel
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT – Student List (30%)
              SizedBox(
                width: 300,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daftar Siswa Kelas XI-1', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchTerm = v),
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau NIS...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
                          filled: true, fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...filtered.map((s) {
                        final isSelected = s['id'] == _selectedStudentId;
                        final rate = s['rate'] as int;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStudentId = s['id'] as int),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
                            ),
                            child: Row(
                              children: [
                                if (isSelected)
                                  Container(width: 4, height: 36, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
                                if (isSelected) const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s['nama'] as String, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.foreground)),
                                      Text('NISN: ${s['nis']}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getAttendanceBg(rate),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$rate%',
                                    style: TextStyle(color: _getAttendanceColor(rate), fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // RIGHT – Detail View (70%)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selected['nama'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                Text('NISN: ${selected['nis']}', style: const TextStyle(color: AppColors.gray600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getAttendanceBg(selected['rate'] as int),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text('Total Kehadiran', style: TextStyle(fontSize: 12, color: AppColors.gray600)),
                                Text(
                                  '${selected['rate']}%',
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _getAttendanceColor(selected['rate'] as int)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.print, size: 16),
                            label: const Text('Cetak Laporan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32, color: Color(0xFFE5E7EB)),

                      // Bar Chart
                      const Text('Analisis Kehadiran Per Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 16)),
                      const SizedBox(height: 16),
                      Container(
                        height: 240,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                        child: BarChart(
                          BarChartData(
                            barGroups: _subjectAttendance.asMap().entries.map((e) {
                              final pct = e.value['pct'] as int;
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: pct.toDouble(),
                                    color: _getBarColor(pct),
                                    width: 28,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, _) {
                                    final labels = _subjectAttendance.map((s) => s['subject'] as String).toList();
                                    if (value.toInt() < labels.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          labels[value.toInt()].replaceAll('B. ', '').replaceAll('Bahasa ', 'Bhs '),
                                          style: const TextStyle(fontSize: 10, color: AppColors.gray600),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.gray500)),
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
                            ),
                            borderData: FlBorderData(show: false),
                            maxY: 100,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegend(const Color(0xFF10B981), 'Baik (>90%)'),
                          const SizedBox(width: 20),
                          _buildLegend(const Color(0xFFF59E0B), 'Cukup (75-90%)'),
                          const SizedBox(width: 20),
                          _buildLegend(const Color(0xFFB91C1C), 'Perlu Perhatian (<75%)'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Detailed Table
                      const Text('Rincian Kehadiran Berdasarkan Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 16)),
                      const SizedBox(height: 12),
                      _buildDetailTable(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray700)),
      ],
    );
  }

  Widget _buildDetailTable() {
    return Table(
      border: TableBorder.all(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
        6: FlexColumnWidth(1.4),
      },
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
          children: ['Mata Pelajaran', 'Total Jam', 'Hadir', 'Sakit', 'Izin', 'Alpa', '% Kehadiran']
              .map((h) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                  ))
              .toList(),
        ),
        ..._subjectAttendance.asMap().entries.map((e) {
          final row = e.value;
          final pct = row['pct'] as int;
          final isEven = e.key % 2 == 0;
          return TableRow(
            decoration: BoxDecoration(color: isEven ? const Color(0xFFF9FAFB) : Colors.white),
            children: [
              _cell(row['subject'] as String, bold: true),
              _cell('${row['total']} Jam'),
              _statusCell(row['hadir'] as int, const Color(0xFF059669), const Color(0xFFDCFCE7)),
              _statusCell(row['sakit'] as int, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
              _statusCell(row['izin'] as int, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
              _statusCell(row['alpa'] as int, const Color(0xFFB91C1C), const Color(0xFFFEF2F2)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAttendanceBg(pct),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(color: _getAttendanceColor(pct), fontWeight: FontWeight.w700, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: AppColors.foreground)),
    );
  }

  Widget _statusCell(int value, Color textColor, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
          child: Text('$value', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }
}
