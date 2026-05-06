// File: lib/features/siswa/screens/riwayat_kehadiran.dart
// ===========================================
// STUDENT ATTENDANCE HISTORY - Web
// Matches mobile content and backend flow:
// semester filter + subject summary + history + QR scan.
// ===========================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/student_providers.dart';
import 'qr_scanner.dart';

class RiwayatKehadiran extends ConsumerStatefulWidget {
  const RiwayatKehadiran({super.key});

  @override
  ConsumerState<RiwayatKehadiran> createState() => _RiwayatKehadiranState();
}

class _RiwayatKehadiranState extends ConsumerState<RiwayatKehadiran>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _semesterLabel = 'Memuat...';
  String? _selectedSemesterId;
  List<Map<String, dynamic>> _semesters = [];
  List<Map<String, dynamic>> _allMeetings = [];
  Map<String, Map<String, dynamic>> _groupedMapel = {};
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      await _loadSemesters();

      String? kelasId;
      try {
        final dashboard = await ref.read(studentDashboardProvider.future);
        kelasId = dashboard['kelasId'] as String?;
      } catch (_) {}

      final grouped = <String, Map<String, dynamic>>{};
      if (kelasId != null && kelasId.trim().isNotEmpty) {
        try {
          final jadwalRes = await ApiService.getJadwal(kelasId: kelasId);
          final List jadwalData = jadwalRes['data'] ?? [];
          for (final item in jadwalData) {
            final schedule = item as Map<String, dynamic>;
            final subject = schedule['subject'] as String? ?? '';
            final teacher = schedule['teacher'] as String? ?? '-';
            if (subject.isNotEmpty && !grouped.containsKey(subject)) {
              grouped[subject] = {
                'mapel': subject,
                'guru': teacher,
                'meetings': <Map<String, dynamic>>[],
                'totalHadir': 0,
                'totalAll': 0,
              };
            }
          }
        } catch (_) {}
      }

      final response = await ApiService.getKehadiranSiswa(
        userId,
        _selectedSemesterId,
      );
      final List data = response['data'] ?? [];
      final meetings = data.cast<Map<String, dynamic>>();

      for (final meeting in meetings) {
        final mapel = meeting['mapel'] as String? ?? '-';
        final guru = meeting['guru'] as String? ?? '-';

        grouped.putIfAbsent(
          mapel,
          () => {
            'mapel': mapel,
            'guru': guru,
            'meetings': <Map<String, dynamic>>[],
            'totalHadir': 0,
            'totalAll': 0,
          },
        );

        grouped[mapel]!['meetings'].add(meeting);
        grouped[mapel]!['totalAll'] = (grouped[mapel]!['totalAll'] as int) + 1;
        if ((meeting['status'] as String? ?? '').toUpperCase() == 'HADIR') {
          grouped[mapel]!['totalHadir'] =
              (grouped[mapel]!['totalHadir'] as int) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _allMeetings = meetings;
          _groupedMapel = grouped;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSemesters() async {
    try {
      if (_semesters.isEmpty) {
        final semRes = await ApiService.getSemester();
        final List sems = semRes['data'] ?? [];
        _semesters = sems.cast<Map<String, dynamic>>();
      }

      if (_selectedSemesterId == null && _semesters.isNotEmpty) {
        final active = _semesters.firstWhere(
          (s) => s['isActive'] == true,
          orElse: () => _semesters.first,
        );
        _selectedSemesterId = active['id'] as String?;
      }

      final selected = _semesters.where((s) => s['id'] == _selectedSemesterId);
      if (selected.isNotEmpty) {
        final semester = selected.first;
        _semesterLabel = '${semester['name']} - ${semester['academicYear']}';
      } else {
        _semesterLabel = 'Semester Aktif';
      }
    } catch (_) {
      _semesterLabel = 'Semester Aktif';
    }
  }

  int _count(String status) => _allMeetings
      .where((m) => (m['status'] as String? ?? '').toUpperCase() == status)
      .length;

  ({Color bg, Color text, Color border, IconData icon}) _statusStyle(
    String status,
  ) {
    switch (status.toUpperCase()) {
      case 'HADIR':
        return (
          bg: const Color(0xFFDCFCE7),
          text: const Color(0xFF15803D),
          border: const Color(0xFF86EFAC),
          icon: Icons.check_circle_outline,
        );
      case 'SAKIT':
        return (
          bg: const Color(0xFFFEF3C7),
          text: const Color(0xFFB45309),
          border: const Color(0xFFFDE68A),
          icon: Icons.sick_outlined,
        );
      case 'IZIN':
        return (
          bg: const Color(0xFFDBEAFE),
          text: const Color(0xFF1D4ED8),
          border: const Color(0xFFBFDBFE),
          icon: Icons.assignment_outlined,
        );
      case 'ALPA':
        return (
          bg: const Color(0xFFFEE2E2),
          text: const Color(0xFFB91C1C),
          border: const Color(0xFFFCA5A5),
          icon: Icons.cancel_outlined,
        );
      default:
        return (
          bg: const Color(0xFFF3F4F6),
          text: AppColors.gray600,
          border: const Color(0xFFE5E7EB),
          icon: Icons.help_outline,
        );
    }
  }

  IconData _mapelIcon(String mapel) {
    final lower = mapel.toLowerCase();
    if (lower.contains('matematika')) return Icons.functions;
    if (lower.contains('fisika')) return Icons.science_outlined;
    if (lower.contains('biologi')) return Icons.biotech_outlined;
    if (lower.contains('kimia')) return Icons.science;
    if (lower.contains('inggris')) return Icons.language;
    if (lower.contains('indonesia')) return Icons.menu_book_outlined;
    if (lower.contains('sejarah')) return Icons.history_edu;
    if (lower.contains('agama')) return Icons.mosque_outlined;
    if (lower.contains('olahraga') || lower.contains('penjas')) {
      return Icons.sports_soccer;
    }
    if (lower.contains('seni')) return Icons.palette_outlined;
    if (lower.contains('ekonomi')) return Icons.account_balance_outlined;
    if (lower.contains('geografi')) return Icons.public;
    if (lower.contains('informatika') || lower.contains('komputer')) {
      return Icons.computer;
    }
    return Icons.book_outlined;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inDays == 0) return 'Hari ini';
      if (diff.inDays == 1) return 'Kemarin';
      if (diff.inDays < 30) return '${diff.inDays} hari yang lalu';
      if (diff.inDays < 365) {
        return '${(diff.inDays / 30).floor()} bulan yang lalu';
      }
      return '${(diff.inDays / 365).floor()} tahun yang lalu';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next && next != null) {
        _selectedSemesterId = null;
        _load();
      }
    });

    final hadir = _count('HADIR');
    final sakit = _count('SAKIT');
    final izin = _count('IZIN');
    final alpa = _count('ALPA');

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Presensi',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Rekap kehadiran dan materi pembelajaran per semester',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                _semesterPicker(),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openQRScanner(context),
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Scan QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _summaryCard(
                  '$hadir',
                  'Hadir',
                  const Color(0xFF16A34A),
                  Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  '$sakit',
                  'Sakit',
                  const Color(0xFFD97706),
                  Icons.sick_outlined,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  '$izin',
                  'Izin',
                  const Color(0xFF2563EB),
                  Icons.assignment_outlined,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  '$alpa',
                  'Alpa',
                  const Color(0xFFDC2626),
                  Icons.cancel_outlined,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.gray500,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book, size: 16),
                        const SizedBox(width: 8),
                        Text('Mata Pelajaran (${_groupedMapel.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 16),
                        const SizedBox(width: 8),
                        Text('Riwayat (${_allMeetings.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? _buildSkeleton()
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _groupedMapel.isEmpty
                            ? _emptyList('Belum ada data mata pelajaran')
                            : _buildMapelList(),
                        _allMeetings.isEmpty
                            ? _emptyList('Belum ada riwayat kehadiran')
                            : _buildHistoryList(),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _semesterPicker() {
    final hasSelected = _semesters.any((s) => s['id'] == _selectedSemesterId);

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: _semesters.isEmpty
          ? Text(
              _semesterLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: hasSelected ? _selectedSemesterId : null,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.gray400,
                ),
                isDense: true,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
                items: _semesters.map((s) {
                  final label = '${s['name']} - ${s['academicYear']}';
                  return DropdownMenuItem(
                    value: s['id'] as String,
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null && value != _selectedSemesterId) {
                    setState(() => _selectedSemesterId = value);
                    _load();
                  }
                },
              ),
            ),
    );
  }

  Widget _summaryCard(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapelList() {
    final entries = _groupedMapel.values.toList()
      ..sort((a, b) => (a['mapel'] as String).compareTo(b['mapel'] as String));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildMapelCard(entries[index]),
    );
  }

  Widget _buildMapelCard(Map<String, dynamic> data) {
    final mapel = data['mapel'] as String;
    final guru = data['guru'] as String;
    final meetings = data['meetings'] as List<Map<String, dynamic>>;
    final totalHadir = data['totalHadir'] as int;
    final totalAll = data['totalAll'] as int;
    final percentage = totalAll > 0 ? totalHadir / totalAll : 0.0;
    final pctString = (percentage * 100).toStringAsFixed(0);

    Color progressColor = AppColors.primary;
    if (percentage < 0.75) progressColor = const Color(0xFFD97706);
    if (percentage < 0.5) progressColor = const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showMapelDetail(data),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _mapelIcon(mapel),
                    size: 24,
                    color: progressColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mapel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 13,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              guru,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 6,
                                backgroundColor: AppColors.gray100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$pctString%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: progressColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '${meetings.length} pertemuan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, color: AppColors.gray300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final meetings = [..._allMeetings]
      ..sort(
        (a, b) => (b['tanggal'] ?? '').toString().compareTo(
          (a['tanggal'] ?? '').toString(),
        ),
      );

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: meetings.length,
      itemBuilder: (context, index) => _buildRiwayatCard(meetings[index]),
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> data) {
    final mapel = data['mapel'] as String? ?? '-';
    final pertemuanKe = data['pertemuanKe'] as int? ?? 1;
    final tanggal = data['tanggal'] as String? ?? '';
    final status = (data['status'] as String? ?? 'HADIR').toUpperCase();
    final topik = data['topik'] as String? ?? '-';
    final keterangan = data['keterangan'] as String? ?? '';
    final style = _statusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(style.icon, size: 23, color: style.text),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        mapel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Pertemuan $pertemuanKe - $topik',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (keterangan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    keterangan,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 13,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_timeAgo(tanggal)} - ${_formatDate(tanggal)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final style = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.text),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: style.text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showMapelDetail(Map<String, dynamic> data) {
    final mapel = data['mapel'] as String;
    final guru = data['guru'] as String;
    final meetings = [
      ...(data['meetings'] as List<Map<String, dynamic>>),
    ]..sort((a, b) => (b['pertemuanKe'] ?? 0).compareTo(a['pertemuanKe'] ?? 0));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: 720,
            height: math.min(MediaQuery.of(context).size.height * 0.82, 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _mapelIcon(mapel),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mapel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              guru,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: meetings.isEmpty
                      ? _emptyList('Belum ada riwayat untuk mata pelajaran ini')
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: meetings.length,
                          itemBuilder: (context, index) =>
                              _buildRiwayatCard(meetings[index]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openQRScanner(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final height = math.min(
          MediaQuery.of(context).size.height * 0.9,
          760.0,
        );
        return Dialog(
          insetPadding: const EdgeInsets.all(28),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 560,
              height: height,
              color: Colors.white,
              child: Stack(
                children: [
                  // Langsung reload riwayat begitu scan sukses, tanpa tutup dialog
                  QRScanner(
                    onSuccess: () {
                      // Invalidate dashboard provider agar KPI kehadiran ikut update
                      ref.invalidate(studentDashboardProvider);
                      if (mounted) _load();
                    },
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton.filled(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    // Reload sekali lagi setelah dialog ditutup sebagai safety net
    if (mounted) _load();
  }

  Widget _emptyList(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_toggle_off,
            size: 58,
            color: AppColors.gray300,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: EdgeInsets.zero,
      children: List.generate(
        5,
        (_) => Container(
          height: 78,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
