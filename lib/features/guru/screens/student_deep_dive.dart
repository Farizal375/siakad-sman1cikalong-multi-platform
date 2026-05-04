// File: lib/features/guru/screens/student_deep_dive.dart
// ===========================================
// STUDENT DEEP DIVE - Wali Kelas
// Connected to /rapor/preview + /rapor PDF endpoints
// ===========================================

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_transfer.dart';
import '../../../shared_widgets/success_toast.dart';
import '../providers/homeroom_provider.dart';

class StudentDeepDive extends ConsumerStatefulWidget {
  final String? studentId;
  const StudentDeepDive({super.key, this.studentId});

  @override
  ConsumerState<StudentDeepDive> createState() => _StudentDeepDiveState();
}

class _StudentDeepDiveState extends ConsumerState<StudentDeepDive> {
  bool _loading = true;
  bool _printing = false;
  bool _downloading = false;
  bool _showToast = false;
  String _toastMsg = '';
  HomeroomContext? _homeroom;
  Map<String, dynamic>? _rapor;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final studentId = widget.studentId;
    if (studentId == null || studentId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final homeroom = await ref.read(homeroomContextProvider.future);
      final semesterId = homeroom.semesterAktif?.id;
      if (semesterId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final response = await ApiService.previewRapor(studentId, semesterId);
      if (mounted) {
        setState(() {
          _homeroom = homeroom;
          _rapor = response['data'] is Map
              ? Map<String, dynamic>.from(response['data'] as Map)
              : null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadRapor() async {
    final studentId = widget.studentId;
    final semesterId = _homeroom?.semesterAktif?.id;
    if (studentId == null || semesterId == null) return;

    final siswa = Map<String, dynamic>.from(_rapor?['siswa'] as Map? ?? {});
    final name = siswa['nama']?.toString() ?? studentId;
    final semester = _homeroom?.semesterAktif?.label ?? 'semester';

    setState(() {
      _downloading = true;
      _toastMsg = 'Mengunduh PDF rapor...';
      _showToast = true;
    });

    try {
      final bytes = await ApiService.downloadRaporPdf(studentId, semesterId);
      await _savePdf(
        'rapor_${_safeFileName(name)}_${_safeFileName(semester)}.pdf',
        bytes,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunduh rapor siswa')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _printRapor() async {
    final studentId = widget.studentId;
    final semesterId = _homeroom?.semesterAktif?.id;
    if (studentId == null || semesterId == null) return;

    setState(() {
      _printing = true;
      _toastMsg = 'Memuat PDF rapor...';
      _showToast = true;
    });

    try {
      final bytes = await ApiService.downloadRaporPdf(studentId, semesterId);
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mencetak rapor siswa')),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
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

  String _safeFileName(String value) {
    return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final rapor = _rapor;
    if (rapor == null) {
      return const Center(child: Text('Data rapor tidak ditemukan'));
    }

    final siswa = Map<String, dynamic>.from(rapor['siswa'] as Map? ?? {});
    final nilai = (rapor['nilai'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final kehadiran = Map<String, dynamic>.from(
      rapor['kehadiran'] as Map? ?? {},
    );
    final catatan = rapor['catatan']?.toString();
    final canPrint = rapor['canPrint'] != false;
    final missingData = (rapor['missingData'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final avg = nilai.isEmpty
        ? 0.0
        : nilai
                  .map((n) => (n['nilaiAkhir'] as num?)?.toDouble() ?? 0)
                  .reduce((a, b) => a + b) /
              nilai.length;
    final totalHadir = (kehadiran['hadir'] as num?)?.toInt() ?? 0;
    final totalSemua =
        totalHadir +
        ((kehadiran['sakit'] as num?)?.toInt() ?? 0) +
        ((kehadiran['izin'] as num?)?.toInt() ?? 0) +
        ((kehadiran['alpa'] as num?)?.toInt() ?? 0);
    final attendance = totalSemua == 0
        ? 0
        : (totalHadir / totalSemua * 100).round();

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/guru/cetak-rapor'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Kembali ke Daftar Siswa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _downloading || !canPrint
                            ? null
                            : _downloadRapor,
                        icon: _downloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download, size: 18),
                        label: Text(_downloading ? 'Memuat...' : 'Unduh PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _printing || !canPrint ? null : _printRapor,
                        icon: _printing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.print, size: 18),
                        label: Text(
                          _printing ? 'Memuat...' : 'Cetak Rapor Siswa (PDF)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildProfileCard(siswa, avg, attendance),
              if (!canPrint) ...[
                const SizedBox(height: 20),
                _buildReadinessWarning(missingData),
              ],
              const SizedBox(height: 20),
              _buildTranscript(nilai),
              const SizedBox(height: 20),
              _buildAttendanceSummary(kehadiran),
              const SizedBox(height: 20),
              _buildCatatan(catatan),
              const SizedBox(height: 32),
            ],
          ),
        ),
        if (_showToast)
          Positioned(
            top: 16,
            right: 16,
            child: SuccessToast(
              isVisible: true,
              message: _toastMsg,
              onClose: () => setState(() => _showToast = false),
            ),
          ),
      ],
    );
  }

  Widget _buildReadinessWarning(List<String> missingData) {
    final labels = {
      'nilai': 'nilai mapel',
      'kehadiran': 'rekap kehadiran',
      'catatan': 'catatan wali kelas',
    };
    final missing = missingData.isEmpty
        ? 'data rapor'
        : missingData.map((item) => labels[item] ?? item).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA), width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rapor belum siap dicetak karena $missing belum lengkap.',
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    Map<String, dynamic> siswa,
    double avg,
    int attendance,
  ) {
    final name = siswa['nama']?.toString() ?? '-';
    final initials = name
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'NISN: ${siswa['nisn'] ?? '-'} - Kelas ${siswa['kelas'] ?? '-'}',
                  style: const TextStyle(color: AppColors.gray600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _kpiBox(
                      Icons.emoji_events,
                      const Color(0xFF3B82F6),
                      const Color(0xFFEFF6FF),
                      'Rata-rata',
                      avg.toStringAsFixed(1),
                    ),
                    const SizedBox(width: 12),
                    _kpiBox(
                      Icons.calendar_today,
                      const Color(0xFF10B981),
                      const Color(0xFFECFDF5),
                      'Kehadiran',
                      '$attendance%',
                    ),
                    const SizedBox(width: 12),
                    _kpiBox(
                      Icons.person_pin,
                      AppColors.accent,
                      AppColors.amber50,
                      'Wali Kelas',
                      siswa['waliKelas']?.toString() ?? '-',
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

  Widget _buildTranscript(List<Map<String, dynamic>> nilai) {
    final semester = _rapor?['semester']?.toString();
    final tahunAjaran = _rapor?['tahunAjaran']?.toString();
    final semesterLabel = [
      if (semester != null && semester.isNotEmpty) semester,
      if (tahunAjaran != null && tahunAjaran.isNotEmpty) tahunAjaran,
    ].join(' - ');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hasil Studi ${semesterLabel.isEmpty ? _homeroom?.semesterAktif?.label ?? '' : semesterLabel}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (nilai.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Belum ada data nilai')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1010,
                child: Table(
                  border: TableBorder.all(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(48),
                    1: FixedColumnWidth(220),
                    2: FixedColumnWidth(58),
                    3: FixedColumnWidth(72),
                    4: FixedColumnWidth(62),
                    5: FixedColumnWidth(62),
                    6: FixedColumnWidth(62),
                    7: FixedColumnWidth(78),
                    8: FixedColumnWidth(78),
                    9: FixedColumnWidth(78),
                    10: FixedColumnWidth(70),
                    11: FixedColumnWidth(122),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      children: [
                        'No',
                        'Mata Pelajaran',
                        'KKM',
                        'Tugas',
                        'UH',
                        'UTS',
                        'UAS',
                        'Keaktifan',
                        'Kehadiran',
                        'Akhir',
                        'Pred.',
                        'Ketuntasan',
                      ].map(_headerCell).toList(),
                    ),
                    ...nilai.asMap().entries.map((e) {
                      final g = e.value;
                      final tuntas = g['tuntas'] == true;
                      return TableRow(
                        decoration: BoxDecoration(
                          color: e.key % 2 == 0
                              ? const Color(0xFFF9FAFB)
                              : Colors.white,
                        ),
                        children: [
                          _cell('${e.key + 1}', center: true),
                          _cell(g['mapel']?.toString() ?? '-'),
                          _cell(_score(g, 'kkm'), center: true),
                          _cell(_score(g, 'nilaiTugas'), center: true),
                          _cell(_score(g, 'nilaiUH'), center: true),
                          _cell(_score(g, 'nilaiUTS'), center: true),
                          _cell(_score(g, 'nilaiUAS'), center: true),
                          _cell(_score(g, 'nilaiKeaktifan'), center: true),
                          _cell(_score(g, 'nilaiKehadiran'), center: true),
                          _cell(
                            _score(g, 'nilaiAkhir'),
                            center: true,
                            bold: true,
                            fontSize: 13,
                          ),
                          _cell(g['predikat']?.toString() ?? '-', center: true),
                          _cell(
                            tuntas ? 'Tuntas' : 'Belum Tuntas',
                            center: true,
                            bold: !tuntas,
                            fontSize: 12,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(Map<String, dynamic> kehadiran) {
    final hadir = (kehadiran['hadir'] as num?)?.toInt() ?? 0;
    final sakit = (kehadiran['sakit'] as num?)?.toInt() ?? 0;
    final izin = (kehadiran['izin'] as num?)?.toInt() ?? 0;
    final alpa = (kehadiran['alpa'] as num?)?.toInt() ?? 0;
    final total = hadir + sakit + izin + alpa;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekap Kehadiran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _attendanceBox(
                'Hadir',
                hadir,
                total,
                Icons.check_circle_outline,
                const Color(0xFF10B981),
                const Color(0xFFECFDF5),
              ),
              const SizedBox(width: 12),
              _attendanceBox(
                'Sakit',
                sakit,
                total,
                Icons.healing_outlined,
                const Color(0xFF3B82F6),
                const Color(0xFFEFF6FF),
              ),
              const SizedBox(width: 12),
              _attendanceBox(
                'Izin',
                izin,
                total,
                Icons.event_available_outlined,
                AppColors.accent,
                AppColors.amber50,
              ),
              const SizedBox(width: 12),
              _attendanceBox(
                'Alpa',
                alpa,
                total,
                Icons.error_outline,
                const Color(0xFFDC2626),
                const Color(0xFFFEF2F2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatatan(String? catatan) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Wali Kelas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
            ),
            child: Text(
              catatan?.isNotEmpty == true
                  ? catatan!
                  : 'Belum ada catatan wali kelas.',
              style: const TextStyle(color: AppColors.foreground, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _cell(
    String value, {
    bool center = false,
    bool bold = false,
    double? fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        value,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontSize: fontSize ?? (bold ? 18 : 13),
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: bold ? AppColors.primary : AppColors.foreground,
        ),
      ),
    );
  }

  String _score(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return '-';
    if (value is num) return value.round().toString();
    return value.toString();
  }

  Widget _attendanceBox(
    String label,
    int value,
    int total,
    IconData icon,
    Color color,
    Color bg,
  ) {
    final percent = total == 0 ? 0 : (value / total * 100).round();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                    ),
                  ),
                  Text(
                    '$value hari',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    '$percent% dari total',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiBox(
    IconData icon,
    Color color,
    Color bg,
    String label,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray600,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
