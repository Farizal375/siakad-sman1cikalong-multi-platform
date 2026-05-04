// File: lib/features/guru/screens/monitoring_kehadiran.dart
// ===========================================
// MONITORING KEHADIRAN – Wali Kelas
// Connected to /dashboard/wali-kelas/kehadiran-mapel API
// Split panel: daftar siswa + detail view + bar chart
// ===========================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../providers/homeroom_provider.dart';

class MonitoringKehadiran extends ConsumerStatefulWidget {
  const MonitoringKehadiran({super.key});

  @override
  ConsumerState<MonitoringKehadiran> createState() =>
      _MonitoringKehadiranState();
}

class _MonitoringKehadiranState extends ConsumerState<MonitoringKehadiran> {
  String _searchTerm = '';
  int _selectedStudentIdx = 0;
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _subjectList = [];
  final Map<String, List<Map<String, dynamic>>> _studentSubjectsById = {};
  String? _selectedSubjectId;
  HomeroomContext? _homeroom;

  // Per-student subject attendance (loaded when student selected)
  List<Map<String, dynamic>> _subjectAttendance = [];

  @override
  void initState() {
    super.initState();
    _loadSubjectAttendance();
  }

  Future<void> _loadSubjectAttendance() async {
    try {
      final homeroom = await ref.read(homeroomContextProvider.future);
      if (!homeroom.hasClass || homeroom.masterKelasId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final response = await ApiService.getWaliKelasKehadiranMapel(
        semesterId: homeroom.semesterAktif?.id,
      );
      final payload = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};
      final subjects = _asMapList(payload['subjects']);
      final allStudents = _asMapList(payload['students']);

      _studentSubjectsById
        ..clear()
        ..addEntries(
          allStudents.map((s) {
            final id = (s['siswaId'] ?? s['id'])?.toString() ?? '';
            return MapEntry(id, _asMapList(s['subjects']));
          }),
        );

      if (!mounted) return;

      setState(() {
        _homeroom = homeroom;
        _subjectList = subjects;
        _selectedSubjectId = subjects.isNotEmpty
            ? subjects.first['subjectId']?.toString()
            : null;
        _students = subjects.isNotEmpty
            ? _studentsForSubject(subjects.first)
            : homeroom.students.map((s) => _studentFromHomeroom(s)).toList();
        _selectedStudentIdx = 0;
        _loading = false;
      });
      _buildSubjectAttendance();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    return (value as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _studentFromHomeroom(Map<String, dynamic> s) {
    return {
      'siswaId': s['id']?.toString() ?? '',
      'name': s['name']?.toString() ?? '-',
      'nisn': s['nisn']?.toString() ?? '-',
      'totalHadir': 0,
      'totalSakit': 0,
      'totalIzin': 0,
      'totalAlpa': 0,
      'totalPertemuan': 0,
      'rate': 0,
    };
  }

  Map<String, dynamic> _studentFromSubject(Map<String, dynamic> s) {
    final totalHadir = (s['totalHadir'] as num?)?.toInt() ?? 0;
    final totalSakit = (s['totalSakit'] as num?)?.toInt() ?? 0;
    final totalIzin = (s['totalIzin'] as num?)?.toInt() ?? 0;
    final totalAlpa = (s['totalAlpa'] as num?)?.toInt() ?? 0;
    final total =
        (s['totalPertemuan'] as num?)?.toInt() ??
        totalHadir + totalSakit + totalIzin + totalAlpa;
    return {
      'siswaId': (s['siswaId'] ?? s['id'])?.toString() ?? '',
      'name': s['name']?.toString() ?? '-',
      'nisn': s['nisn']?.toString() ?? '-',
      'totalHadir': totalHadir,
      'totalSakit': totalSakit,
      'totalIzin': totalIzin,
      'totalAlpa': totalAlpa,
      'totalPertemuan': total,
      'rate':
          (s['rate'] as num?)?.toInt() ??
          (total > 0 ? (totalHadir / total * 100).round() : 0),
      'attendance': s['attendance'] ?? const [],
    };
  }

  List<Map<String, dynamic>> _studentsForSubject(Map<String, dynamic> subject) {
    final subjectStudents = _asMapList(subject['students']);
    if (subjectStudents.isNotEmpty) {
      return subjectStudents.map(_studentFromSubject).toList();
    }
    return (_homeroom?.students ?? [])
        .map((s) => _studentFromHomeroom(s))
        .toList();
  }

  Map<String, dynamic> _selectedSubject() {
    return _subjectList.firstWhere(
      (s) => s['subjectId']?.toString() == _selectedSubjectId,
      orElse: () => _subjectList.isNotEmpty ? _subjectList.first : {},
    );
  }

  String _subjectLabel(Map<String, dynamic> subject, String className) {
    final subjectName = subject['subject']?.toString() ?? 'Mapel';
    final schedules = _asMapList(subject['schedules']);
    final days = <String>[];
    for (final schedule in schedules) {
      final day = (schedule['day'] ?? schedule['hari'])?.toString() ?? '';
      if (day.isNotEmpty && !days.contains(day)) days.add(day);
    }
    final dayLabel = days.isEmpty ? '-' : days.join(', ');
    return '$subjectName - $dayLabel ($className)';
  }

  String _selectedSubjectName() {
    final subject = _selectedSubject();
    return subject['subject']?.toString() ?? 'Mapel';
  }

  String _chartSubjectLabel(String subject) {
    return subject
        .replaceAll('Pendidikan ', 'P. ')
        .replaceAll('Bahasa ', 'B. ')
        .replaceAll('Matematika ', 'Mtk. ')
        .replaceAll('Indonesia', 'Ind.')
        .replaceAll('Peminatan', 'Pemin.')
        .replaceAll('Wajib', 'Wajib');
  }

  void _buildSubjectAttendance() {
    if (_students.isEmpty) {
      setState(() => _subjectAttendance = []);
      return;
    }
    final selected = _students[_selectedStudentIdx];
    final siswaId = selected['siswaId']?.toString() ?? '';
    final breakdown = _studentSubjectsById[siswaId] ?? [];
    final items = breakdown.isNotEmpty ? breakdown : [_selectedSubject()];

    setState(() {
      _subjectAttendance = items.where((item) => item.isNotEmpty).map((item) {
        final totalHadir = (item['totalHadir'] as num?)?.toInt() ?? 0;
        final totalSakit = (item['totalSakit'] as num?)?.toInt() ?? 0;
        final totalIzin = (item['totalIzin'] as num?)?.toInt() ?? 0;
        final totalAlpa = (item['totalAlpa'] as num?)?.toInt() ?? 0;
        final total =
            (item['totalPertemuan'] as num?)?.toInt() ??
            totalHadir + totalSakit + totalIzin + totalAlpa;
        return {
          'subject': item['subject']?.toString() ?? 'Mapel',
          'total': total,
          'hadir': totalHadir,
          'sakit': totalSakit,
          'izin': totalIzin,
          'alpa': totalAlpa,
          'pct':
              (item['rate'] as num?)?.toInt() ??
              (total > 0 ? (totalHadir / total * 100).round() : 0),
        };
      }).toList();
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
    final className = _homeroom?.kelas ?? 'Kelas Wali';

    final filtered = _students.where((s) {
      final q = _searchTerm.toLowerCase();
      return (s['name'] as String? ?? '').toLowerCase().contains(q) ||
          (s['nisn'] as String? ?? '').contains(q);
    }).toList();

    final selected =
        _students.isNotEmpty && _selectedStudentIdx < _students.length
        ? _students[_selectedStudentIdx]
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monitoring Kehadiran $className',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Pantau kehadiran siswa semester ${_homeroom?.semesterAktif?.label ?? '-'}',
            style: const TextStyle(color: AppColors.gray600),
          ),
          const SizedBox(height: 12),

          // Mata pelajaran filter
          if (_subjectList.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Mata Pelajaran',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    menuMaxHeight: 360,
                    initialValue: _selectedSubjectId,
                    items: _subjectList.map((subject) {
                      final label = _subjectLabel(subject, className);
                      return DropdownMenuItem(
                        value: subject['subjectId']?.toString(),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      final currentStudentId = _students.isNotEmpty
                          ? _students[_selectedStudentIdx]['siswaId']
                                ?.toString()
                          : null;
                      setState(() {
                        _selectedSubjectId = v;
                        _students = _studentsForSubject(_selectedSubject());
                        final retainedIndex = currentStudentId == null
                            ? -1
                            : _students.indexWhere(
                                (s) =>
                                    s['siswaId']?.toString() ==
                                    currentStudentId,
                              );
                        _selectedStudentIdx = retainedIndex >= 0
                            ? retainedIndex
                            : 0;
                      });
                      _buildSubjectAttendance();
                    },
                    decoration: InputDecoration(
                      hintText: 'Pilih mata pelajaran',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.gray300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.gray300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          if (_students.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppColors.gray300,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada data kehadiran',
                      style: TextStyle(color: AppColors.gray600),
                    ),
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
                            'Daftar Siswa',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _searchTerm = v),
                            decoration: InputDecoration(
                              hintText: 'Cari nama atau NIS...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.gray400,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.gray200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.gray200,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
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
                                  color: isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    if (isSelected)
                                      Container(
                                        width: 4,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    if (isSelected) const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s['name'] as String? ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                              color: AppColors.foreground,
                                            ),
                                          ),
                                          Text(
                                            'NISN: ${s['nisn'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.gray500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getAttendanceBg(rate),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$rate%',
                                        style: TextStyle(
                                          color: _getAttendanceColor(rate),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
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

                  // RIGHT – Detail View
                  if (selected != null)
                    Expanded(
                      child: Container(
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
                            // Student Header
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selected['name'] as String? ?? '-',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'NISN: ${selected['nisn'] ?? '-'}',
                                        style: const TextStyle(
                                          color: AppColors.gray600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getAttendanceBg(
                                      selected['rate'] as int,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Total Kehadiran',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.gray600,
                                        ),
                                      ),
                                      Text(
                                        '${selected['rate']}%',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: _getAttendanceColor(
                                            selected['rate'] as int,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32, color: Color(0xFFE5E7EB)),

                            // Bar Chart
                            if (_subjectAttendance.isNotEmpty) ...[
                              const Text(
                                'Perbandingan Semua Mapel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 240,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: BarChart(
                                  BarChartData(
                                    barGroups: _subjectAttendance
                                        .asMap()
                                        .entries
                                        .map((e) {
                                          final pct = (e.value['pct'] as num)
                                              .toInt();
                                          return BarChartGroupData(
                                            x: e.key,
                                            barRods: [
                                              BarChartRodData(
                                                toY: pct.toDouble(),
                                                color: _getBarColor(pct),
                                                width:
                                                    _subjectAttendance.length >
                                                        10
                                                    ? 18
                                                    : 28,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(4),
                                                    ),
                                              ),
                                            ],
                                          );
                                        })
                                        .toList(),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 48,
                                          getTitlesWidget: (value, _) {
                                            if (value.toInt() <
                                                _subjectAttendance.length) {
                                              final subjectName =
                                                  _subjectAttendance[value
                                                          .toInt()]['subject']
                                                      as String;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: SizedBox(
                                                  width: 70,
                                                  child: Text(
                                                    subjectName.isEmpty
                                                        ? '-'
                                                        : _chartSubjectLabel(
                                                            subjectName,
                                                          ),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.gray600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
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
                                          getTitlesWidget: (v, _) => Text(
                                            '${v.toInt()}%',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.gray500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (v) =>
                                          const FlLine(
                                            color: Color(0xFFE5E7EB),
                                            strokeWidth: 1,
                                          ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    maxY: 100,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLegend(
                                    const Color(0xFF10B981),
                                    'Baik (>90%)',
                                  ),
                                  const SizedBox(width: 20),
                                  _buildLegend(
                                    const Color(0xFFF59E0B),
                                    'Cukup (75-90%)',
                                  ),
                                  const SizedBox(width: 20),
                                  _buildLegend(
                                    const Color(0xFFB91C1C),
                                    'Perlu Perhatian (<75%)',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Detail Table
                            Text(
                              'Rincian Kehadiran ${_selectedSubjectName()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontSize: 16,
                              ),
                            ),
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
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.gray700),
        ),
      ],
    );
  }

  Widget _buildDetailTable(Map<String, dynamic> student) {
    final totalHadir = (student['totalHadir'] as num?)?.toInt() ?? 0;
    final totalSakit = (student['totalSakit'] as num?)?.toInt() ?? 0;
    final totalIzin = (student['totalIzin'] as num?)?.toInt() ?? 0;
    final totalAlpa = (student['totalAlpa'] as num?)?.toInt() ?? 0;
    final total =
        student['totalPertemuan'] ??
        (totalHadir + totalSakit + totalIzin + totalAlpa);

    return Table(
      border: TableBorder.all(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1.4),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          children: ['Total Jam', 'Hadir', 'Sakit', 'Izin', 'Alpa']
              .map(
                (h) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Text(
                    h,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
          children: [
            _cell('$total Jam'),
            _statusCell(
              totalHadir,
              const Color(0xFF059669),
              const Color(0xFFDCFCE7),
            ),
            _statusCell(
              totalSakit,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            _statusCell(
              totalIzin,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _statusCell(
              totalAlpa,
              const Color(0xFFB91C1C),
              const Color(0xFFFEF2F2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: AppColors.foreground,
        ),
      ),
    );
  }

  Widget _statusCell(int value, Color textColor, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
