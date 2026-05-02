// File: lib/features/siswa/screens/mobile/mobile_hasil_studi.dart
// ===========================================
// MOBILE HASIL STUDI / RAPOR (FR-06.3)
// Tabs: Nilai | Transkrip (ALL semesters) | Grafik
// Connected to /nilai/siswa/:id API
// ===========================================

import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/file_transfer.dart';

class MobileHasilStudi extends ConsumerStatefulWidget {
  const MobileHasilStudi({super.key});
  @override
  ConsumerState<MobileHasilStudi> createState() => _MobileHasilStudiState();
}

class _MobileHasilStudiState extends ConsumerState<MobileHasilStudi>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  List<Map<String, dynamic>> _allGrades = [];
  Map<String, List<Map<String, dynamic>>> _gradesBySemester = {};
  Map<String, dynamic>? _summary;
  bool _downloadingRapor = false;
  bool _downloadingTranskrip = false;
  // Track expanded semesters in transcript
  final Set<String> _expandedSemesters = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadGrades();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      final response = await ApiService.getNilaiSiswa(userId);
      final List data = response['data'] ?? [];
      final grades = data.cast<Map<String, dynamic>>();
      final summary = response['summary'] as Map<String, dynamic>?;

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final g in grades) {
        final semKey =
            '${g['semester'] ?? 'Lainnya'} ${g['tahunAjaran'] ?? ''}';
        grouped.putIfAbsent(semKey, () => []);
        grouped[semKey]!.add(g);
      }

      if (mounted) {
        setState(() {
          _allGrades = grades;
          _gradesBySemester = grouped;
          _summary = summary;
          // Expand all semesters by default
          _expandedSemesters.addAll(grouped.keys);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
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
    if (nilai >= 55) return 'C-';
    return 'D';
  }

  String _getPredikat(num? nilai) {
    return _getHuruf(nilai);
  }

  Color _gradeColor(String huruf) {
    if (huruf.startsWith('A')) return const Color(0xFF15803D);
    if (huruf.startsWith('B')) return const Color(0xFF1D4ED8);
    if (huruf.startsWith('C')) return const Color(0xFFB45309);
    return const Color(0xFFB91C1C);
  }

  Color _gradeBg(String huruf) {
    if (huruf.startsWith('A')) return const Color(0xFFDCFCE7);
    if (huruf.startsWith('B')) return const Color(0xFFDBEAFE);
    if (huruf.startsWith('C')) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  double _calcAvg(List<Map<String, dynamic>> grades) {
    if (grades.isEmpty) return 0;
    return grades.fold<double>(
          0,
          (s, g) => s + ((g['nilaiAkhir'] as num?)?.toDouble() ?? 0),
        ) /
        grades.length;
  }

  List<Map<String, dynamic>> get _latestSemesterGrades {
    final latestId = _summary?['latestSemesterId'] as String?;
    if (latestId != null) {
      final grades = _allGrades
          .where((g) => g['semesterId'] == latestId)
          .toList();
      if (grades.isNotEmpty) return grades;
    }
    if (_gradesBySemester.isEmpty) return [];
    return _gradesBySemester.entries.last.value;
  }

  String get _latestSemesterLabel {
    final label = _summary?['latestSemesterLabel'] as String?;
    if (label != null && label.isNotEmpty) return label;
    final grades = _latestSemesterGrades;
    if (grades.isEmpty) return '-';
    return '${grades.first['semester'] ?? '-'} - ${grades.first['tahunAjaran'] ?? '-'}';
  }

  Future<void> _savePdf(String filename, List<int> bytes) async {
    try {
      downloadBytesFile(filename, bytes, mimeType: 'application/pdf');
    } on UnsupportedError {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: filename,
      );
    }
  }

  Future<void> _downloadSemesterPdf() async {
    final userId = ref.read(currentUserIdProvider);
    final semesterId =
        _summary?['latestSemesterId'] as String? ??
        (_latestSemesterGrades.isNotEmpty
            ? _latestSemesterGrades.first['semesterId'] as String?
            : null);
    if (userId == null || semesterId == null) return;

    try {
      setState(() => _downloadingRapor = true);
      final bytes = await ApiService.downloadRaporPdf(userId, semesterId);
      await _savePdf(
        'rapor_${_latestSemesterLabel.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.pdf',
        bytes,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunduh PDF rapor'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingRapor = false);
    }
  }

  Future<void> _downloadTranscriptPdf() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      setState(() => _downloadingTranskrip = true);
      final bytes = await ApiService.downloadTranskripPdf(userId);
      await _savePdf('transkrip_nilai.pdf', bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunduh PDF transkrip'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingTranskrip = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hasil Studi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: fgColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Riwayat performa akademik dan nilai',
                  style: TextStyle(fontSize: 13, color: AppColors.gray500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
            tabs: const [
              Tab(text: 'Nilai'),
              Tab(text: 'Transkrip'),
              Tab(text: 'Grafik'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab Content
        Expanded(
          child: _loading
              ? _buildSkeleton()
              : _allGrades.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildNilaiTab(context),
                    _buildTranskripTab(context),
                    _buildGrafikTab(context),
                  ],
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // TAB 1: NILAI (per semester cards)
  // ═══════════════════════════════════════════
  Widget _buildNilaiTab(BuildContext context) {
    final latestAvg =
        (_summary?['latestAverage'] as num?)?.toDouble() ??
        _calcAvg(_latestSemesterGrades);
    final rank = _summary?['latestRank'];
    final classSize = _summary?['latestClassSize'];

    return RefreshIndicator(
      onRefresh: _loadGrades,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryMiniCard(
                  context,
                  'Rata-rata Terakhir',
                  latestAvg.toStringAsFixed(1),
                  _latestSemesterLabel,
                  Icons.bar_chart_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMiniCard(
                  context,
                  'Peringkat Kelas',
                  rank == null ? '-' : '$rank',
                  classSize == null
                      ? _latestSemesterLabel
                      : 'dari $classSize siswa',
                  Icons.emoji_events_outlined,
                  AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloadingRapor ? null : _downloadSemesterPdf,
              icon: _downloadingRapor
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_outlined, size: 18),
              label: const Text('Unduh PDF Rapor Semester Terakhir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Rincian Nilai Mata Pelajaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tugas, UH, UTS, UAS, dan komponen lainnya mengikuti input guru mapel.',
            style: TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),
          ..._gradesBySemester.entries.map((entry) {
            final avg = _calcAvg(entry.value);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Rata: ${avg.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ...entry.value.map((g) => _buildGradeCard(context, g)),
                const SizedBox(height: 20),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryMiniCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.gray700 : AppColors.gray200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.gray500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: AppColors.gray400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(BuildContext context, Map<String, dynamic> grade) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    final subject = grade['mataPelajaran'] ?? '-';
    final nilai = (grade['nilaiAkhir'] as num?)?.round() ?? 0;
    final huruf = _getHuruf(grade['nilaiAkhir'] as num?);
    final predikat = _getPredikat(grade['nilaiAkhir'] as num?);
    final kkm = grade['kkm'] ?? 75;
    final lulus = nilai >= (kkm as num);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.gray700 : AppColors.gray200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _gradeBg(huruf),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _gradeColor(huruf).withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$nilai',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _gradeColor(huruf),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fgColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'KKM: $kkm',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: lulus ? AppColors.green50 : AppColors.red50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lulus ? 'Tuntas' : 'Belum Tuntas',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: lulus
                                  ? const Color(0xFF15803D)
                                  : AppColors.destructive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    huruf,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _gradeColor(huruf),
                    ),
                  ),
                  Text(
                    predikat,
                    style: TextStyle(fontSize: 10, color: AppColors.gray500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _scorePill('Tugas', grade['nilaiTugas'], grade['bobotTugas']),
              _scorePill('UH', grade['nilaiUH'], grade['bobotUH']),
              _scorePill('UTS', grade['nilaiUTS'], grade['bobotUTS']),
              _scorePill('UAS', grade['nilaiUAS'], grade['bobotUAS']),
              _scorePill(
                'Aktif',
                grade['nilaiKeaktifan'],
                grade['bobotKeaktifan'],
              ),
              _scorePill(
                'Hadir',
                grade['nilaiKehadiran'],
                grade['bobotKehadiran'],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scorePill(String label, dynamic value, dynamic weight) {
    final score = (value as num?)?.toStringAsFixed(0) ?? '-';
    final weightLabel = weight == null
        ? ''
        : ' • ${((weight as num).toDouble()).toStringAsFixed(0)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Text(
        '$label: $score$weightLabel',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.gray700,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 2: TRANSKRIP — ALL SEMESTERS GROUPED
  // ═══════════════════════════════════════════
  Widget _buildTranskripTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    final kumulatif = _calcAvg(_allGrades);
    final semesterKeys = _gradesBySemester.keys.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        // Cumulative GPA card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accentHover],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rata-rata Kumulatif',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_allGrades.length} Mata Pelajaran · ${semesterKeys.length} Semester',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                kumulatif.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _downloadingTranskrip ? null : _downloadTranscriptPdf,
            icon: _downloadingTranskrip
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_outlined, size: 18),
            label: const Text('Unduh PDF Transkrip Resmi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // All semesters
        ...semesterKeys.asMap().entries.map((semEntry) {
          final semKey = semEntry.value;
          final grades = _gradesBySemester[semKey]!;
          final avg = _calcAvg(grades);
          final isExpanded = _expandedSemesters.contains(semKey);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Semester header (tappable to expand/collapse)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedSemesters.remove(semKey);
                    } else {
                      _expandedSemesters.add(semKey);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          semKey,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Rata: ${avg.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${grades.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Grade rows (visible when expanded)
              if (isExpanded)
                ...grades.asMap().entries.map((gEntry) {
                  final g = gEntry.value;
                  final huruf = _getHuruf(g['nilaiAkhir'] as num?);
                  final nilai = (g['nilaiAkhir'] as num?)?.round() ?? 0;
                  final subject = g['mataPelajaran'] ?? '-';
                  final kkm = g['kkm'] ?? 75;
                  final lulus = nilai >= (kkm as num);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.gray700 : AppColors.gray200,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Number
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.gray700
                                : AppColors.gray100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${gEntry.key + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.gray300
                                    : AppColors.gray600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Subject
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: fgColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Text(
                                    'KKM: $kkm',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.gray400,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: lulus
                                          ? AppColors.green50
                                          : AppColors.red50,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      lulus ? '✓' : '✗',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: lulus
                                            ? const Color(0xFF15803D)
                                            : AppColors.destructive,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Score + Grade
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$nilai',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _gradeColor(huruf),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _gradeBg(huruf),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                huruf,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _gradeColor(huruf),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // TAB 3: GRAFIK
  // ═══════════════════════════════════════════
  Widget _buildGrafikTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    // Sort semesters by academic year and term to ensure chronological order
    final semesterKeys = _gradesBySemester.keys.toList()..sort();

    final gpaData = <FlSpot>[];
    // Map available data to semesters 1-6 (assuming chronological order matches Sem 1-6)
    for (int i = 0; i < semesterKeys.length; i++) {
      // Limit to 6 semesters maximum
      if (i >= 6) break;
      gpaData.add(
        FlSpot(
          (i + 1).toDouble(),
          _calcAvg(_gradesBySemester[semesterKeys[i]]!),
        ),
      );
    }

    final gradeBuckets = [
      {
        'label': 'D',
        'range': '<55',
        'color': const Color(0xFFB91C1C),
        'count': 0,
      },
      {
        'label': 'C-',
        'range': '55-59',
        'color': const Color(0xFFDC2626),
        'count': 0,
      },
      {
        'label': 'C',
        'range': '60-64',
        'color': const Color(0xFFF97316),
        'count': 0,
      },
      {
        'label': 'C+',
        'range': '65-69',
        'color': const Color(0xFFF59E0B),
        'count': 0,
      },
      {
        'label': 'B-',
        'range': '70-74',
        'color': const Color(0xFF0EA5E9),
        'count': 0,
      },
      {
        'label': 'B',
        'range': '75-79',
        'color': const Color(0xFF3B82F6),
        'count': 0,
      },
      {
        'label': 'B+',
        'range': '80-84',
        'color': const Color(0xFF6366F1),
        'count': 0,
      },
      {
        'label': 'A-',
        'range': '85-89',
        'color': const Color(0xFF22C55E),
        'count': 0,
      },
      {
        'label': 'A',
        'range': '90-100',
        'color': const Color(0xFF15803D),
        'count': 0,
      },
    ];

    for (final g in _allGrades) {
      final v = (g['nilaiAkhir'] as num?)?.toDouble() ?? 0;
      final letter = _getHuruf(v);
      final bucket = gradeBuckets.firstWhere((item) => item['label'] == letter);
      bucket['count'] = (bucket['count'] as int) + 1;
    }
    final total = _allGrades.length;
    final pieSections = gradeBuckets.map((bucket) {
      final count = bucket['count'] as int;
      final pct = total > 0 ? count / total * 100 : 0.0;
      return _pieSection(
        pct,
        bucket['label'] as String,
        bucket['color'] as Color,
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        Text(
          'Tren Rata-rata Per Semester',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: fgColor,
          ),
        ),
        const SizedBox(height: 12),
        if (gpaData.isNotEmpty)
          Container(
            height: 240,
            padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.gray700 : AppColors.gray200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: gpaData,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 5,
                        color: AppColors.primary,
                        strokeColor: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final val = v.toInt();
                        if (val >= 1 && val <= 6) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'Sem $val',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  verticalInterval: 1,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.gray200,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                  getDrawingVerticalLine: (v) =>
                      FlLine(color: AppColors.gray100, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: AppColors.gray300, width: 1.5),
                    left: BorderSide(color: AppColors.gray300, width: 1.5),
                    right: BorderSide.none,
                    top: BorderSide.none,
                  ),
                ),
                minX: 1,
                maxX: 6,
                minY: 50,
                maxY: 100,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.gray700 : AppColors.gray200,
              ),
            ),
            child: Center(
              child: Text(
                'Data belum cukup untuk grafik tren',
                style: TextStyle(color: AppColors.gray500),
              ),
            ),
          ),
        const SizedBox(height: 28),

        Text(
          'Distribusi Nilai',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: fgColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: pieSections,
                    centerSpaceRadius: 36,
                    sectionsSpace: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: gradeBuckets.map((bucket) {
                  return _pieLegend(
                    context,
                    bucket['color'] as Color,
                    '${bucket['label']} (${bucket['range']})',
                    bucket['count'] as int,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PieChartSectionData _pieSection(double pct, String label, Color color) {
    return PieChartSectionData(
      value: pct > 0 ? pct : 0.1,
      color: color,
      title: pct > 5 ? '$label\n${pct.round()}%' : '',
      radius: 60,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _pieLegend(
    BuildContext context,
    Color color,
    String label,
    int count,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.gray500)),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.foreground,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: AppColors.gray300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data nilai',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nilai akan muncul setelah guru menginput',
            style: TextStyle(fontSize: 13, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: List.generate(
        5,
        (_) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
