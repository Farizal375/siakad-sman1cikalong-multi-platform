// File: lib/features/guru/screens/monitoring_kehadiran.dart
// ===========================================
// MONITORING KEHADIRAN – Wali Kelas
// Connected to /kehadiran/rekap/:jadwalId API
// Split panel: daftar siswa + detail view + bar chart
// ===========================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

class MonitoringKehadiran extends StatefulWidget {
  const MonitoringKehadiran({super.key});

  @override
  State<MonitoringKehadiran> createState() => _MonitoringKehadiranState();
}

class _MonitoringKehadiranState extends State<MonitoringKehadiran> {
  String _searchTerm = '';
  int _selectedStudentIdx = 0;
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _jadwalList = [];
  String? _selectedJadwalId;

  // Per-student subject attendance (loaded when student selected)
  List<Map<String, dynamic>> _subjectAttendance = [];

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    try {
      final response = await ApiService.getJadwal();
      final List data = response['data'] ?? [];
      final jadwalList = data.cast<Map<String, dynamic>>();
      if (mounted && jadwalList.isNotEmpty) {
        setState(() {
          _jadwalList = jadwalList;
          _selectedJadwalId = jadwalList.first['id']?.toString();
        });
        _loadRekap();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRekap() async {
    if (_selectedJadwalId == null) return;
    setState(() => _loading = true);
    try {
      final response = await ApiService.getRekapKehadiran(_selectedJadwalId!);
      final List data = response['data'] ?? [];
      final students = data.cast<Map<String, dynamic>>();

      // Compute rate for each student
      for (final s in students) {
        final totalHadir = (s['totalHadir'] as num?)?.toInt() ?? 0;
        final totalSakit = (s['totalSakit'] as num?)?.toInt() ?? 0;
        final totalIzin = (s['totalIzin'] as num?)?.toInt() ?? 0;
        final totalAlpa = (s['totalAlpa'] as num?)?.toInt() ?? 0;
        final total = totalHadir + totalSakit + totalIzin + totalAlpa;
        s['rate'] = total > 0 ? (totalHadir / total * 100).round() : 0;
        s['totalPertemuan'] = total;
      }

      if (mounted) {
        setState(() {
          _students = students;
          _selectedStudentIdx = 0;
          _loading = false;
        });
        _buildSubjectAttendance();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _buildSubjectAttendance() {
    // For simplicity, show the selected jadwal's attendance summary
    // In a real app you'd aggregate multiple jadwal per student
    if (_students.isEmpty) return;
    final selected = _students[_selectedStudentIdx];
    final totalHadir = (selected['totalHadir'] as num?)?.toInt() ?? 0;
    final totalSakit = (selected['totalSakit'] as num?)?.toInt() ?? 0;
    final totalIzin = (selected['totalIzin'] as num?)?.toInt() ?? 0;
    final totalAlpa = (selected['totalAlpa'] as num?)?.toInt() ?? 0;
    final total = totalHadir + totalSakit + totalIzin + totalAlpa;

    // Get the jadwal info for subject name
    final jadwal = _jadwalList.firstWhere((j) => j['id']?.toString() == _selectedJadwalId, orElse: () => {});
    final mapelName = jadwal['mataPelajaran'] ?? jadwal['mapel'] ?? 'Mapel';

    setState(() {
      _subjectAttendance = [
        {
          'subject': mapelName,
          'total': total,
          'hadir': totalHadir,
          'sakit': totalSakit,
          'izin': totalIzin,
          'alpa': totalAlpa,
          'pct': total > 0 ? (totalHadir / total * 100).round() : 0,
        },
      ];
    });
  }

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
    if (_loading) return const Center(child: CircularProgressIndicator());

    final filtered = _students.where((s) {
      final q = _searchTerm.toLowerCase();
      return (s['name'] as String? ?? '').toLowerCase().contains(q) || (s['nisn'] as String? ?? '').contains(q);
    }).toList();

    final selected = _students.isNotEmpty && _selectedStudentIdx < _students.length ? _students[_selectedStudentIdx] : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monitoring Kehadiran', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const Text('Pantau kehadiran siswa di kelas Anda', style: TextStyle(color: AppColors.gray600)),
          const SizedBox(height: 12),

          // Jadwal filter
          if (_jadwalList.isNotEmpty)
            SizedBox(
              width: 400,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedJadwalId,
                items: _jadwalList.map((j) {
                  final label = '${j['mataPelajaran'] ?? j['mapel'] ?? 'Mapel'} - ${j['hari'] ?? ''} (${j['kelas'] ?? j['masterKelas'] ?? ''})';
                  return DropdownMenuItem(value: j['id']?.toString(), child: Text(label, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) {
                  setState(() => _selectedJadwalId = v);
                  _loadRekap();
                },
                decoration: InputDecoration(
                  labelText: 'Pilih Jadwal',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          const SizedBox(height: 20),

          if (_students.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 64, color: AppColors.gray300),
                    SizedBox(height: 16),
                    Text('Belum ada data kehadiran', style: TextStyle(color: AppColors.gray600)),
                  ],
                ),
              ),
            )
          else
          // Split Panel
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT – Student List
                SizedBox(
                  width: 300,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Daftar Siswa', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                        ...filtered.asMap().entries.map((e) {
                          final s = e.value;
                          final idx = _students.indexOf(s);
                          final isSelected = idx == _selectedStudentIdx;
                          final rate = (s['rate'] as num?)?.toInt() ?? 0;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedStudentIdx = idx);
                              _buildSubjectAttendance();
                            },
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
                                  if (isSelected) Container(width: 4, height: 36, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
                                  if (isSelected) const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s['name'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.foreground)),
                                        Text('NISN: ${s['nisn'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: _getAttendanceBg(rate), borderRadius: BorderRadius.circular(8)),
                                    child: Text('$rate%', style: TextStyle(color: _getAttendanceColor(rate), fontWeight: FontWeight.w700, fontSize: 12)),
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

                // RIGHT – Detail View
                if (selected != null)
                Expanded(
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
                        // Student Header
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(selected['name'] as String? ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  Text('NISN: ${selected['nisn'] ?? '-'}', style: const TextStyle(color: AppColors.gray600)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: _getAttendanceBg(selected['rate'] as int), borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  const Text('Total Kehadiran', style: TextStyle(fontSize: 12, color: AppColors.gray600)),
                                  Text('${selected['rate']}%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _getAttendanceColor(selected['rate'] as int))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32, color: Color(0xFFE5E7EB)),

                        // Bar Chart
                        if (_subjectAttendance.isNotEmpty) ...[
                          const Text('Analisis Kehadiran', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 16)),
                          const SizedBox(height: 16),
                          Container(
                            height: 240,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                            child: BarChart(
                              BarChartData(
                                barGroups: _subjectAttendance.asMap().entries.map((e) {
                                  final pct = (e.value['pct'] as num).toInt();
                                  return BarChartGroupData(
                                    x: e.key,
                                    barRods: [BarChartRodData(toY: pct.toDouble(), color: _getBarColor(pct), width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
                                  );
                                }).toList(),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true, reservedSize: 40,
                                      getTitlesWidget: (value, _) {
                                        if (value.toInt() < _subjectAttendance.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(_subjectAttendance[value.toInt()]['subject'] as String, style: const TextStyle(fontSize: 10, color: AppColors.gray600), textAlign: TextAlign.center),
                                          );
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
                          const SizedBox(height: 8),
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
                        ],

                        // Detail Table
                        const Text('Rincian Kehadiran', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 16)),
                        const SizedBox(height: 12),
                        _buildDetailTable(selected),
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

  Widget _buildDetailTable(Map<String, dynamic> student) {
    final totalHadir = (student['totalHadir'] as num?)?.toInt() ?? 0;
    final totalSakit = (student['totalSakit'] as num?)?.toInt() ?? 0;
    final totalIzin = (student['totalIzin'] as num?)?.toInt() ?? 0;
    final totalAlpa = (student['totalAlpa'] as num?)?.toInt() ?? 0;
    final total = student['totalPertemuan'] ?? (totalHadir + totalSakit + totalIzin + totalAlpa);

    return Table(
      border: TableBorder.all(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1.4),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
          children: ['Total Jam', 'Hadir', 'Sakit', 'Izin', 'Alpa']
              .map((h) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))))
              .toList(),
        ),
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
          children: [
            _cell('$total Jam'),
            _statusCell(totalHadir, const Color(0xFF059669), const Color(0xFFDCFCE7)),
            _statusCell(totalSakit, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
            _statusCell(totalIzin, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
            _statusCell(totalAlpa, const Color(0xFFB91C1C), const Color(0xFFFEF2F2)),
          ],
        ),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(text, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: AppColors.foreground)));
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
