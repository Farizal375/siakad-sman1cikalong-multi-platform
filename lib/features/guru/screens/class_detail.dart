// File: lib/features/guru/screens/class_detail.dart
// ===========================================
// CLASS DETAIL – Jurnal/Absensi & Input Nilai
// FR-04.1 – FR-04.6
// ===========================================

import 'dart:math';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

// ── Mock Data ──────────────────────────────────────────────────────────────
class _Student {
  final String id, name, nisn;
  String status; // HADIR / SAKIT / IZIN / ALPA
  _Student({
    required this.id,
    required this.name,
    required this.nisn,
    this.status = 'ALPA',
  });
}

class _GradeRow {
  final String name, nisn;
  double tugas, uh, uts, uas;
  double keaktifan; // input guru
  final double kehadiran; // auto dari absensi, read-only
  _GradeRow({
    required this.name,
    required this.nisn,
    this.tugas = 0,
    this.uh = 0,
    this.uts = 0,
    this.uas = 0,
    this.keaktifan = 80,
    this.kehadiran = 0, // dihitung otomatis
  });
  double getNaValue(
    double wTugas,
    double wUh,
    double wUts,
    double wUas,
    double wKeaktifan,
    double wKehadiran,
  ) {
    return (tugas * wTugas / 100) +
        (uh * wUh / 100) +
        (uts * wUts / 100) +
        (uas * wUas / 100) +
        (keaktifan * wKeaktifan / 100) +
        (kehadiran * wKehadiran / 100);
  }

  String getGrade(double naValue) {
    if (naValue >= 90) return 'A';
    if (naValue >= 80) return 'B';
    if (naValue >= 70) return 'C';
    if (naValue >= 60) return 'D';
    return 'E';
  }
}

class _PastMeeting {
  final String id, date, pertemuanKe, materi;
  final List<_Student> students;
  _PastMeeting({
    required this.id,
    required this.date,
    required this.pertemuanKe,
    required this.materi,
    required this.students,
  });
}

class _RecapStudent {
  final String name, nisn;
  final List<String> attendance; // 'H', 'I', 'S', 'A', '-'
  final int persentase;
  _RecapStudent({
    required this.name,
    required this.nisn,
    required this.attendance,
    this.persentase = 0,
  });

  int get totalHadir => attendance.where((a) => a == 'H').length;
  int get totalIzin => attendance.where((a) => a == 'I').length;
  int get totalSakit => attendance.where((a) => a == 'S').length;
  int get totalAlpa => attendance.where((a) => a == 'A').length;
}

// ── Main Screen ────────────────────────────────────────────────────────────
class ClassDetail extends StatefulWidget {
  final String classId;
  const ClassDetail({super.key, required this.classId});

  @override
  State<ClassDetail> createState() => _ClassDetailState();
}

class _ClassDetailState extends State<ClassDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Jurnal tab state
  String _generatedQR = '';
  Timer? _qrTimer;
  Timer? _pollTimer; // polling real-time attendance setiap 10 detik
  int _qrCountdown = 180; // 3 menit
  bool _showQRModal = false;
  // ignore: unused_field
  bool _isGeneratingQR = false;

  // QR session state
  List<String> _scheduleIds = [];
  int _totalPertemuanDibuat = 0;
  String _activeJadwalId = '';
  int _activePertemuanKe = 1;
  String _activeTanggal = '';
  String _activeMateri = '';
  bool _sessionActive = false; // true = sesi absensi sedang terbuka
  DateTime? _sessionStartTime;

  // Edit History state
  bool _showHistoryModal = false;
  _PastMeeting? _selectedHistory;

  List<_Student> _students = [];

  // Input Nilai tab state
  List<_GradeRow> _grades = [];
  String _editingId = '';
  final _controllers = <String, TextEditingController>{};
  bool _gradesSaved = false;

  // Nilai Weights (dynamic) — total harus 100
  double _bobotTugas = 20;
  double _bobotUH = 20;
  double _bobotUTS = 20;
  double _bobotUAS = 20;
  double _bobotKeaktifan = 10;
  double _bobotKehadiran = 20;

  // Data lists
  List<_PastMeeting> _histories = [];
  List<_RecapStudent> _recapStudents = [];

  bool _isLoading = true;
  String _className = '';
  String _subjectName = '';
  String? _activeSemesterId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getGuruClassDetail(widget.classId);
      final data = res['data'];

      if (mounted) {
        setState(() {
          _className = data['className'];
          _subjectName = data['subjectName'];
          _activeSemesterId = data['activeSemesterId'];

          final studentsList = data['students'] as List;
          _students = studentsList
              .map(
                (s) => _Student(
                  id: s['id'],
                  name: s['name'],
                  nisn: s['nisn'],
                  status: s['currentStatus'] ?? 'ALPA',
                ),
              )
              .toList();

          _grades = studentsList.map((s) {
            final double gradeData = ((s['grade'] ?? 0) as num).toDouble();
            // Default 0 jika belum ada data presensi (sesuai aturan: alpa=0, belum ada=0)
            final double attendanceRate = ((s['attendanceRate'] ?? 0) as num)
                .toDouble();
            return _GradeRow(
              name: s['name'] ?? '',
              nisn: s['nisn'] ?? '-',
              tugas: gradeData > 0
                  ? gradeData
                  : (60 + Random().nextInt(40)).toDouble(),
              uh: gradeData > 0
                  ? gradeData
                  : (60 + Random().nextInt(40)).toDouble(),
              uts: gradeData > 0
                  ? gradeData
                  : (60 + Random().nextInt(40)).toDouble(),
              uas: gradeData > 0
                  ? gradeData
                  : (60 + Random().nextInt(40)).toDouble(),
              keaktifan: (70 + Random().nextInt(30)).toDouble(),
              kehadiran: attendanceRate, // 0 jika belum ada presensi
            );
          }).toList();

          _totalPertemuanDibuat = (data['totalPertemuanDibuat'] ?? 0) as int;
          _scheduleIds = List<String>.from(data['scheduleIds'] ?? []);

          final recapList = data['recap'] as List;
          _recapStudents = recapList.map((r) {
            final pertemuanList = r['pertemuan'] as List? ?? [];
            final List<String> att = pertemuanList
                .map<String>((p) => (p['status'] ?? '-') as String)
                .toList();
            return _RecapStudent(
              name: r['name'] ?? '',
              nisn: r['nisn'] ?? '-',
              attendance: att,
              persentase: (r['persentase'] ?? 0) as int,
            );
          }).toList();

          final historiesList = data['histories'] as List;
          _histories = historiesList
              .map(
                (h) => _PastMeeting(
                  id: h['id'] ?? '',
                  date: h['date'] ?? '',
                  pertemuanKe: h['session'].toString(),
                  materi: h['topic'] ?? '',
                  students:
                      (h['students'] as List?)
                          ?.map(
                            (s) => _Student(
                              id: s['id'],
                              name: s['name'],
                              nisn: s['nisn'],
                              status: s['status'] ?? 'ALPA',
                            ),
                          )
                          .toList() ??
                      _students
                          .map(
                            (s) => _Student(
                              id: s.id,
                              name: s.name,
                              nisn: s.nisn,
                              status: 'ALPA',
                            ),
                          )
                          .toList(),
                ),
              )
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Gagal memuat data kelas: Koneksi terputus');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrTimer?.cancel();
    _pollTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isCompactLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 980;
  }

  // ── QR Generation (API-backed, 3-minute expiry) ─────────────────────
  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _generateQR() async {
    if (_scheduleIds.isEmpty) {
      _showErrorSnackbar('Tidak ada jadwal terkait untuk kelas ini');
      return;
    }
    setState(() => _isGeneratingQR = true);
    try {
      final jadwalId = _activeJadwalId.isNotEmpty
          ? _activeJadwalId
          : _scheduleIds.first;
      final tanggal = _activeTanggal.isNotEmpty
          ? _activeTanggal
          : _todayString();
      final pertemuanKe = _activePertemuanKe;

      final res = await ApiService.generateQR({
        'jadwalId': jadwalId,
        'tanggal': tanggal,
        'pertemuanKe': pertemuanKe,
      });
      final data = res['data'];
      setState(() {
        // Reset SEMUA siswa ke ALPA dulu — sesi baru = 0 hadir
        for (final s in _students) {
          s.status = 'ALPA';
        }
        _generatedQR = data['qrData'] ?? '';
        _qrCountdown = 180;
        _showQRModal = true;
        _sessionActive = true;
        _isGeneratingQR = false;
      });
      _startCountdownTimer();
      _startPolling(); // mulai polling real-time
    } catch (e) {
      setState(() => _isGeneratingQR = false);
      _showErrorSnackbar('Gagal generate QR Code. Periksa koneksi.');
    }
  }

  Future<void> _refreshQR() async {
    if (_scheduleIds.isEmpty) return;
    try {
      final jadwalId = _activeJadwalId.isNotEmpty
          ? _activeJadwalId
          : _scheduleIds.first;
      final tanggal = _activeTanggal.isNotEmpty
          ? _activeTanggal
          : _todayString();
      final pertemuanKe = _activePertemuanKe;

      final res = await ApiService.refreshQR({
        'jadwalId': jadwalId,
        'tanggal': tanggal,
        'pertemuanKe': pertemuanKe,
      });
      final data = res['data'];
      if (mounted) {
        setState(() {
          _generatedQR = data['qrData'] ?? '';
          _qrCountdown = 180;
        });
        _startCountdownTimer();
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Gagal refresh QR Code');
    }
  }

  void _startCountdownTimer() {
    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_qrCountdown <= 1) {
        t.cancel();
        _refreshQR(); // auto refresh setiap 3 menit
      } else {
        if (mounted) setState(() => _qrCountdown--);
      }
    });
  }

  void _closeQRModal() {
    _qrTimer?.cancel();
    // Tidak stop polling — session masih aktif, modal hanya diminimize
    setState(() => _showQRModal = false);
  }

  // ── Real-time Polling (10 detik) ──────────────────────────────────────────
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pollLiveAttendance(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollLiveAttendance() async {
    if (!_sessionActive || !mounted) return;
    final jadwalId = _activeJadwalId.isNotEmpty
        ? _activeJadwalId
        : (_scheduleIds.isNotEmpty ? _scheduleIds.first : '');
    final tanggal = _activeTanggal.isNotEmpty ? _activeTanggal : _todayString();
    if (jadwalId.isEmpty) return;

    try {
      final res = await ApiService.getLiveAttendance(
        jadwalId: jadwalId,
        tanggal: tanggal,
        pertemuanKe: _activePertemuanKe,
      );
      final List<dynamic> hadirnList = res['data'] ?? [];
      final Set<String> hadirIds = hadirnList
          .map((h) => h['siswaId'] as String)
          .toSet();

      if (!mounted) return;
      setState(() {
        for (final s in _students) {
          if (hadirIds.contains(s.id)) {
            s.status = 'HADIR';
          }
          // Jangan reset ke ALPA yang sudah diubah manual guru
        }
      });
    } catch (_) {
      // Polling error diabaikan — tidak ganggu UX
    }
  }

  Future<void> _endSession() async {
    _qrTimer?.cancel();
    _stopPolling(); // hentikan polling
    final jadwalId = _activeJadwalId.isNotEmpty
        ? _activeJadwalId
        : (_scheduleIds.isNotEmpty ? _scheduleIds.first : '');
    final tanggal = _activeTanggal.isNotEmpty ? _activeTanggal : _todayString();

    if (jadwalId.isNotEmpty) {
      try {
        await ApiService.endSession({
          'jadwalId': jadwalId,
          'tanggal': tanggal,
          'pertemuanKe': _activePertemuanKe,
        });
      } catch (_) {}
    }

    setState(() {
      _showQRModal = false;
      _sessionActive = false;
      _generatedQR = '';
      _qrCountdown = 180;
    });
    _showSaveSnackbar('Sesi absensi telah ditutup.');
  }

  // ── Open Session ───────────────────────────────────────────────────────
  void _openSessionDialog() {
    final pertemuanCtrl = TextEditingController(
      text: '${_totalPertemuanDibuat + 1}',
    );
    final topicCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Buka Sesi Pertemuan Baru',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pertemuan Ke-',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: pertemuanCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDeco('Contoh: 1'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Materi / Topik Pertemuan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: topicCtrl,
                decoration: _inputDeco('Contoh: Integral Tak Tentu'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deskripsi Kegiatan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: _inputDeco('Jelaskan kegiatan pembelajaran...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (pertemuanCtrl.text.trim().isEmpty) {
                _showErrorSnackbar('Pertemuan ke- wajib diisi');
                return;
              }
              if (topicCtrl.text.trim().isEmpty) {
                _showErrorSnackbar('Materi / topik wajib diisi');
                return;
              }
              if (_scheduleIds.isEmpty) {
                _showErrorSnackbar('Tidak ada jadwal terkait');
                return;
              }
              try {
                final jadwalId = _scheduleIds.first;
                final tanggal = _todayString();
                final pertemuanKe =
                    int.tryParse(pertemuanCtrl.text.trim()) ?? 1;
                final materi = topicCtrl.text.trim();

                await ApiService.createJurnal({
                  'jadwalId': jadwalId,
                  'tanggal': tanggal,
                  'pertemuanKe': pertemuanKe,
                  'judulMateri': materi,
                  'deskripsiKegiatan': descCtrl.text.trim(),
                });

                _activeJadwalId = jadwalId;
                _activePertemuanKe = pertemuanKe;
                _activeTanggal = tanggal;
                _activeMateri = materi;
                _sessionStartTime = DateTime.now();

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                await _loadData();
                await _generateQR(); // sets _sessionActive=true inside
              } catch (e) {
                var message = 'Gagal membuat sesi pertemuan. Periksa koneksi.';
                if (e is DioException && e.response?.data is Map) {
                  message = e.response?.data['message'] ?? message;
                }
                _showErrorSnackbar(message);
              }
            },
            child: const Text('Buka Sesi & Tampilkan QR'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  // ── Grade edit ────────────────────────────────────────────────────────
  TextEditingController _ctrl(String key, double value) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: value.toStringAsFixed(0));
    }
    return _controllers[key]!;
  }

  Future<void> _saveGrades() async {
    if (_getTotalBobot() != 100) {
      _showErrorSnackbar(
        'Total bobot penilaian harus 100% sebelum dapat menyimpan nilai',
      );
      return;
    }
    if (_activeSemesterId == null) {
      _showErrorSnackbar('Semester aktif tidak ditemukan');
      return;
    }

    try {
      final records = <Map<String, dynamic>>[];
      for (int i = 0; i < _grades.length; i++) {
        final g = _grades[i];
        final student = _students.firstWhere((s) => s.nisn == g.nisn);

        final tugasKey = '${g.nisn}-tugas';
        final uhKey = '${g.nisn}-uh';
        final utsKey = '${g.nisn}-uts';
        final uasKey = '${g.nisn}-uas';
        final keaktifanKey = '${g.nisn}-keaktifan';

        if (_controllers.containsKey(tugasKey)) {
          g.tugas = double.tryParse(_controllers[tugasKey]!.text) ?? g.tugas;
        }
        if (_controllers.containsKey(uhKey)) {
          g.uh = double.tryParse(_controllers[uhKey]!.text) ?? g.uh;
        }
        if (_controllers.containsKey(utsKey)) {
          g.uts = double.tryParse(_controllers[utsKey]!.text) ?? g.uts;
        }
        if (_controllers.containsKey(uasKey)) {
          g.uas = double.tryParse(_controllers[uasKey]!.text) ?? g.uas;
        }
        if (_controllers.containsKey(keaktifanKey)) {
          g.keaktifan =
              double.tryParse(_controllers[keaktifanKey]!.text) ?? g.keaktifan;
        }

        records.add({
          'siswaId': student.id,
          'tugas': g.tugas,
          'uh': g.uh,
          'uts': g.uts,
          'uas': g.uas,
          'keaktifan': g.keaktifan,
          'kehadiran': g.kehadiran,
        });
      }

      final parts = widget.classId.split('_');
      if (parts.length < 2) throw Exception('Invalid classId format');
      final mapelId = parts[1];

      await ApiService.saveNilaiBatch({
        'mapelId': mapelId,
        'semesterId': _activeSemesterId,
        'bobot': {
          'tugas': _bobotTugas,
          'uh': _bobotUH,
          'uts': _bobotUTS,
          'uas': _bobotUAS,
          'keaktifan': _bobotKeaktifan,
          'kehadiran': _bobotKehadiran,
        },
        'records': records,
      });

      setState(() {
        _editingId = '';
        _gradesSaved = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _gradesSaved = false);
      });
      _showSaveSnackbar('Nilai berhasil disimpan!');
    } catch (e) {
      _showErrorSnackbar('Gagal menyimpan nilai. Periksa koneksi.');
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final subject = _subjectName.isNotEmpty
        ? _subjectName
        : widget.classId.toUpperCase();
    final kelas = _className.isNotEmpty ? _className : '';
    final isCompact = _isCompactLayout(context);
    final tabs = isCompact
        ? const [Tab(text: 'Riwayat'), Tab(text: 'Absensi'), Tab(text: 'Nilai')]
        : const [
            Tab(text: 'Riwayat Pertemuan'),
            Tab(text: 'Rekapitulasi Absensi'),
            Tab(text: 'Manajemen Nilai'),
          ];

    return Stack(
      children: [
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            _buildHeader(subject, kelas),
            const SizedBox(height: 24),

            // ── Segmented Tabs ──
            Container(
              height: isCompact ? 58 : 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: isCompact,
                labelPadding: isCompact
                    ? const EdgeInsets.symmetric(horizontal: 16)
                    : const EdgeInsets.symmetric(horizontal: 8),
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.gray600,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 12 : 14,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: isCompact ? 12 : 14,
                ),
                dividerColor: Colors.transparent,
                tabs: tabs,
              ),
            ),
            const SizedBox(height: 20),

            // ── Tab Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJurnalTab(),
                  _buildRekapTab(),
                  _buildNilaiTab(),
                ],
              ),
            ),
          ],
        ),

        // QR Modal overlay
        if (_showQRModal) _buildQRModal(),

        // History Edit Modal overlay
        if (_showHistoryModal) _buildHistoryModal(),
      ],
    );
  }

  Widget _buildHeader(String subject, String kelas) {
    final compact = _isCompactLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        Row(
          children: [
            const Text(
              'Guru  >  ',
              style: TextStyle(color: AppColors.gray500, fontSize: 13),
            ),
            const Text(
              'Detail Kelas',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => context.goNamed('guru-kelas'),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Kembali ke Daftar Kelas',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$subject - Kelas $kelas',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: AppColors.gray500,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Total: ${_students.length} Siswa',
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (_sessionActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Color(0xFF059669), size: 8),
                          SizedBox(width: 6),
                          Text(
                            'Sesi Absensi Aktif',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: (_sessionActive
                    ? ElevatedButton.icon(
                        onPressed: _endSession,
                        icon: const Icon(Icons.stop_circle_outlined, size: 20),
                        label: const Text(
                          'Akhiri Sesi Pertemuan',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _openSessionDialog,
                        icon: const Icon(Icons.play_circle_outline, size: 20),
                        label: const Text(
                          'Buka Presensi',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      )),
              ),
            ],
          )
        else
          // Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$subject - Kelas $kelas',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          color: AppColors.gray500,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total: ${_students.length} Siswa',
                          style: const TextStyle(
                            color: AppColors.gray500,
                            fontSize: 14,
                          ),
                        ),
                        if (_sessionActive) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF059669),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Sesi Absensi Aktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Toggle Button
              if (_sessionActive)
                ElevatedButton.icon(
                  onPressed: _endSession,
                  icon: const Icon(Icons.stop_circle_outlined, size: 20),
                  label: const Text(
                    'Akhiri Sesi Pertemuan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _openSessionDialog,
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  label: const Text(
                    'Buka Presensi',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  void _openHistoryModal(_PastMeeting history) {
    setState(() {
      _selectedHistory = history;
      _showHistoryModal = true;
    });
  }

  Future<void> _deleteHistory(_PastMeeting history) async {
    if (history.id.isEmpty) {
      _showErrorSnackbar('ID pertemuan tidak valid');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text(
              'Hapus Pertemuan?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            children: [
              const TextSpan(text: 'Pertemuan '),
              TextSpan(
                text: 'ke-${history.pertemuanKe} (${history.materi})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
              const TextSpan(text: ' dan seluruh data absensinya akan '),
              const TextSpan(
                text: 'dihapus permanen',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '.\n\nTindakan ini tidak dapat dibatalkan.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteJurnal(history.id);
      _showSaveSnackbar('Pertemuan berhasil dihapus.');
      await _loadData(); // sync with database
    } catch (e) {
      _showErrorSnackbar('Gagal menghapus pertemuan. Periksa koneksi.');
    }
  }

  // ══════════════════ RIWAYAT PERTEMUAN TAB ════════════════════════════════
  Widget _buildJurnalTab() {
    if (_isCompactLayout(context)) {
      return _buildJurnalTabCompact();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── REAL-TIME ATTENDANCE PANEL (only when session active) ──────
          if (_sessionActive) _buildRealTimeAttendance(),

          const SizedBox(height: 16),

          // ── HISTORY TABLE ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Daftar Riwayat Pertemuan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFF3F4F6)),
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          'Tanggal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          'Pertemuan Ke-',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Materi / KD',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        child: Text(
                          'Ringkasan Kehadiran',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: Text(
                          'Aksi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_histories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Belum ada riwayat pertemuan.',
                        style: TextStyle(color: AppColors.gray500),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _histories.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (_, index) {
                      final h = _histories[index];
                      final hadir = h.students
                          .where((s) => s.status == 'HADIR')
                          .length;
                      final izin = h.students
                          .where((s) => s.status == 'IZIN')
                          .length;
                      final sakit = h.students
                          .where((s) => s.status == 'SAKIT')
                          .length;
                      final alpa = h.students
                          .where((s) => s.status == 'ALPA')
                          .length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 140,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: AppColors.gray500,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    h.date,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Pertemuan ${h.pertemuanKe}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                h.materi,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 320,
                              child: Row(
                                children: [
                                  _buildSummaryText(
                                    'Hadir',
                                    hadir,
                                    const Color(0xFF059669),
                                  ),
                                  _buildSummaryDivider(),
                                  _buildSummaryText(
                                    'Izin',
                                    izin,
                                    const Color(0xFFD97706),
                                  ),
                                  _buildSummaryDivider(),
                                  _buildSummaryText(
                                    'Sakit',
                                    sakit,
                                    const Color(0xFF2563EB),
                                  ),
                                  _buildSummaryDivider(),
                                  _buildSummaryText(
                                    'Alpa',
                                    alpa,
                                    const Color(0xFFDC2626),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              child: Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _openHistoryModal(h),
                                    icon: const Icon(
                                      Icons.remove_red_eye_outlined,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Lihat',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _deleteHistory(h),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Hapus',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(
                                        color: Color(0xFFDC2626),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildJurnalTabCompact() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sessionActive) _buildRealTimeAttendance(),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Daftar Riwayat Pertemuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (_histories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Center(
                      child: Text(
                        'Belum ada riwayat pertemuan.',
                        style: TextStyle(color: AppColors.gray500),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: _histories.map((h) {
                        final hadir = h.students
                            .where((s) => s.status == 'HADIR')
                            .length;
                        final izin = h.students
                            .where((s) => s.status == 'IZIN')
                            .length;
                        final sakit = h.students
                            .where((s) => s.status == 'SAKIT')
                            .length;
                        final alpa = h.students
                            .where((s) => s.status == 'ALPA')
                            .length;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: AppColors.gray500,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      h.date,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Pertemuan ${h.pertemuanKe}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                h.materi,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _summaryChip(
                                    'Hadir',
                                    hadir,
                                    const Color(0xFF059669),
                                  ),
                                  _summaryChip(
                                    'Izin',
                                    izin,
                                    const Color(0xFFD97706),
                                  ),
                                  _summaryChip(
                                    'Sakit',
                                    sakit,
                                    const Color(0xFF2563EB),
                                  ),
                                  _summaryChip(
                                    'Alpa',
                                    alpa,
                                    const Color(0xFFDC2626),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _openHistoryModal(h),
                                    icon: const Icon(
                                      Icons.remove_red_eye_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Lihat'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _deleteHistory(h),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                    ),
                                    label: const Text('Hapus'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(
                                        color: Color(0xFFDC2626),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Real-time Attendance Management Panel ──────────────────────────────────
  Widget _buildRealTimeAttendance() {
    if (_isCompactLayout(context)) {
      return _buildRealTimeAttendanceCompact();
    }

    final hadirCount = _students.where((s) => s.status == 'HADIR').length;
    final izinCount = _students.where((s) => s.status == 'IZIN').length;
    final sakitCount = _students.where((s) => s.status == 'SAKIT').length;
    final alpaCount = _students.where((s) => s.status == 'ALPA').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Header ─
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                const Text(
                  'Manajemen Absensi Real-time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                // Live counters
                _liveCounter(
                  'Hadir',
                  hadirCount,
                  const Color(0xFF059669),
                  const Color(0xFFD1FAE5),
                ),
                const SizedBox(width: 8),
                _liveCounter(
                  'Izin',
                  izinCount,
                  const Color(0xFFD97706),
                  const Color(0xFFFEF3C7),
                ),
                const SizedBox(width: 8),
                _liveCounter(
                  'Sakit',
                  sakitCount,
                  const Color(0xFF2563EB),
                  const Color(0xFFDBEAFE),
                ),
                const SizedBox(width: 8),
                _liveCounter(
                  'Alpa',
                  alpaCount,
                  const Color(0xFFDC2626),
                  const Color(0xFFFEE2E2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              'Pertemuan ke-$_activePertemuanKe  •  $_activeMateri',
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
          ),

          // ─ Table Header ─
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.primary,
            child: const Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    'No',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    'Foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Nama Siswa',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Text(
                    'NISN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Waktu Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: Text(
                    'Aksi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─ Student Rows ─
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
            itemBuilder: (_, idx) {
              final s = _students[idx];
              final isOdd = idx % 2 == 1;
              return Container(
                color: isOdd ? const Color(0xFFF9FAFB) : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // No
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                    // Avatar
                    SizedBox(
                      width: 48,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          s.name[0],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    // Name
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // NISN
                    SizedBox(
                      width: 130,
                      child: Text(
                        s.nisn,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    // Waktu Scan
                    SizedBox(
                      width: 100,
                      child: s.status == 'HADIR'
                          ? Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 13,
                                  color: AppColors.gray500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(7 + idx ~/ 6).toString().padLeft(2, '0')}:${((idx * 3) % 60).toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              '–',
                              style: TextStyle(color: AppColors.gray400),
                            ),
                    ),
                    // Status badge
                    SizedBox(width: 80, child: _statusBadge(s.status)),
                    // 4-Button Actions
                    SizedBox(
                      width: 260,
                      child: Row(
                        children: [
                          _attendanceBtn(
                            'Hadir',
                            s.status == 'HADIR',
                            const Color(0xFF059669),
                            const Color(0xFFD1FAE5),
                            () => setState(() => s.status = 'HADIR'),
                          ),
                          const SizedBox(width: 6),
                          _attendanceBtn(
                            'Izin',
                            s.status == 'IZIN',
                            const Color(0xFFD97706),
                            const Color(0xFFFEF3C7),
                            () => setState(() => s.status = 'IZIN'),
                          ),
                          const SizedBox(width: 6),
                          _attendanceBtn(
                            'Sakit',
                            s.status == 'SAKIT',
                            const Color(0xFF2563EB),
                            const Color(0xFFDBEAFE),
                            () => setState(() => s.status = 'SAKIT'),
                          ),
                          const SizedBox(width: 6),
                          _attendanceBtn(
                            'Alpa',
                            s.status == 'ALPA',
                            const Color(0xFFDC2626),
                            const Color(0xFFFEE2E2),
                            () => setState(() => s.status = 'ALPA'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ─ Save Button ─
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_students.length} siswa',
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _saveAttendanceChanges,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text(
                    'Simpan Perubahan Absensi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeAttendanceCompact() {
    final hadirCount = _students.where((s) => s.status == 'HADIR').length;
    final izinCount = _students.where((s) => s.status == 'IZIN').length;
    final sakitCount = _students.where((s) => s.status == 'SAKIT').length;
    final alpaCount = _students.where((s) => s.status == 'ALPA').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manajemen Absensi Real-time',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _liveCounter(
                      'Hadir',
                      hadirCount,
                      const Color(0xFF059669),
                      const Color(0xFFD1FAE5),
                    ),
                    _liveCounter(
                      'Izin',
                      izinCount,
                      const Color(0xFFD97706),
                      const Color(0xFFFEF3C7),
                    ),
                    _liveCounter(
                      'Sakit',
                      sakitCount,
                      const Color(0xFF2563EB),
                      const Color(0xFFDBEAFE),
                    ),
                    _liveCounter(
                      'Alpa',
                      alpaCount,
                      const Color(0xFFDC2626),
                      const Color(0xFFFEE2E2),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Pertemuan ke-$_activePertemuanKe • $_activeMateri',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
            itemBuilder: (_, idx) {
              final s = _students[idx];
              final timeText = s.status == 'HADIR'
                  ? '${(7 + idx ~/ 6).toString().padLeft(2, '0')}:${((idx * 3) % 60).toString().padLeft(2, '0')}'
                  : '–';
              final initial = s.name.isNotEmpty ? s.name[0] : '-';
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foreground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.nisn,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray500,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(s.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _attendanceBtn(
                          'Hadir',
                          s.status == 'HADIR',
                          const Color(0xFF059669),
                          const Color(0xFFD1FAE5),
                          () => setState(() => s.status = 'HADIR'),
                        ),
                        _attendanceBtn(
                          'Izin',
                          s.status == 'IZIN',
                          const Color(0xFFD97706),
                          const Color(0xFFFEF3C7),
                          () => setState(() => s.status = 'IZIN'),
                        ),
                        _attendanceBtn(
                          'Sakit',
                          s.status == 'SAKIT',
                          const Color(0xFF2563EB),
                          const Color(0xFFDBEAFE),
                          () => setState(() => s.status = 'SAKIT'),
                        ),
                        _attendanceBtn(
                          'Alpa',
                          s.status == 'ALPA',
                          const Color(0xFFDC2626),
                          const Color(0xFFFEE2E2),
                          () => setState(() => s.status = 'ALPA'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_students.length} siswa',
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveAttendanceChanges,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text(
                      'Simpan Perubahan Absensi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
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

  Widget _liveCounter(String label, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceBtn(
    String label,
    bool isActive,
    Color activeColor,
    Color activeBg,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeBg : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? activeColor : AppColors.gray500,
          ),
        ),
      ),
    );
  }

  Future<void> _saveAttendanceChanges() async {
    if (_students.isEmpty) return;
    final jadwalId = _activeJadwalId.isNotEmpty
        ? _activeJadwalId
        : (_scheduleIds.isNotEmpty ? _scheduleIds.first : '');
    final tanggal = _activeTanggal.isNotEmpty ? _activeTanggal : _todayString();

    if (jadwalId.isEmpty) {
      _showErrorSnackbar('Tidak ada sesi aktif untuk disimpan');
      return;
    }
    try {
      await ApiService.saveBatchAttendance({
        'jadwalId': jadwalId,
        'tanggal': tanggal,
        'pertemuanKe': _activePertemuanKe,
        'topik': _activeMateri,
        'records': _students
            .map((s) => {'siswaId': s.id, 'status': s.status})
            .toList(),
      });
      _showSaveSnackbar('Perubahan absensi berhasil disimpan!');
      await _loadData();
    } catch (e) {
      _showErrorSnackbar('Gagal menyimpan absensi. Periksa koneksi.');
    }
  }

  Widget _buildSummaryText(String label, int count, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '|',
        style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHistoryModal() {
    if (_selectedHistory == null) return const SizedBox();
    final h = _selectedHistory!;
    final hadirCount = h.students.where((s) => s.status == 'HADIR').length;
    final izinCount = h.students.where((s) => s.status == 'IZIN').length;
    final sakitCount = h.students.where((s) => s.status == 'SAKIT').length;
    final alpaCount = h.students.where((s) => s.status == 'ALPA').length;

    return GestureDetector(
      onTap: () => setState(() => _showHistoryModal = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 780,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─ Modal Header ─
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF3F4F6)),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Absensi – ${h.date}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pertemuan ${h.pertemuanKe}  •  ${h.materi}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _showHistoryModal = false;
                          _selectedHistory = null;
                        }),
                      ),
                    ],
                  ),
                ),

                // ─ Body ─
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stat boxes
                        Row(
                          children: [
                            _modalStatBox(
                              'Hadir',
                              hadirCount,
                              const Color(0xFF15803D),
                              const Color(0xFFF0FDF4),
                              const Color(0xFFBBF7D0),
                            ),
                            const SizedBox(width: 12),
                            _modalStatBox(
                              'Izin',
                              izinCount,
                              const Color(0xFFB45309),
                              const Color(0xFFFFFBEB),
                              const Color(0xFFFDE68A),
                            ),
                            const SizedBox(width: 12),
                            _modalStatBox(
                              'Sakit',
                              sakitCount,
                              const Color(0xFF1D4ED8),
                              const Color(0xFFEFF6FF),
                              const Color(0xFFBFDBFE),
                            ),
                            const SizedBox(width: 12),
                            _modalStatBox(
                              'Alpa',
                              alpaCount,
                              const Color(0xFFB91C1C),
                              const Color(0xFFFFF5F5),
                              const Color(0xFFFECACA),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '#',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'NAMA SISWA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Text(
                                  'NISN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'SCAN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  'STATUS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'UBAH',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Table rows
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: h.students.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final s = entry.value;
                              final isOdd = idx % 2 == 1;
                              return Container(
                                color: isOdd
                                    ? const Color(0xFFF9FAFB)
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.gray500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            child: Text(
                                              s.name[0],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              s.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        s.nisn,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.gray500,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: s.status == 'HADIR'
                                          ? Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  size: 13,
                                                  color: AppColors.gray500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '07:${10 + idx}:${20 + idx}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.gray600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Text(
                                              '–',
                                              style: TextStyle(
                                                color: AppColors.gray400,
                                              ),
                                            ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: _statusBadge(s.status),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: _buildHistoryStatusDropdown(h, s),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─ Footer ─
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _showHistoryModal = false;
                          _selectedHistory = null;
                        }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.foreground,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          _showSaveSnackbar(
                            'Perubahan data absensi berhasil disimpan!',
                          );
                          setState(() {
                            _showHistoryModal = false;
                            _selectedHistory = null;
                          });
                        },
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalStatBox(
    String label,
    int count,
    Color textColor,
    Color bgColor,
    Color borderColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final Map<String, List<Color>> colors = {
      'HADIR': [const Color(0xFFDCFCE7), const Color(0xFF15803D)],
      'IZIN': [const Color(0xFFFEF3C7), const Color(0xFFB45309)],
      'SAKIT': [const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)],
      'ALPA': [const Color(0xFFFEE2E2), const Color(0xFFB91C1C)],
    };
    final c = colors[status] ?? [const Color(0xFFF3F4F6), AppColors.gray600];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c[0],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c[1],
        ),
      ),
    );
  }

  Widget _buildHistoryStatusDropdown(_PastMeeting h, _Student s) {
    const statuses = ['HADIR', 'SAKIT', 'IZIN', 'ALPA'];
    return DropdownButton<String>(
      value: s.status,
      isDense: true,
      underline: const SizedBox(),
      items: statuses
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(v, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => s.status = val);
      },
    );
  }

  // ══════════════════ REKAPITULASI TAB ════════════════════════════════════
  Widget _buildRekapTab() {
    final totalPertemuan = _totalPertemuanDibuat > 0
        ? _totalPertemuanDibuat
        : (_recapStudents.isNotEmpty
              ? _recapStudents.first.attendance.length
              : 0);
    if (_isCompactLayout(context)) {
      return _buildRekapTabCompact(totalPertemuan);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Header Card ─
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.table_rows_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                const Text(
                  'Rekapitulasi Kehadiran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text(
                    'Cetak PDF',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: () => _showSaveSnackbar(
                    'Rekapitulasi sedang dicetak ke PDF...',
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text(
                    'Export Excel',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: () =>
                      _showSaveSnackbar('Rekapitulasi diekspor ke Excel!'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─ Matrix Table ─
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.primary),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                dataRowMinHeight: 40,
                dataRowMaxHeight: 48,
                columnSpacing: 8,
                columns: [
                  const DataColumn(
                    label: SizedBox(width: 30, child: Text('No')),
                  ),
                  const DataColumn(
                    label: SizedBox(width: 110, child: Text('NISN')),
                  ),
                  const DataColumn(
                    label: SizedBox(width: 160, child: Text('Nama Siswa')),
                  ),
                  ...List.generate(
                    totalPertemuan,
                    (i) => DataColumn(
                      label: SizedBox(width: 36, child: Text('P${i + 1}')),
                    ),
                  ),
                  const DataColumn(
                    label: SizedBox(
                      width: 60,
                      child: Text(
                        'Hadir',
                        style: TextStyle(color: Color(0xFF86EFAC)),
                      ),
                    ),
                  ),
                  const DataColumn(
                    label: SizedBox(
                      width: 50,
                      child: Text(
                        'Izin',
                        style: TextStyle(color: Color(0xFFFDE68A)),
                      ),
                    ),
                  ),
                  const DataColumn(
                    label: SizedBox(
                      width: 50,
                      child: Text(
                        'Sakit',
                        style: TextStyle(color: Color(0xFFBFDBFE)),
                      ),
                    ),
                  ),
                  const DataColumn(
                    label: SizedBox(
                      width: 50,
                      child: Text(
                        'Alpa',
                        style: TextStyle(color: Color(0xFFFCA5A5)),
                      ),
                    ),
                  ),
                  const DataColumn(
                    label: SizedBox(
                      width: 55,
                      child: Text(
                        '%',
                        style: TextStyle(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
                rows: _recapStudents.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final Color pctColor = s.persentase >= 90
                      ? const Color(0xFF15803D)
                      : s.persentase >= 75
                      ? const Color(0xFFB45309)
                      : const Color(0xFFB91C1C);
                  final Color pctBg = s.persentase >= 90
                      ? const Color(0xFFF0FDF4)
                      : s.persentase >= 75
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFFEE2E2);
                  return DataRow(
                    color: WidgetStateProperty.all(
                      idx % 2 == 0 ? Colors.white : const Color(0xFFF9FAFB),
                    ),
                    cells: [
                      DataCell(
                        Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          s.nisn,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...s.attendance.map(
                        (code) => DataCell(_attendanceCell(code)),
                      ),
                      DataCell(
                        _rekapTotalCell(
                          '${s.totalHadir}',
                          const Color(0xFF15803D),
                          const Color(0xFFF0FDF4),
                        ),
                      ),
                      DataCell(
                        _rekapTotalCell(
                          '${s.totalIzin}',
                          const Color(0xFFB45309),
                          const Color(0xFFFFFBEB),
                        ),
                      ),
                      DataCell(
                        _rekapTotalCell(
                          '${s.totalSakit}',
                          const Color(0xFF1D4ED8),
                          const Color(0xFFEFF6FF),
                        ),
                      ),
                      DataCell(
                        _rekapTotalCell(
                          '${s.totalAlpa}',
                          const Color(0xFFB91C1C),
                          s.totalAlpa > 3
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFFF5F5),
                        ),
                      ),
                      DataCell(
                        _rekapTotalCell('${s.persentase}%', pctColor, pctBg),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─ Legend ─
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legendItem(
                'H',
                'Hadir',
                const Color(0xFF059669),
                const Color(0xFFDCFCE7),
              ),
              _legendItem(
                'I',
                'Izin',
                const Color(0xFFB45309),
                const Color(0xFFFEF3C7),
              ),
              _legendItem(
                'S',
                'Sakit',
                const Color(0xFF1D4ED8),
                const Color(0xFFDBEAFE),
              ),
              _legendItem(
                'A',
                'Alpa',
                const Color(0xFFB91C1C),
                const Color(0xFFFEE2E2),
              ),
              _legendItem(
                '-',
                'Kosong',
                AppColors.gray500,
                const Color(0xFFF3F4F6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRekapTabCompact(int totalPertemuan) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.table_rows_rounded, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rekapitulasi Kehadiran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text(
                        'Cetak PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () => _showSaveSnackbar(
                        'Rekapitulasi sedang dicetak ke PDF...',
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text(
                        'Export Excel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () =>
                          _showSaveSnackbar('Rekapitulasi diekspor ke Excel!'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._recapStudents.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final Color pctColor = s.persentase >= 90
                ? const Color(0xFF15803D)
                : s.persentase >= 75
                ? const Color(0xFFB45309)
                : const Color(0xFFB91C1C);
            final Color pctBg = s.persentase >= 90
                ? const Color(0xFFF0FDF4)
                : s.persentase >= 75
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFFEE2E2);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${idx + 1}.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              s.nisn,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _rekapTotalCell('${s.persentase}%', pctColor, pctBg),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < totalPertemuan; i++) ...[
                          _attendanceCell(
                            i < s.attendance.length ? s.attendance[i] : '-',
                          ),
                          if (i != totalPertemuan - 1) const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _summaryChip(
                        'Hadir',
                        s.totalHadir,
                        const Color(0xFF059669),
                      ),
                      _summaryChip(
                        'Izin',
                        s.totalIzin,
                        const Color(0xFFB45309),
                      ),
                      _summaryChip(
                        'Sakit',
                        s.totalSakit,
                        const Color(0xFF1D4ED8),
                      ),
                      _summaryChip(
                        'Alpa',
                        s.totalAlpa,
                        const Color(0xFFB91C1C),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legendItem(
                'H',
                'Hadir',
                const Color(0xFF059669),
                const Color(0xFFDCFCE7),
              ),
              _legendItem(
                'I',
                'Izin',
                const Color(0xFFB45309),
                const Color(0xFFFEF3C7),
              ),
              _legendItem(
                'S',
                'Sakit',
                const Color(0xFF1D4ED8),
                const Color(0xFFDBEAFE),
              ),
              _legendItem(
                'A',
                'Alpa',
                const Color(0xFFB91C1C),
                const Color(0xFFFEE2E2),
              ),
              _legendItem(
                '-',
                'Kosong',
                AppColors.gray500,
                const Color(0xFFF3F4F6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendanceCell(String code) {
    final Map<String, List<Color>> colors = {
      'H': [const Color(0xFFDCFCE7), const Color(0xFF15803D)],
      'I': [const Color(0xFFFEF3C7), const Color(0xFFB45309)],
      'S': [const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)],
      'A': [const Color(0xFFFEE2E2), const Color(0xFFB91C1C)],
      '-': [const Color(0xFFF3F4F6), AppColors.gray400],
    };
    final c = colors[code] ?? colors['-']!;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c[0],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c[1].withValues(alpha: 0.35)),
      ),
      child: Text(
        code == 'H' ? '✓' : code,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c[1],
        ),
      ),
    );
  }

  Widget _rekapTotalCell(String value, Color fg, Color bg) {
    return Container(
      width: 36,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _legendItem(String code, String label, Color fg, Color bg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            code == 'H' ? '✓' : code,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.gray600),
        ),
      ],
    );
  }

  // ══════════════════ NILAI TAB ══════════════════════════════════════════
  Widget _buildNilaiTab() {
    double calculateNa(g) => g.getNaValue(
      _bobotTugas,
      _bobotUH,
      _bobotUTS,
      _bobotUAS,
      _bobotKeaktifan,
      _bobotKehadiran,
    );
    final avg = _grades.isEmpty
        ? 0.0
        : _grades.map(calculateNa).reduce((a, b) => a + b) / _grades.length;

    if (_isCompactLayout(context)) {
      return _buildNilaiTabCompact(avg);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Bobot info ─
          _buildBobotCard(),
          const SizedBox(height: 20),

          // ─ Stats row ─
          Row(
            children: [
              _nilaiStatCard(
                'Rata-rata Kelas',
                avg.toStringAsFixed(1),
                Icons.bar_chart,
                AppColors.primary,
              ),
              const SizedBox(width: 12),
              _nilaiStatCard(
                'Nilai Tertinggi',
                _grades.isEmpty
                    ? '0.0'
                    : _grades
                          .map(
                            (g) => g.getNaValue(
                              _bobotTugas,
                              _bobotUH,
                              _bobotUTS,
                              _bobotUAS,
                              _bobotKeaktifan,
                              _bobotKehadiran,
                            ),
                          )
                          .reduce(max)
                          .toStringAsFixed(1),
                Icons.trending_up,
                const Color(0xFF059669),
              ),
              const SizedBox(width: 12),
              _nilaiStatCard(
                'Nilai Terendah',
                _grades.isEmpty
                    ? '0.0'
                    : _grades
                          .map(
                            (g) => g.getNaValue(
                              _bobotTugas,
                              _bobotUH,
                              _bobotUTS,
                              _bobotUAS,
                              _bobotKeaktifan,
                              _bobotKehadiran,
                            ),
                          )
                          .reduce(min)
                          .toStringAsFixed(1),
                Icons.trending_down,
                const Color(0xFFDC2626),
              ),
              const SizedBox(width: 12),
              _nilaiStatCard(
                'Lulus (≥70)',
                '${_grades.where((g) => g.getNaValue(_bobotTugas, _bobotUH, _bobotUTS, _bobotUAS, _bobotKeaktifan, _bobotKehadiran) >= 70).length}/${_grades.length}',
                Icons.check_circle_outline,
                const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─ Save success toast ─
          if (_gradesSaved)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF059669),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Nilai berhasil disimpan!',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // ─ Table ─
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.table_chart_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tabel Nilai Siswa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text(
                          'Simpan Semua Nilai',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: _saveGrades,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Column headers
                Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 32,
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'NAMA SISWA',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _NilaiHeader(
                        'TUGAS (${_bobotTugas.toInt()}%)',
                        width: 110,
                      ),
                      _NilaiHeader('UH (${_bobotUH.toInt()}%)', width: 100),
                      _NilaiHeader('UTS (${_bobotUTS.toInt()}%)', width: 100),
                      _NilaiHeader('UAS (${_bobotUAS.toInt()}%)', width: 100),
                      _NilaiHeader(
                        'KEAKTIFAN (${_bobotKeaktifan.toInt()}%)',
                        width: 120,
                      ),
                      NilaiHeaderAuto(
                        'KEHADIRAN (${_bobotKehadiran.toInt()}%)',
                        width: 140,
                      ),
                      const _NilaiHeader('NA', width: 70),
                      const _NilaiHeader('GRADE', width: 70),
                    ],
                  ),
                ),
                const Divider(height: 1),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _grades.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (ctx, i) => _buildGradeRow(_grades[i], i),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNilaiTabCompact(double avg) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBobotCard(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 520;
              final itemWidth = twoColumns
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _compactNilaiStatCard(
                      'Rata-rata Kelas',
                      avg.toStringAsFixed(1),
                      Icons.bar_chart,
                      AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _compactNilaiStatCard(
                      'Nilai Tertinggi',
                      _grades.isEmpty
                          ? '0.0'
                          : _grades
                                .map(
                                  (g) => g.getNaValue(
                                    _bobotTugas,
                                    _bobotUH,
                                    _bobotUTS,
                                    _bobotUAS,
                                    _bobotKeaktifan,
                                    _bobotKehadiran,
                                  ),
                                )
                                .reduce(max)
                                .toStringAsFixed(1),
                      Icons.trending_up,
                      const Color(0xFF059669),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _compactNilaiStatCard(
                      'Nilai Terendah',
                      _grades.isEmpty
                          ? '0.0'
                          : _grades
                                .map(
                                  (g) => g.getNaValue(
                                    _bobotTugas,
                                    _bobotUH,
                                    _bobotUTS,
                                    _bobotUAS,
                                    _bobotKeaktifan,
                                    _bobotKehadiran,
                                  ),
                                )
                                .reduce(min)
                                .toStringAsFixed(1),
                      Icons.trending_down,
                      const Color(0xFFDC2626),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _compactNilaiStatCard(
                      'Lulus (≥70)',
                      '${_grades.where((g) => g.getNaValue(_bobotTugas, _bobotUH, _bobotUTS, _bobotUAS, _bobotKeaktifan, _bobotKehadiran) >= 70).length}/${_grades.length}',
                      Icons.check_circle_outline,
                      const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (_gradesSaved)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF059669),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nilai berhasil disimpan!',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.table_chart_outlined,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tabel Nilai Siswa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.save_outlined, size: 16),
                          label: const Text(
                            'Simpan Semua Nilai',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: _saveGrades,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _grades
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildGradeCard(entry.value, entry.key),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBobotCard() {
    final totalBobot = _getTotalBobot();
    final totalBobotLabel = totalBobot == 100
        ? 'Total: 100% ✓'
        : 'Total: ${totalBobot.toInt()}% (Harus 100%)';
    final totalBobotColor = totalBobot == 100
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Persentase Bobot Penilaian',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                totalBobotLabel,
                style: TextStyle(
                  color: totalBobotColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Semua bobot dijumlahkan harus tepat 100%. Bobot Kehadiran dihitung otomatis dari data absensi.',
            style: const TextStyle(fontSize: 11, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),

          _buildBobotInputSection(),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.gray400, size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Klik baris pada tabel untuk mulai mengedit. Nilai kehadiran dihitung otomatis dari data absensi.',
                  style: TextStyle(color: AppColors.gray500, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getTotalBobot() =>
      _bobotTugas +
      _bobotUH +
      _bobotUTS +
      _bobotUAS +
      _bobotKeaktifan +
      _bobotKehadiran;

  Widget _buildBobotInputSection() {
    if (!_isCompactLayout(context)) {
      return Column(
        children: [
          Row(
            children: [
              _bobotInput(
                'Tugas',
                _bobotTugas,
                (v) => setState(() => _bobotTugas = v),
              ),
              const SizedBox(width: 12),
              _bobotInput('UH', _bobotUH, (v) => setState(() => _bobotUH = v)),
              const SizedBox(width: 12),
              _bobotInput(
                'UTS',
                _bobotUTS,
                (v) => setState(() => _bobotUTS = v),
              ),
              const SizedBox(width: 12),
              _bobotInput(
                'UAS',
                _bobotUAS,
                (v) => setState(() => _bobotUAS = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _bobotInput(
                'Keaktifan',
                _bobotKeaktifan,
                (v) => setState(() => _bobotKeaktifan = v),
              ),
              const SizedBox(width: 12),
              _bobotInput(
                'Kehadiran',
                _bobotKehadiran,
                (v) => setState(() => _bobotKehadiran = v),
              ),
              const Spacer(),
              const Spacer(),
            ],
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        final itemWidth = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _bobotInputBox(
                'Tugas',
                _bobotTugas,
                (v) => setState(() => _bobotTugas = v),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _bobotInputBox(
                'UH',
                _bobotUH,
                (v) => setState(() => _bobotUH = v),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _bobotInputBox(
                'UTS',
                _bobotUTS,
                (v) => setState(() => _bobotUTS = v),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _bobotInputBox(
                'UAS',
                _bobotUAS,
                (v) => setState(() => _bobotUAS = v),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _bobotInputBox(
                'Keaktifan',
                _bobotKeaktifan,
                (v) => setState(() => _bobotKeaktifan = v),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _bobotInputBox(
                'Kehadiran',
                _bobotKehadiran,
                (v) => setState(() => _bobotKehadiran = v),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bobotInput(String label, double value, Function(double) onChanged) {
    return Expanded(child: _bobotInputBox(label, value, onChanged));
  }

  Widget _bobotInputBox(
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (%)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value.toStringAsFixed(0),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (val) {
            final parsed = double.tryParse(val);
            if (parsed != null) onChanged(parsed);
            if (val.isEmpty) onChanged(0);
          },
        ),
      ],
    );
  }

  Widget _nilaiStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
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

  Widget _compactNilaiStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
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
    );
  }

  Widget _buildGradeCard(_GradeRow g, int idx) {
    final na = g.getNaValue(
      _bobotTugas,
      _bobotUH,
      _bobotUTS,
      _bobotUAS,
      _bobotKeaktifan,
      _bobotKehadiran,
    );
    final passed = na >= 70;
    final grade = g.getGrade(na);
    final Color gradeColor = switch (grade) {
      'A' => const Color(0xFF059669),
      'B' => const Color(0xFF2563EB),
      'C' => const Color(0xFFD97706),
      _ => const Color(0xFFDC2626),
    };
    final Color kehadiranColor = g.kehadiran >= 90
        ? const Color(0xFF059669)
        : g.kehadiran >= 75
        ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);
    final initial = g.name.isNotEmpty ? g.name[0] : '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 520;
          final itemWidth = twoColumns
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${idx + 1}. ${g.name}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'NISN: ${g.nisn}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _gradeInputField(
                      'Tugas (${_bobotTugas.toInt()}%)',
                      _ctrl('${g.nisn}-tugas', g.tugas),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _gradeInputField(
                      'UH (${_bobotUH.toInt()}%)',
                      _ctrl('${g.nisn}-uh', g.uh),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _gradeInputField(
                      'UTS (${_bobotUTS.toInt()}%)',
                      _ctrl('${g.nisn}-uts', g.uts),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _gradeInputField(
                      'UAS (${_bobotUAS.toInt()}%)',
                      _ctrl('${g.nisn}-uas', g.uas),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _gradeInputField(
                      'Keaktifan (${_bobotKeaktifan.toInt()}%)',
                      _ctrl('${g.nisn}-keaktifan', g.keaktifan),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _gradeMetric(
                    'Kehadiran',
                    '${g.kehadiran.toStringAsFixed(0)}%',
                    kehadiranColor,
                  ),
                  _gradeMetric(
                    'NA',
                    na.toStringAsFixed(1),
                    passed ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                  _gradeMetric('Grade', grade, gradeColor),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _gradeInputField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradeMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildGradeRow(_GradeRow g, int idx) {
    final isEditing = _editingId == g.nisn;
    final na = g.getNaValue(
      _bobotTugas,
      _bobotUH,
      _bobotUTS,
      _bobotUAS,
      _bobotKeaktifan,
      _bobotKehadiran,
    );
    final passed = na >= 70;

    final Color gradeColor;
    switch (g.getGrade(na)) {
      case 'A':
        gradeColor = const Color(0xFF059669);
        break;
      case 'B':
        gradeColor = const Color(0xFF2563EB);
        break;
      case 'C':
        gradeColor = const Color(0xFFD97706);
        break;
      default:
        gradeColor = const Color(0xFFDC2626);
    }

    // Kehadiran color coding
    final Color kehadiranColor;
    if (g.kehadiran >= 90) {
      kehadiranColor = const Color(0xFF059669);
    } else if (g.kehadiran >= 75) {
      kehadiranColor = const Color(0xFFD97706);
    } else {
      kehadiranColor = const Color(0xFFDC2626);
    }

    return GestureDetector(
      onTap: () => setState(() => _editingId = isEditing ? '' : g.nisn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isEditing ? const Color(0xFFF0F7FF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${idx + 1}',
                style: const TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      g.name[0],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      g.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isEditing) ...[
              _editableNilaiCell(_ctrl('${g.nisn}-tugas', g.tugas), 110),
              _editableNilaiCell(_ctrl('${g.nisn}-uh', g.uh), 100),
              _editableNilaiCell(_ctrl('${g.nisn}-uts', g.uts), 100),
              _editableNilaiCell(_ctrl('${g.nisn}-uas', g.uas), 100),
              _editableNilaiCell(
                _ctrl('${g.nisn}-keaktifan', g.keaktifan),
                120,
              ),
            ] else ...[
              _nilaiCell(g.tugas.toStringAsFixed(0), 110, passed),
              _nilaiCell(g.uh.toStringAsFixed(0), 100, passed),
              _nilaiCell(g.uts.toStringAsFixed(0), 100, passed),
              _nilaiCell(g.uas.toStringAsFixed(0), 100, passed),
              _nilaiCell(
                g.keaktifan.toStringAsFixed(0),
                120,
                g.keaktifan >= 70,
              ),
            ],
            // Kehadiran — read-only, auto dari absensi
            SizedBox(
              width: 140,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kehadiranColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kehadiranColor.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outlined,
                          size: 11,
                          color: kehadiranColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${g.kehadiran.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kehadiranColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // NA
            SizedBox(
              width: 70,
              child: Text(
                na.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: passed
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
            // Grade badge
            SizedBox(
              width: 70,
              child: Container(
                width: 32,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  g.getGrade(na),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: gradeColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nilaiCell(String value, double width, bool ok) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          color: ok ? AppColors.foreground : const Color(0xFFDC2626),
        ),
      ),
    );
  }

  Widget _editableNilaiCell(TextEditingController ctrl, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════ QR MODAL ═══════════════════════════════════════════
  Widget _buildQRModal() {
    final minutes = (_qrCountdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_qrCountdown % 60).toString().padLeft(2, '0');
    final isUrgent = _qrCountdown <= 30;
    final timerColor = isUrgent
        ? const Color(0xFFDC2626)
        : const Color(0xFF059669);

    return GestureDetector(
      onTap: () {}, // Don't close on outer tap — session stays active
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            width: 440,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─ Header bar ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6EE7B7),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Sesi Absensi Aktif',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Close (minimize only — session still runs)
                      GestureDetector(
                        onTap: _closeQRModal,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.minimize_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─ Body ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Column(
                    children: [
                      // Title
                      const Text(
                        'QR Absensi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pertemuan ke-$_activePertemuanKe  •  $_activeMateri',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),

                      // ── Progress bar + timer ──
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _qrCountdown / 180,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 15,
                            color: timerColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'QR diperbarui dalam $minutes:$seconds',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: timerColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── QR Code (token NOT exposed) ──
                      Container(
                        width: 260,
                        height: 260,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _generatedQR,
                          version: QrVersions.auto,
                          size: 240,
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Siswa scan melalui aplikasi mobile masing-masing',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Session Info Grid ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            _qrInfoCell('Pertemuan Ke-', '$_activePertemuanKe'),
                            const _QRInfoDivider(),
                            _qrInfoCell(
                              'Waktu Mulai',
                              _sessionStartTime != null
                                  ? '${_sessionStartTime!.hour.toString().padLeft(2, '0')}:${_sessionStartTime!.minute.toString().padLeft(2, '0')}'
                                  : '--:--',
                            ),
                            const _QRInfoDivider(),
                            _qrInfoCell(
                              'Hadir',
                              '${_students.where((s) => s.status == 'HADIR').length}/${_students.length}',
                            ),
                          ],
                        ),
                      ),
                      if (_activeMateri.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              const Text(
                                'Materi: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray500,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _activeMateri,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // ─ Footer ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _endSession,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text(
                      'Akhiri Sesi Pertemuan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _qrInfoCell(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.gray500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _showSaveSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(msg),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(msg),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Column header helper ────────────────────────────────────────────────────
class _NilaiHeader extends StatelessWidget {
  final String text;
  final double width;
  const _NilaiHeader(this.text, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.gray500,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Auto-calculated (read-only) column header – purple tint
class NilaiHeaderAuto extends StatelessWidget {
  final String text;
  final double width;
  const NilaiHeaderAuto(this.text, {super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF7C3AED),
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── QR Info Divider helper ────────────────────────────────────────────────────
class _QRInfoDivider extends StatelessWidget {
  const _QRInfoDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
