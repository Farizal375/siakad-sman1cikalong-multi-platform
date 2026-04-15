// File: lib/features/guru/screens/class_detail.dart
// ===========================================
// CLASS DETAIL – Jurnal/Absensi & Input Nilai
// FR-04.1 – FR-04.6
// ===========================================

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

// ── Mock Data ──────────────────────────────────────────────────────────────
class _Student {
  final String id, name, nisn;
  String status; // HADIR / SAKIT / IZIN / ALPA
  _Student({required this.id, required this.name, required this.nisn, this.status = 'ALPA'});
}

class _GradeRow {
  final String name, nisn;
  double tugas, uh, uts, uas;
  double keaktifan;          // input guru
  final double kehadiran;    // auto dari absensi, read-only
  _GradeRow({
    required this.name,
    required this.nisn,
    this.tugas = 0,
    this.uh = 0,
    this.uts = 0,
    this.uas = 0,
    this.keaktifan = 80,
    this.kehadiran = 0,     // dihitung otomatis
  });
  double getNaValue(
    double wTugas, double wUh, double wUts, double wUas,
    double wKeaktifan, double wKehadiran,
  ) {
    return (tugas     * wTugas     / 100)
         + (uh        * wUh        / 100)
         + (uts       * wUts       / 100)
         + (uas       * wUas       / 100)
         + (keaktifan * wKeaktifan / 100)
         + (kehadiran * wKehadiran / 100);
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
  _PastMeeting({required this.id, required this.date, required this.pertemuanKe, required this.materi, required this.students});
}

class _RecapStudent {
  final String name, nisn;
  final List<String> attendance; // 'H', 'I', 'S', 'A', '-'
  _RecapStudent({required this.name, required this.nisn, required this.attendance});

  int get totalHadir => attendance.where((a) => a == 'H').length;
  int get totalIzin  => attendance.where((a) => a == 'I').length;
  int get totalSakit => attendance.where((a) => a == 'S').length;
  int get totalAlpa  => attendance.where((a) => a == 'A').length;
}

// ── Main Screen ────────────────────────────────────────────────────────────
class ClassDetail extends StatefulWidget {
  final String classId;
  const ClassDetail({super.key, required this.classId});

  @override
  State<ClassDetail> createState() => _ClassDetailState();
}

class _ClassDetailState extends State<ClassDetail> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Jurnal tab state
  bool _sessionOpen = false;
  String _sessionTopic = '';
  String _sessionDesc = '';
  String _sessionPertemuan = '';
  String _generatedQR = '';
  Timer? _qrTimer;
  int _qrCountdown = 60;
  bool _showQRModal = false;

  // Edit History state
  bool _showHistoryModal = false;
  _PastMeeting? _selectedHistory;

  final List<_Student> _students = List.generate(
    18,
    (i) => _Student(
      id: 'S${(i + 1).toString().padLeft(3, '0')}',
      name: [
        'Ahmad Fauzi', 'Budi Santoso', 'Citra Dewi', 'Dian Pratama', 'Eka Rahayu',
        'Fajar Nugroho', 'Gita Permata', 'Hendra Wijaya', 'Indah Sari', 'Joko Susilo',
        'Karina Putri', 'Luthfi Hakim', 'Maya Anggraini', 'Nanda Kurniawan', 'Olivia Rini',
        'Prasetyo Adi', 'Qonita Zahra', 'Rizky Maulana',
      ][i],
      nisn: '${100000 + i}',
      status: 'HADIR',
    ),
  );

  // Input Nilai tab state
  late List<_GradeRow> _grades;
  String _editingId = '';
  final _controllers = <String, TextEditingController>{};
  bool _gradesSaved = false;

  // Nilai Weights (dynamic) — total harus 100
  double _bobotTugas     = 20;
  double _bobotUH        = 20;
  double _bobotUTS = 20;
  double _bobotUAS = 20;
  double _bobotKeaktifan = 10;
  double _bobotKehadiran = 20;

  // QR Timer
  late List<_PastMeeting> _histories;
  late List<_RecapStudent> _recapStudents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // kehadiran dihitung setelah _recapStudents diisi
    _grades = List.generate(
      _students.length,
      (i) => _GradeRow(
        name: _students[i].name,
        nisn: _students[i].nisn,
        tugas:     (60 + Random().nextInt(40)).toDouble(),
        uh:        (60 + Random().nextInt(40)).toDouble(),
        uts:       (60 + Random().nextInt(40)).toDouble(),
        uas:       (60 + Random().nextInt(40)).toDouble(),
        keaktifan: (70 + Random().nextInt(30)).toDouble(),
        kehadiran: 0, // ditentukan di bawah setelah _recapStudents
      ),
    );

    _histories = [
      _PastMeeting(
        id: 'M1',
        date: '08 Apr 2026',
        pertemuanKe: '1',
        materi: 'Pengenalan Materi & Silabus',
        students: _students.map((s) => _Student(id: s.id, name: s.name, nisn: s.nisn, status: 'HADIR')).toList(),
      ),
      _PastMeeting(
        id: 'M2',
        date: '10 Apr 2026',
        pertemuanKe: '2',
        materi: 'Ruang Lingkup Lanjutan',
        students: _students.map((s) => _Student(id: s.id, name: s.name, nisn: s.nisn, status: s.name.startsWith('A') ? 'IZIN' : 'HADIR')).toList(),
      ),
    ];

    _recapStudents = [
      _RecapStudent(name: 'Ahmad Fauzi',      nisn: '100000', attendance: ['H','H','H','H','H','H','H','S','H','H','H','H']),
      _RecapStudent(name: 'Budi Santoso',      nisn: '100001', attendance: ['H','I','H','H','I','H','H','H','H','I','H','H']),
      _RecapStudent(name: 'Citra Dewi',        nisn: '100002', attendance: ['H','H','S','H','H','H','S','H','H','H','S','H']),
      _RecapStudent(name: 'Dian Pratama',      nisn: '100003', attendance: ['H','H','H','H','H','H','H','H','H','H','H','H']),
      _RecapStudent(name: 'Eka Rahayu',        nisn: '100004', attendance: ['I','H','H','I','A','H','H','A','H','H','A','A']),
      _RecapStudent(name: 'Fajar Nugroho',     nisn: '100005', attendance: ['H','H','H','H','H','H','H','H','H','H','H','H']),
      _RecapStudent(name: 'Gita Permata',      nisn: '100006', attendance: ['H','H','H','S','H','H','H','H','H','H','H','H']),
      _RecapStudent(name: 'Hendra Wijaya',     nisn: '100007', attendance: ['H','H','A','H','H','H','H','H','H','H','H','H']),
      _RecapStudent(name: 'Indah Sari',        nisn: '100008', attendance: ['S','H','H','H','H','H','H','H','H','H','H','H']),
      _RecapStudent(name: 'Joko Susilo',       nisn: '100009', attendance: ['H','H','H','H','H','I','H','H','H','H','H','H']),
      _RecapStudent(name: 'Karina Putri',      nisn: '100010', attendance: ['H','H','H','H','H','H','H','H','H','H','I','H']),
      _RecapStudent(name: 'Luthfi Hakim',      nisn: '100011', attendance: ['H','H','H','H','H','H','H','H','H','H','H','H']),
      _RecapStudent(name: 'Maya Anggraini',    nisn: '100012', attendance: ['H','H','H','H','H','H','H','H','A','H','H','H']),
      _RecapStudent(name: 'Nanda Kurniawan',   nisn: '100013', attendance: ['H','H','H','H','H','H','H','H','H','I','H','H']),
      _RecapStudent(name: 'Olivia Rini',       nisn: '100014', attendance: ['H','H','H','H','H','H','H','H','H','H','H','H']),
      _RecapStudent(name: 'Prasetyo Adi',      nisn: '100015', attendance: ['H','H','S','H','H','S','H','H','H','H','H','H']),
      _RecapStudent(name: 'Qonita Zahra',      nisn: '100016', attendance: ['H','H','H','H','H','H','A','H','H','H','H','H']),
      _RecapStudent(name: 'Rizky Maulana',     nisn: '100017', attendance: ['H','H','H','H','H','H','H','H','H','H','H','H']),
    ];

    // ── Auto-hitung kehadiran dari _recapStudents ────────────────────
    // Skor kehadiran = (totalHadir / totalPertemuan) * 100
    const totalPertemuan = 12;
    for (int i = 0; i < _grades.length && i < _recapStudents.length; i++) {
      final pct = (_recapStudents[i].totalHadir / totalPertemuan) * 100;
      // _GradeRow.kehadiran adalah final; kita buat ulang baris itu
      _grades[i] = _GradeRow(
        name:      _grades[i].name,
        nisn:      _grades[i].nisn,
        tugas:     _grades[i].tugas,
        uh:        _grades[i].uh,
        uts:       _grades[i].uts,
        uas:       _grades[i].uas,
        keaktifan: _grades[i].keaktifan,
        kehadiran: pct.clamp(0, 100),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── QR Generation ─────────────────────────────────────────────────────
  void _generateQR() {
    final code = 'SIAKAD-${widget.classId.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _generatedQR = code;
      _qrCountdown = 60;
      _showQRModal = true;
    });
    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_qrCountdown <= 1) {
        t.cancel();
        _generateQR(); // auto refresh
      } else {
        if (mounted) setState(() => _qrCountdown--);
      }
    });
  }

  void _closeQRModal() {
    _qrTimer?.cancel();
    setState(() => _showQRModal = false);
  }

  // ── Open Session ───────────────────────────────────────────────────────
  void _openSessionDialog() {
    final pertemuanCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Buka Sesi Pertemuan Baru', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pertemuan Ke-', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: pertemuanCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDeco('Contoh: 1'),
              ),
              const SizedBox(height: 16),
              const Text('Topik Pertemuan', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: topicCtrl,
                decoration: _inputDeco('Contoh: Persamaan Kuadrat'),
              ),
              const SizedBox(height: 16),
              const Text('Deskripsi / Materi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: _inputDeco('Jelaskan materi yang akan dibahas...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (topicCtrl.text.trim().isEmpty || pertemuanCtrl.text.trim().isEmpty) return;
              setState(() {
                _sessionOpen = true;
                _sessionPertemuan = pertemuanCtrl.text.trim();
                _sessionTopic = topicCtrl.text.trim();
                _sessionDesc = descCtrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Buka Sesi'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  // ── Grade edit ────────────────────────────────────────────────────────
  TextEditingController _ctrl(String key, double value) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: value.toStringAsFixed(0));
    }
    return _controllers[key]!;
  }

  void _saveGrades() {
    for (int i = 0; i < _grades.length; i++) {
      final g = _grades[i];
      final tugasKey     = '${g.nisn}-tugas';
      final uhKey        = '${g.nisn}-uh';
      final utsKey       = '${g.nisn}-uts';
      final uasKey       = '${g.nisn}-uas';
      final keaktifanKey = '${g.nisn}-keaktifan';
      if (_controllers.containsKey(tugasKey))     g.tugas     = double.tryParse(_controllers[tugasKey]!.text)     ?? g.tugas;
      if (_controllers.containsKey(uhKey))        g.uh        = double.tryParse(_controllers[uhKey]!.text)        ?? g.uh;
      if (_controllers.containsKey(utsKey))       g.uts       = double.tryParse(_controllers[utsKey]!.text)       ?? g.uts;
      if (_controllers.containsKey(uasKey))       g.uas       = double.tryParse(_controllers[uasKey]!.text)       ?? g.uas;
      if (_controllers.containsKey(keaktifanKey)) g.keaktifan = double.tryParse(_controllers[keaktifanKey]!.text) ?? g.keaktifan;
    }
    setState(() {
      _editingId = '';
      _gradesSaved = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _gradesSaved = false);
    });
  }

  // ── UI ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Parse meta from classId
    final parts = widget.classId.split('-');
    final subject = parts.isNotEmpty ? parts[0].toUpperCase() : widget.classId.toUpperCase();
    final kelas = parts.length > 1 ? 'Kelas ${parts[1].toUpperCase()}-${parts.length > 2 ? parts[2] : ''}' : '';

    return Stack(
      children: [
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            _buildHeader(subject, kelas),
            const SizedBox(height: 24),

            // ── Tabs ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.gray500,
                indicatorColor: AppColors.accent,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.assignment_outlined), text: 'Jurnal & Absensi'),
                  Tab(icon: Icon(Icons.table_rows_outlined), text: 'Rekapitulasi'),
                  Tab(icon: Icon(Icons.grade_outlined), text: 'Input Nilai'),
                ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
                    child: Text(kelas, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Detail Kelas',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola jurnal, absensi, dan nilai siswa secara lengkap.',
                style: TextStyle(fontSize: 14, color: AppColors.gray600),
              ),
            ],
          ),
        ),
        // Stats summary
        _statBadge(Icons.people, '${_students.length}', 'Siswa', AppColors.primary),
        const SizedBox(width: 12),
        _statBadge(Icons.check_circle_outline, '${_students.where((s) => s.status == 'HADIR').length}', 'Hadir', const Color(0xFF059669)),
        const SizedBox(width: 12),
        _statBadge(
          _sessionOpen ? Icons.radio_button_checked : Icons.radio_button_off,
          _sessionOpen ? 'Aktif' : 'Tutup',
          'Sesi',
          _sessionOpen ? const Color(0xFF059669) : AppColors.gray500,
        ),
      ],
    );
  }

  Widget _statBadge(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
        ],
      ),
    );
  }

  // ══════════════════ JURNAL TAB ══════════════════════════════════════════
  Widget _buildJurnalTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Session Card ─
          _buildSessionCard(),
          const SizedBox(height: 20),

          // ─ Absensi ─
          if (_sessionOpen) _buildAbsensiPanel(),

          // ─ Riwayat Pertemuan ─
          if (!_sessionOpen) _buildHistoryPanel(),
        ],
      ),
    );
  }

  Widget _buildSessionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.book_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Jurnal Pertemuan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const Spacer(),
              if (_sessionOpen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Sesi Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (!_sessionOpen) ...[
            // ─ Open Session CTA ─
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE3F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_open_outlined, size: 48, color: AppColors.gray400),
                  const SizedBox(height: 12),
                  const Text('Belum Ada Sesi Terbuka', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray600)),
                  const SizedBox(height: 6),
                  const Text(
                    'Buka sesi pertemuan baru untuk memulai absensi dan mencatat jurnal mengajar hari ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.gray500),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Buka Pertemuan Baru', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: _openSessionDialog,
                  ),
                ],
              ),
            ),
          ] else ...[
            // ─ Active Session Info ─
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_sessionPertemuan.isNotEmpty) ...[
                        _infoRow(Icons.numbers_outlined, 'Pertemuan Ke', _sessionPertemuan),
                        const SizedBox(height: 10),
                      ],
                      _infoRow(Icons.topic_outlined, 'Topik', _sessionTopic),
                      if (_sessionDesc.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _infoRow(Icons.description_outlined, 'Materi', _sessionDesc),
                      ],
                      const SizedBox(height: 10),
                      _infoRow(Icons.calendar_today_outlined, 'Tanggal', _formattedDate()),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Tampilkan QR Absensi', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: _generateQR,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.gray500),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray600)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.foreground))),
      ],
    );
  }

  Widget _buildAbsensiPanel() {
    final counts = {
      'HADIR': _students.where((s) => s.status == 'HADIR').length,
      'SAKIT': _students.where((s) => s.status == 'SAKIT').length,
      'IZIN': _students.where((s) => s.status == 'IZIN').length,
      'ALPA': _students.where((s) => s.status == 'ALPA').length,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.checklist, color: AppColors.primary),
                const SizedBox(width: 10),
                const Text('Daftar Hadir Siswa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const Spacer(),
                // Summary chips
                ..._statusChip('H', counts['HADIR']!, const Color(0xFF059669), const Color(0xFFD1FAE5)),
                const SizedBox(width: 6),
                ..._statusChip('S', counts['SAKIT']!, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                const SizedBox(width: 6),
                ..._statusChip('I', counts['IZIN']!, const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
                const SizedBox(width: 6),
                ..._statusChip('A', counts['ALPA']!, const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Table header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('#', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray500, fontSize: 12))),
                Expanded(flex: 3, child: Text('NAMA', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray500, fontSize: 12))),
                SizedBox(width: 100, child: Text('NISN', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray500, fontSize: 12))),
                SizedBox(width: 260, child: Text('STATUS KEHADIRAN', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray500, fontSize: 12))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Student rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
            itemBuilder: (ctx, i) => _buildAbsensiRow(_students[i], i),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan Absensi', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () => _showSaveSnackbar('Absensi berhasil disimpan!'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _statusChip(String label, int count, Color fg, Color bg) => [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text('$label: $count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    ),
  ];

  Widget _buildAbsensiRow(_Student s, int idx) {
    const statuses = ['HADIR', 'SAKIT', 'IZIN', 'ALPA'];
    const colors = {
      'HADIR': Color(0xFF059669),
      'SAKIT': Color(0xFFD97706),
      'IZIN': Color(0xFF2563EB),
      'ALPA': Color(0xFFDC2626),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('${idx + 1}', style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(s.name[0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(s.nisn, style: const TextStyle(fontSize: 13, color: AppColors.gray500, fontFamily: 'monospace')),
          ),
          SizedBox(
            width: 260,
            child: Row(
              children: statuses.map((status) {
                final isSelected = s.status == status;
                final color = colors[status]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => s.status = status),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? color : const Color(0xFFF9FAFB),
                        border: Border.all(color: isSelected ? color : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.gray500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════ RIWAYAT PERTEMUAN ═══════════════════════════════════
  Widget _buildHistoryPanel() {
    if (_histories.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Table Header ─
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Daftar Riwayat Pertemuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ),
          // ─ Column Labels ─
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Row(
              children: [
                SizedBox(width: 120, child: Text('TANGGAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray500))),
                SizedBox(width: 80,  child: Text('PERTEMUAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray500))),
                Expanded(child: Text('MATERI / KD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray500))),
                SizedBox(width: 260, child: Text('RINGKASAN KEHADIRAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray500))),
                SizedBox(width: 120, child: Text('AKSI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray500))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          // ─ Rows ─
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _histories.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
            itemBuilder: (ctx, i) {
              final h = _histories[i];
              final hadir  = h.students.where((s) => s.status == 'HADIR').length;
              final izin   = h.students.where((s) => s.status == 'IZIN').length;
              final sakit  = h.students.where((s) => s.status == 'SAKIT').length;
              final alpa   = h.students.where((s) => s.status == 'ALPA').length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Tanggal
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.gray500),
                          const SizedBox(width: 6),
                          Flexible(child: Text(h.date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.foreground))),
                        ],
                      ),
                    ),
                    // Pertemuan Ke
                    SizedBox(
                      width: 80,
                      child: Text('Ke-${h.pertemuanKe}', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                    ),
                    // Materi
                    Expanded(
                      child: Text(h.materi, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                    ),
                    // Summary chips
                    SizedBox(
                      width: 260,
                      child: Row(
                        children: [
                          _summaryChip('Hadir', hadir, const Color(0xFF15803D), const Color(0xFFDCFCE7)),
                          const SizedBox(width: 6),
                          _summaryChip('Izin', izin, const Color(0xFFB45309), const Color(0xFFFEF3C7)),
                          const SizedBox(width: 6),
                          _summaryChip('Sakit', sakit, const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
                          const SizedBox(width: 6),
                          _summaryChip('Alpa', alpa, const Color(0xFFB91C1C), const Color(0xFFFEE2E2)),
                        ],
                      ),
                    ),
                    // Action
                    SizedBox(
                      width: 120,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                        label: const Text('Lihat & Edit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        onPressed: () => setState(() {
                          _selectedHistory = h;
                          _showHistoryModal = true;
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text('$label: $count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _buildHistoryModal() {
    if (_selectedHistory == null) return const SizedBox();
    final h = _selectedHistory!;
    final hadirCount = h.students.where((s) => s.status == 'HADIR').length;
    final izinCount  = h.students.where((s) => s.status == 'IZIN').length;
    final sakitCount = h.students.where((s) => s.status == 'SAKIT').length;
    final alpaCount  = h.students.where((s) => s.status == 'ALPA').length;

    return GestureDetector(
      onTap: () => setState(() => _showHistoryModal = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 780,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─ Modal Header ─
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Absensi – ${h.date}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            const SizedBox(height: 4),
                            Text('Pertemuan ${h.pertemuanKe}  •  ${h.materi}',
                                style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
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
                            _modalStatBox('Hadir',  hadirCount, const Color(0xFF15803D), const Color(0xFFF0FDF4), const Color(0xFFBBF7D0)),
                            const SizedBox(width: 12),
                            _modalStatBox('Izin',   izinCount,  const Color(0xFFB45309), const Color(0xFFFFFBEB), const Color(0xFFFDE68A)),
                            const SizedBox(width: 12),
                            _modalStatBox('Sakit',  sakitCount, const Color(0xFF1D4ED8), const Color(0xFFEFF6FF), const Color(0xFFBFDBFE)),
                            const SizedBox(width: 12),
                            _modalStatBox('Alpa',   alpaCount,  const Color(0xFFB91C1C), const Color(0xFFFFF5F5), const Color(0xFFFECACA)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 40,  child: Text('#',          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                              Expanded(flex: 3,    child: Text('NAMA SISWA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                              SizedBox(width: 120, child: Text('NISN',       style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                              SizedBox(width: 100, child: Text('SCAN',       style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                              SizedBox(width: 80,  child: Text('STATUS',     style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                              SizedBox(width: 100, child: Text('UBAH',       style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                            ],
                          ),
                        ),

                        // Table rows
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                          ),
                          child: Column(
                            children: h.students.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final s   = entry.value;
                              final isOdd = idx % 2 == 1;
                              return Container(
                                color: isOdd ? const Color(0xFFF9FAFB) : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    SizedBox(width: 40, child: Text('${idx + 1}', style: const TextStyle(fontSize: 13, color: AppColors.gray500))),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                            child: Text(s.name[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(child: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 120, child: Text(s.nisn, style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontFamily: 'monospace'))),
                                    SizedBox(
                                      width: 100,
                                      child: s.status == 'HADIR'
                                          ? Row(
                                              children: [
                                                const Icon(Icons.access_time, size: 13, color: AppColors.gray500),
                                                const SizedBox(width: 4),
                                                Text('07:${10 + idx}:${20 + idx}', style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                                              ],
                                            )
                                          : const Text('–', style: TextStyle(color: AppColors.gray400)),
                                    ),
                                    SizedBox(width: 80, child: _statusBadge(s.status)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          _showSaveSnackbar('Perubahan data absensi berhasil disimpan!');
                          setState(() {
                            _showHistoryModal = false;
                            _selectedHistory = null;
                          });
                        },
                        child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _modalStatBox(String label, int count, Color textColor, Color bgColor, Color borderColor) {
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
            Text(label, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final Map<String, List<Color>> colors = {
      'HADIR': [const Color(0xFFDCFCE7), const Color(0xFF15803D)],
      'IZIN':  [const Color(0xFFFEF3C7), const Color(0xFFB45309)],
      'SAKIT': [const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)],
      'ALPA':  [const Color(0xFFFEE2E2), const Color(0xFFB91C1C)],
    };
    final c = colors[status] ?? [const Color(0xFFF3F4F6), AppColors.gray600];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c[0], borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c[1])),
    );
  }

  Widget _buildHistoryStatusDropdown(_PastMeeting h, _Student s) {
    const statuses = ['HADIR', 'SAKIT', 'IZIN', 'ALPA'];
    return DropdownButton<String>(
      value: s.status,
      isDense: true,
      underline: const SizedBox(),
      items: statuses.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: (val) {
        if (val != null) setState(() => s.status = val);
      },
    );
  }

  // ══════════════════ REKAPITULASI TAB ════════════════════════════════════
  Widget _buildRekapTab() {
    const totalPertemuan = 12;
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(Icons.table_rows_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                const Text('Rekapitulasi Kehadiran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Cetak PDF', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  onPressed: () => _showSaveSnackbar('Rekapitulasi sedang dicetak ke PDF...'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Export Excel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  onPressed: () => _showSaveSnackbar('Rekapitulasi diekspor ke Excel!'),
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.primary),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                dataRowMinHeight: 40,
                dataRowMaxHeight: 48,
                columnSpacing: 8,
                columns: [
                  const DataColumn(label: SizedBox(width: 30,  child: Text('No'))),
                  const DataColumn(label: SizedBox(width: 110, child: Text('NISN'))),
                  const DataColumn(label: SizedBox(width: 160, child: Text('Nama Siswa'))),
                  ...List.generate(totalPertemuan, (i) => DataColumn(label: SizedBox(width: 36, child: Text('P${i + 1}')))),
                  const DataColumn(label: SizedBox(width: 60,  child: Text('Hadir', style: TextStyle(color: Color(0xFF86EFAC))))),
                  const DataColumn(label: SizedBox(width: 50,  child: Text('Izin',  style: TextStyle(color: Color(0xFFFDE68A))))),
                  const DataColumn(label: SizedBox(width: 50,  child: Text('Sakit', style: TextStyle(color: Color(0xFFBFDBFE))))),
                  const DataColumn(label: SizedBox(width: 50,  child: Text('Alpa',  style: TextStyle(color: Color(0xFFFCA5A5))))),
                ],
                rows: _recapStudents.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s   = entry.value;
                  return DataRow(
                    color: WidgetStateProperty.all(idx % 2 == 0 ? Colors.white : const Color(0xFFF9FAFB)),
                    cells: [
                      DataCell(Text('${idx + 1}', style: const TextStyle(fontSize: 12, color: AppColors.gray500))),
                      DataCell(Text(s.nisn, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.gray600))),
                      DataCell(Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                      ...s.attendance.map((code) => DataCell(_attendanceCell(code))),
                      DataCell(_rekapTotalCell('${s.totalHadir}', const Color(0xFF15803D), const Color(0xFFF0FDF4))),
                      DataCell(_rekapTotalCell('${s.totalIzin}',  const Color(0xFFB45309), const Color(0xFFFFFBEB))),
                      DataCell(_rekapTotalCell('${s.totalSakit}', const Color(0xFF1D4ED8), const Color(0xFFEFF6FF))),
                      DataCell(_rekapTotalCell('${s.totalAlpa}',  const Color(0xFFB91C1C),
                          s.totalAlpa > 3 ? const Color(0xFFFEE2E2) : const Color(0xFFFFF5F5))),
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
              _legendItem('H', 'Hadir',  const Color(0xFF059669), const Color(0xFFDCFCE7)),
              _legendItem('I', 'Izin',   const Color(0xFFB45309), const Color(0xFFFEF3C7)),
              _legendItem('S', 'Sakit',  const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
              _legendItem('A', 'Alpa',   const Color(0xFFB91C1C), const Color(0xFFFEE2E2)),
              _legendItem('-', 'Kosong', AppColors.gray500,       const Color(0xFFF3F4F6)),
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c[1]),
      ),
    );
  }

  Widget _rekapTotalCell(String value, Color fg, Color bg) {
    return Container(
      width: 36,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _legendItem(String code, String label, Color fg, Color bg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28, height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
          child: Text(code == 'H' ? '✓' : code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
      ],
    );
  }

  // ══════════════════ NILAI TAB ══════════════════════════════════════════
  Widget _buildNilaiTab() {
    double calculateNa(g) => g.getNaValue(_bobotTugas, _bobotUH, _bobotUTS, _bobotUAS, _bobotKeaktifan, _bobotKehadiran);
    final avg = _grades.isEmpty ? 0.0 : _grades.map(calculateNa).reduce((a, b) => a + b) / _grades.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Bobot info ─
          _buildBobotCard(),
          const SizedBox(height: 20),

          // ─ Stats row ─
          Row(children: [
            _nilaiStatCard('Rata-rata Kelas',  avg.toStringAsFixed(1),                                              Icons.bar_chart,          AppColors.primary),
            const SizedBox(width: 12),
            _nilaiStatCard('Nilai Tertinggi', _grades.map((g) => g.getNaValue(_bobotTugas, _bobotUH, _bobotUTS, _bobotUAS, _bobotKeaktifan, _bobotKehadiran)).reduce(max).toStringAsFixed(1), Icons.trending_up,   const Color(0xFF059669)),
            const SizedBox(width: 12),
            _nilaiStatCard('Nilai Terendah',  _grades.map((g) => g.getNaValue(_bobotTugas, _bobotUH, _bobotUTS, _bobotUAS, _bobotKeaktifan, _bobotKehadiran)).reduce(min).toStringAsFixed(1), Icons.trending_down, const Color(0xFFDC2626)),
            const SizedBox(width: 12),
            _nilaiStatCard('Lulus (≥70)',      '${_grades.where((g) => g.getNaValue(_bobotTugas, _bobotUH, _bobotUTS, _bobotUAS, _bobotKeaktifan, _bobotKehadiran) >= 70).length}/${_grades.length}', Icons.check_circle_outline, const Color(0xFF7C3AED)),
          ]),
          const SizedBox(height: 20),

          // ─ Save success toast ─
          if (_gradesSaved)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Text('Nilai berhasil disimpan!', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                ],
              ),
            ),

          // ─ Table ─
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.table_chart_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Tabel Nilai Siswa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Simpan Semua Nilai', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        onPressed: _saveGrades,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Column headers
                Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray500, fontSize: 12))),
                      const Expanded(flex: 3, child: Text('NAMA SISWA', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray500, fontSize: 12))),
                      _NilaiHeader('TUGAS (${_bobotTugas.toInt()}%)', width: 110),
                      _NilaiHeader('UH (${_bobotUH.toInt()}%)', width: 100),
                      _NilaiHeader('UTS (${_bobotUTS.toInt()}%)', width: 100),
                      _NilaiHeader('UAS (${_bobotUAS.toInt()}%)', width: 100),
                      _NilaiHeader('KEAKTIFAN (${_bobotKeaktifan.toInt()}%)', width: 120),
                      NilaiHeaderAuto('KEHADIRAN (${_bobotKehadiran.toInt()}%)', width: 140),
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
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (ctx, i) => _buildGradeRow(_grades[i], i),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBobotCard() {
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
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Text('Persentase Bobot Penilaian', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              _getTotalBobot() == 100
                  ? const Text('Total: 100% ✓', style: TextStyle(color: Color(0xFF059669), fontSize: 13, fontWeight: FontWeight.w600))
                  : Text('Total: ${_getTotalBobot().toInt()}% (Harus 100%)', style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Semua bobot dijumlahkan harus tepat 100%. Bobot Kehadiran dihitung otomatis dari data absensi.',
            style: const TextStyle(fontSize: 11, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),

          // Row 1: Tugas, UH, UTS, UAS
          Row(
            children: [
              _bobotInput('Tugas', _bobotTugas, (v) => setState(() => _bobotTugas = v)),
              const SizedBox(width: 12),
              _bobotInput('UH', _bobotUH, (v) => setState(() => _bobotUH = v)),
              const SizedBox(width: 12),
              _bobotInput('UTS', _bobotUTS, (v) => setState(() => _bobotUTS = v)),
              const SizedBox(width: 12),
              _bobotInput('UAS', _bobotUAS, (v) => setState(() => _bobotUAS = v)),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Keaktifan & Kehadiran (Both editable now)
          Row(
            children: [
              _bobotInput('Keaktifan', _bobotKeaktifan, (v) => setState(() => _bobotKeaktifan = v)),
              const SizedBox(width: 12),
              _bobotInput('Kehadiran', _bobotKehadiran, (v) => setState(() => _bobotKehadiran = v)),
              const Spacer(),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.gray400, size: 14),
              SizedBox(width: 6),
              Text('Klik baris pada tabel untuk mulai mengedit. Nilai kehadiran dihitung otomatis dari data absensi.', style: TextStyle(color: AppColors.gray500, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  double _getTotalBobot() => _bobotTugas + _bobotUH + _bobotUTS + _bobotUAS + _bobotKeaktifan + _bobotKehadiran;

  Widget _bobotInput(String label, double value, Function(double) onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label (%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null) onChanged(parsed);
              if (val.isEmpty) onChanged(0);
            },
          ),
        ],
      ),
    );
  }

  Widget _nilaiStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeRow(_GradeRow g, int idx) {
    final isEditing = _editingId == g.nisn;
    final na = g.getNaValue(_bobotTugas, _bobotUH, _bobotUTS, _bobotUAS, _bobotKeaktifan, _bobotKehadiran);
    final passed = na >= 70;

    final Color gradeColor;
    switch (g.getGrade(na)) {
      case 'A': gradeColor = const Color(0xFF059669); break;
      case 'B': gradeColor = const Color(0xFF2563EB); break;
      case 'C': gradeColor = const Color(0xFFD97706); break;
      default: gradeColor = const Color(0xFFDC2626);
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
            SizedBox(width: 32, child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, color: AppColors.gray500))),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(g.name[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(g.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
            if (isEditing) ...[
              _editableNilaiCell(_ctrl('${g.nisn}-tugas', g.tugas), 110),
              _editableNilaiCell(_ctrl('${g.nisn}-uh', g.uh), 100),
              _editableNilaiCell(_ctrl('${g.nisn}-uts', g.uts), 100),
              _editableNilaiCell(_ctrl('${g.nisn}-uas', g.uas), 100),
              _editableNilaiCell(_ctrl('${g.nisn}-keaktifan', g.keaktifan), 120),
            ] else ...[
              _nilaiCell(g.tugas.toStringAsFixed(0), 110, passed),
              _nilaiCell(g.uh.toStringAsFixed(0), 100, passed),
              _nilaiCell(g.uts.toStringAsFixed(0), 100, passed),
              _nilaiCell(g.uas.toStringAsFixed(0), 100, passed),
              _nilaiCell(g.keaktifan.toStringAsFixed(0), 120, g.keaktifan >= 70),
            ],
            // Kehadiran — read-only, auto dari absensi
            SizedBox(
              width: 140,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kehadiranColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kehadiranColor.withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outlined, size: 11, color: kehadiranColor),
                        const SizedBox(width: 4),
                        Text(
                          '${g.kehadiran.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kehadiranColor),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: passed ? const Color(0xFF059669) : const Color(0xFFDC2626)),
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
                child: Text(g.getGrade(na), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: gradeColor)),
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
      child: Text(value, style: TextStyle(fontSize: 13, color: ok ? AppColors.foreground : const Color(0xFFDC2626))),
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
          ),
        ),
      ),
    );
  }

  // ══════════════════ QR MODAL ═══════════════════════════════════════════
  Widget _buildQRModal() {
    return GestureDetector(
      onTap: _closeQRModal,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent close on inner tap
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('QR Absensi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _closeQRModal,
                        child: const Icon(Icons.close, color: AppColors.gray500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Countdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _qrCountdown <= 10 ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: _qrCountdown <= 10 ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Text(
                          'Refresh dalam $_qrCountdown detik',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _qrCountdown <= 10 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // QR Code mock
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                    ),
                    child: Stack(
                      children: [
                        // QR grid pattern (mock)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CustomPaint(
                            size: const Size(240, 240),
                            painter: _QRPainter(_generatedQR),
                          ),
                        ),
                        // Center logo
                        Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Center(
                              child: Icon(Icons.school, color: AppColors.primary, size: 28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Code text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      _generatedQR,
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.gray600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'QR Code otomatis diperbarui setiap 60 detik untuk keamanan.\nSiswa scan menggunakan aplikasi SIAKAD Mobile.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generateQR,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh QR'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _closeQRModal,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Tutup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  String _formattedDate() {
    final now = DateTime.now();
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray500, fontSize: 12)),
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

// ── QR Painter (mock QR code grid) ─────────────────────────────────────────
class _QRPainter extends CustomPainter {
  final String data;
  _QRPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E3A8A);
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final rng = Random(data.hashCode);
    final cellSize = size.width / 25;
    const quietZone = 2; // cells

    // Draw cells (mimic QR density)
    for (int row = 0; row < 25; row++) {
      for (int col = 0; col < 25; col++) {
        // Skip finder pattern areas (corners)
        final inTopLeft = row < 9 && col < 9;
        final inTopRight = row < 9 && col > 15;
        final inBottomLeft = row > 15 && col < 9;

        if (inTopLeft || inTopRight || inBottomLeft) continue;
        if (row < quietZone || col < quietZone || row >= 25 - quietZone || col >= 25 - quietZone) continue;

        if (rng.nextBool()) {
          final rect = Rect.fromLTWH(col * cellSize + 1, row * cellSize + 1, cellSize - 1, cellSize - 1);
          canvas.drawRect(rect, paint);
        }
      }
    }

    // Draw finder patterns (corners)
    _drawFinder(canvas, paint, bgPaint, cellSize, 0, 0);
    _drawFinder(canvas, paint, bgPaint, cellSize, 18, 0);
    _drawFinder(canvas, paint, bgPaint, cellSize, 0, 18);
  }

  void _drawFinder(Canvas canvas, Paint dark, Paint light, double cs, double startCol, double startRow) {
    // Outer 7x7 black
    canvas.drawRect(Rect.fromLTWH(startCol * cs, startRow * cs, 7 * cs, 7 * cs), dark);
    // Inner 5x5 white
    canvas.drawRect(Rect.fromLTWH((startCol + 1) * cs, (startRow + 1) * cs, 5 * cs, 5 * cs), light);
    // Inner 3x3 black
    canvas.drawRect(Rect.fromLTWH((startCol + 2) * cs, (startRow + 2) * cs, 3 * cs, 3 * cs), dark);
  }

  @override
  bool shouldRepaint(_QRPainter old) => old.data != data;
}
