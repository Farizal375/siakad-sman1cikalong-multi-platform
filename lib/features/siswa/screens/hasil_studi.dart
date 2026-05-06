// File: lib/features/siswa/screens/hasil_studi.dart
// ===========================================
// HASIL STUDI – Siswa
// Connected to /nilai/siswa/:siswaId API
// 3 Tab: Nilai Semester | Transkrip Nilai | Visualisasi Data
// ===========================================

import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/file_transfer.dart';

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
  Map<String, dynamic>? _summary;
  bool _downloadingRapor = false;
  bool _downloadingTranskrip = false;
  final Set<String> _expandedSemesters = {};

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
      final summary = response['summary'] as Map<String, dynamic>?;

      // Group by semester
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
          _summary = summary;
          _gradesBySemester.clear();
          _gradesBySemester.addAll(grouped);
          _expandedSemesters
            ..clear()
            ..addAll(grouped.keys);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getPredikat(num? nilai) {
    return _getHuruf(nilai);
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

  double _calcAvg(List<Map<String, dynamic>> g) {
    if (g.isEmpty) return 0;
    return g.fold<double>(
          0,
          (s, row) => s + ((row['nilaiAkhir'] as num?)?.toDouble() ?? 0),
        ) /
        g.length;
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

  int _semesterOrderValue(String semKey) {
    final yearMatch = RegExp(r'(\d{4})').firstMatch(semKey);
    final startYear = int.tryParse(yearMatch?.group(1) ?? '') ?? 0;
    final term = semKey.toLowerCase().contains('genap') ? 2 : 1;
    return startYear * 10 + term;
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hasil Studi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Riwayat performa akademik dan nilai',
                      style: TextStyle(color: AppColors.gray600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(8),
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
                child: compact
                    ? Column(
                        children: [
                          _tabBtn('aktivitas', 'Nilai Semester'),
                          const SizedBox(height: 8),
                          _tabBtn('transkrip', 'Transkrip Nilai'),
                          const SizedBox(height: 8),
                          _tabBtn('visualisasi', 'Visualisasi Data'),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _tabBtn('aktivitas', 'Nilai Semester'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _tabBtn('transkrip', 'Transkrip Nilai'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _tabBtn('visualisasi', 'Visualisasi Data'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              Container(
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
                child: _allGrades.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: AppColors.gray300,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada data nilai',
                                style: TextStyle(
                                  color: AppColors.gray600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildTabContent(compact),
              ),
            ],
          ),
        );
      },
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
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.gray600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool compact) {
    switch (_activeTab) {
      case 'aktivitas':
        return _buildNilaiTab(compact);
      case 'transkrip':
        return _buildTranscriptTab(compact);
      case 'visualisasi':
        return _buildVisualisasiTab(compact);
      default:
        return const SizedBox();
    }
  }

  Widget _buildNilaiTab(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLatestSummaryCards(compact),
        const SizedBox(height: 24),
        const Text(
          'Rincian Nilai Mata Pelajaran',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Komponen nilai mengikuti input dan bobot dari guru mata pelajaran.',
          style: TextStyle(fontSize: 13, color: AppColors.gray600),
        ),
        const SizedBox(height: 16),
        ..._gradesBySemester.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGradeSemesterSection(entry.key, entry.value),
              const SizedBox(height: 28),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLatestSummaryCards(bool compact) {
    final latestGrades = _latestSemesterGrades;
    final avg =
        (_summary?['latestAverage'] as num?)?.toDouble() ??
        _calcAvg(latestGrades);
    final rank = _summary?['latestRank'];
    final classSize = _summary?['latestClassSize'];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(
            'Rata-rata Semester Terakhir',
            avg.toStringAsFixed(1),
            _latestSemesterLabel,
            Icons.bar_chart_rounded,
            AppColors.primary,
          ),
          const SizedBox(height: 12),
          _infoCard(
            'Peringkat Kelas Terakhir',
            rank == null ? '-' : '$rank',
            classSize == null
                ? _latestSemesterLabel
                : 'dari $classSize siswa • $_latestSemesterLabel',
            Icons.emoji_events_outlined,
            AppColors.accent,
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
                  : const Icon(Icons.download, size: 18),
              label: const Text('Unduh PDF Rapor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _infoCard(
            'Rata-rata Semester Terakhir',
            avg.toStringAsFixed(1),
            _latestSemesterLabel,
            Icons.bar_chart_rounded,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            'Peringkat Kelas Terakhir',
            rank == null ? '-' : '$rank',
            classSize == null
                ? _latestSemesterLabel
                : 'dari $classSize siswa • $_latestSemesterLabel',
            Icons.emoji_events_outlined,
            AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
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
              : const Icon(Icons.download, size: 18),
          label: const Text('Unduh PDF Rapor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 4),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeSemesterSection(
    String title,
    List<Map<String, dynamic>> grades,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rata-rata ${_calcAvg(grades).toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...grades.map(_buildGradeDetailCard),
      ],
    );
  }

  Widget _buildGradeDetailCard(Map<String, dynamic> grade) {
    final nilai = (grade['nilaiAkhir'] as num?)?.round() ?? 0;
    final huruf = _getHuruf(grade['nilaiAkhir'] as num?);
    final kkm = grade['kkm'] ?? 75;
    final lulus = nilai >= (kkm as num);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _hurfBg(huruf),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hurfColor(huruf).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$nilai',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _hurfColor(huruf),
                  ),
                ),
                Text(
                  huruf,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _hurfColor(huruf),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        grade['mataPelajaran'] as String? ?? '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: lulus
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lulus ? 'Tuntas' : 'Belum Tuntas',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: lulus
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'KKM $kkm • Predikat ${_getPredikat(grade['nilaiAkhir'] as num?)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _scoreChip(
                      'Tugas',
                      grade['nilaiTugas'],
                      grade['bobotTugas'],
                    ),
                    _scoreChip('UH', grade['nilaiUH'], grade['bobotUH']),
                    _scoreChip('UTS', grade['nilaiUTS'], grade['bobotUTS']),
                    _scoreChip('UAS', grade['nilaiUAS'], grade['bobotUAS']),
                    _scoreChip(
                      'Keaktifan',
                      grade['nilaiKeaktifan'],
                      grade['bobotKeaktifan'],
                    ),
                    _scoreChip(
                      'Kehadiran',
                      grade['nilaiKehadiran'],
                      grade['bobotKehadiran'],
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

  Widget _scoreChip(String label, dynamic value, dynamic weight) {
    final score = (value as num?)?.toStringAsFixed(0) ?? '-';
    final weightLabel = weight == null
        ? ''
        : ' • ${((weight as num).toDouble()).toStringAsFixed(0)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        '$label: $score$weightLabel',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.gray700,
        ),
      ),
    );
  }

  Widget _buildTranscriptTab(bool compact) {
    final semesterKeys = _gradesBySemester.keys.toList()
      ..sort(
        (a, b) => _semesterOrderValue(a).compareTo(_semesterOrderValue(b)),
      );
    final kumulatif = _calcAvg(_allGrades);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transkrip Nilai Akumulatif',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloadingTranskrip
                      ? null
                      : _downloadTranscriptPdf,
                  icon: _downloadingTranskrip
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download, size: 18),
                  label: const Text('Unduh Transkrip Resmi (PDF)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Transkrip Nilai Akumulatif',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _downloadingTranskrip
                    ? null
                    : _downloadTranscriptPdf,
                icon: _downloadingTranskrip
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download, size: 18),
                label: const Text('Unduh Transkrip Resmi (PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        _buildTranscriptSummary(kumulatif, semesterKeys.length, compact),
        const SizedBox(height: 16),
        ...semesterKeys.map(
          (semKey) => _buildTranscriptSemesterSection(semKey, compact),
        ),
      ],
    );
  }

  Widget _buildTranscriptSummary(
    double kumulatif,
    int semesterCount,
    bool compact,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentHover],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rata-rata Kumulatif',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_allGrades.length} Mata Pelajaran • $semesterCount Semester',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  kumulatif.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rata-rata Kumulatif',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_allGrades.length} Mata Pelajaran • $semesterCount Semester',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  kumulatif.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTranscriptSemesterSection(String semKey, bool compact) {
    final grades = _gradesBySemester[semKey] ?? [];
    final avg = _calcAvg(grades);
    final isExpanded = _expandedSemesters.contains(semKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSemesters.remove(semKey);
                } else {
                  _expandedSemesters.add(semKey);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                semKey,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _headerBadge('Rata: ${avg.toStringAsFixed(1)}'),
                            _headerBadge('${grades.length} Mapel'),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            semKey,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _headerBadge('Rata: ${avg.toStringAsFixed(1)}'),
                        const SizedBox(width: 8),
                        _headerBadge('${grades.length} Mapel'),
                      ],
                    ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            _buildTranscriptTable(grades),
          ],
        ],
      ),
    );
  }

  Widget _headerBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTranscriptTable(List<Map<String, dynamic>> grades) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 680,
        child: Table(
          border: TableBorder.all(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(8),
          ),
          columnWidths: const {
            0: FixedColumnWidth(86),
            1: FlexColumnWidth(2.6),
            2: FixedColumnWidth(110),
            3: FixedColumnWidth(72),
            4: FixedColumnWidth(72),
            5: FixedColumnWidth(96),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              children:
                  [
                        'Kode',
                        'Mata Pelajaran',
                        'Tahun Ajaran',
                        'Nilai',
                        'Huruf',
                        'Status',
                      ]
                      .map(
                        (h) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: Text(
                            h,
                            style: const TextStyle(
                              color: AppColors.gray700,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            ...grades.asMap().entries.map((entry) {
              final grade = entry.value;
              final nilai = (grade['nilaiAkhir'] as num?)?.round() ?? 0;
              final huruf = _getHuruf(grade['nilaiAkhir'] as num?);
              final kkm = grade['kkm'] ?? 75;
              final lulus = nilai >= (kkm as num);
              return TableRow(
                decoration: BoxDecoration(
                  color: entry.key.isEven
                      ? Colors.white
                      : const Color(0xFFF9FAFB),
                ),
                children: [
                  _tableText(grade['mataPelajaranKode'] ?? '-', bold: true),
                  _tableText(grade['mataPelajaran'] ?? '-'),
                  _tableText(grade['tahunAjaran'] ?? '-'),
                  _tableText(
                    '$nilai',
                    centered: true,
                    bold: true,
                    color: AppColors.primary,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Center(child: _letterBadge(huruf)),
                  ),
                  _tableText(
                    lulus ? 'Tuntas' : 'Belum',
                    centered: true,
                    color: lulus
                        ? const Color(0xFF15803D)
                        : AppColors.destructive,
                    bold: true,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _tableText(
    dynamic value, {
    bool centered = false,
    bool bold = false,
    Color color = AppColors.foreground,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        value?.toString() ?? '-',
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _letterBadge(String huruf) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _hurfBg(huruf),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _hurfColor(huruf).withValues(alpha: 0.5)),
      ),
      child: Text(
        huruf,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _hurfColor(huruf),
        ),
      ),
    );
  }

  Widget _buildVisualisasiTab(bool compact) {
    final semesterKeys = _gradesBySemester.keys.toList()
      ..sort(
        (a, b) => _semesterOrderValue(a).compareTo(_semesterOrderValue(b)),
      );
    final gpaData = <FlSpot>[];
    for (int i = 0; i < semesterKeys.length; i++) {
      if (i >= 6) break;
      gpaData.add(
        FlSpot(
          (i + 1).toDouble(),
          _calcAvg(_gradesBySemester[semesterKeys[i]]!),
        ),
      );
    }

    // Grade distribution uses the same letter scale as nilai and transkrip.
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
    final pieData = gradeBuckets.map((bucket) {
      final count = bucket['count'] as int;
      final pct = total > 0 ? count / total * 100 : 0.0;
      final label = bucket['label'] as String;
      return PieChartSectionData(
        value: pct > 0 ? pct : 0.1,
        color: bucket['color'] as Color,
        title: pct > 4 ? '$label\n${pct.round()}%' : '',
        radius: 82,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line Chart
        const Text(
          'Tren Rata-rata Nilai Per Semester',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        if (gpaData.isNotEmpty)
          Container(
            height: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
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
            height: 200,
            alignment: Alignment.center,
            child: const Text(
              'Data belum cukup untuk grafik',
              style: TextStyle(color: AppColors.gray500),
            ),
          ),
        const SizedBox(height: 32),

        // Pie Chart – Distribusi Nilai
        const Text(
          'Distribusi Nilai',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: compact ? 440 : 360,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: compact
              ? Column(
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
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: gradeBuckets.map((bucket) {
                        return _pieLegend(
                          bucket['color'] as Color,
                          '${bucket['label']} (${bucket['range']})',
                          bucket['count'] as int,
                        );
                      }).toList(),
                    ),
                  ],
                )
              : Row(
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
                    SizedBox(
                      width: 210,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: gradeBuckets.map((bucket) {
                          return _pieLegend(
                            bucket['color'] as Color,
                            '${bucket['label']} (${bucket['range']})',
                            bucket['count'] as int,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _pieLegend(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count',
          style: const TextStyle(fontSize: 13, color: AppColors.gray700),
        ),
      ],
    );
  }
}
