// File: lib/features/guru/screens/teacher_dashboard.dart
// ===========================================
// TEACHER DASHBOARD — Dynamic Schedule + QR Shortcut
// Real-time time-checking logic for "Buka Pertemuan"
// ===========================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  bool _loading = true;
  Map<String, dynamic> _dashboardData = {};

  // ── Time-checking state ──
  DateTime _currentTime = DateTime.now();
  Timer? _timeCheckTimer;

  // ── QR Modal state ──
  bool _showQrModal = false;
  bool _isOpeningSession = false;
  String _qrData = '';
  int _qrCountdown = 180;
  Timer? _qrCountdownTimer;
  // Active session info
  String _activeJadwalId = '';
  String _activeTanggal = '';
  int _activePertemuanKe = 1;
  String _activeSubject = '';
  String _activeClassName = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    // Timer setiap 30 detik untuk cek waktu real-time
    _timeCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timeCheckTimer?.cancel();
    _qrCountdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      final response = await ApiService.getGuruDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = response['data'] ?? {};
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Time-checking logic ──
  String _scheduleStatus(Map<String, dynamic> j) {
    final startParts = (j['startTime'] as String? ?? '00:00').split(':');
    final endParts = (j['endTime'] as String? ?? '00:00').split(':');
    final now = _currentTime;
    final start = DateTime(now.year, now.month, now.day,
        int.parse(startParts[0]), int.parse(startParts[1]));
    final end = DateTime(now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]));
    if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
        (now.isBefore(end) || now.isAtSameMomentAs(end))) {
      return 'active';
    }
    if (now.isAfter(end)) return 'past';
    return 'future';
  }

  // ── Quick Session Handler ──
  Future<void> _onBukaPertemuan(Map<String, dynamic> jadwal) async {
    if (_isOpeningSession) return;
    setState(() => _isOpeningSession = true);
    try {
      final res = await ApiService.quickSession({
        'jadwalId': jadwal['id'],
        'mataPelajaranId': jadwal['mataPelajaranId'] ?? '',
      });
      final data = res['data'];
      if (mounted) {
        setState(() {
          _qrData = data['qrData'] ?? '';
          _activeJadwalId = data['jadwalId'] ?? '';
          _activeTanggal = data['tanggal'] ?? '';
          _activePertemuanKe = data['pertemuanKe'] ?? 1;
          _activeSubject = data['subject'] ?? jadwal['subject'] ?? '';
          _activeClassName = data['className'] ?? jadwal['className'] ?? '';
          _qrCountdown = 180;
          _showQrModal = true;
          _isOpeningSession = false;
        });
        _startQrCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOpeningSession = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Gagal membuka sesi. Periksa koneksi.'),
          ]),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  void _startQrCountdown() {
    _qrCountdownTimer?.cancel();
    _qrCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_qrCountdown <= 1) {
        t.cancel();
        _refreshQr();
      } else {
        if (mounted) setState(() => _qrCountdown--);
      }
    });
  }

  Future<void> _refreshQr() async {
    try {
      final res = await ApiService.refreshQR({
        'jadwalId': _activeJadwalId,
        'tanggal': _activeTanggal,
        'pertemuanKe': _activePertemuanKe,
      });
      if (mounted) {
        setState(() {
          _qrData = res['data']?['qrData'] ?? _qrData;
          _qrCountdown = 180;
        });
        _startQrCountdown();
      }
    } catch (_) {}
  }

  Future<void> _endSession() async {
    _qrCountdownTimer?.cancel();
    try {
      await ApiService.endSession({
        'jadwalId': _activeJadwalId,
        'tanggal': _activeTanggal,
      });
    } catch (_) {}
    if (mounted) {
      setState(() {
        _showQrModal = false;
        _qrData = '';
        _qrCountdown = 180;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white),
          SizedBox(width: 8),
          Text('Sesi absensi telah ditutup.'),
        ]),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _monthName(int month) {
    const m = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    return m[month - 1];
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final rawSchedule = _dashboardData['jadwalHariIni'] as List? ?? [];
    final totalKelas = _dashboardData['totalKelas'] ?? 0;
    final totalJadwal = _dashboardData['totalJadwal'] ?? 0;

    return Stack(children: [
      SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Greeting ──
          Text('${_getGreeting()}, Guru!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.foreground)),
          const SizedBox(height: 8),
          Text('Hari ini: ${_dashboardData['hari'] ?? '-'} • Total jadwal: $totalJadwal sesi/minggu',
              style: const TextStyle(color: AppColors.gray600)),
          const SizedBox(height: 24),

          // ── KPI Cards ──
          Row(children: [
            _kpiCard('Kelas Hari Ini', '${rawSchedule.length}', 'Pertemuan',
                const Color(0xFF3B82F6), const Color(0xFF2563EB), Icons.calendar_today),
            _kpiCard('Total Kelas Diampu', '$totalKelas', 'Kelas',
                const Color(0xFF10B981), const Color(0xFF059669), Icons.people),
          ]),
          const SizedBox(height: 24),

          // ── Main Content ──
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // LEFT 70%
            Expanded(flex: 7, child: _buildScheduleSection(rawSchedule)),
            const SizedBox(width: 20),
            // RIGHT 30%
            Expanded(flex: 3, child: _buildJournalSection()),
          ]),
        ]),
      ),
      // QR Modal overlay
      if (_showQrModal) _buildQrModal(),
    ]);
  }

  Widget _kpiCard(String title, String value, String sub, Color c1, Color c2, IconData icon) {
    return Expanded(child: Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.foreground)),
            const SizedBox(width: 6),
            Text(sub, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
          ]),
        ])),
        Container(width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22)),
      ]),
    ));
  }

  Widget _buildScheduleSection(List rawSchedule) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Jadwal Mengajar Hari Ini',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground)),
            const SizedBox(height: 4),
            Text('${_dashboardData['hari'] ?? '-'}, ${_currentTime.day} ${_monthName(_currentTime.month)} ${_currentTime.year}',
                style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
          ]),
          Row(children: [
            const Icon(Icons.access_time, size: 16, color: AppColors.gray600),
            const SizedBox(width: 4),
            Text(_formatTime(_currentTime), style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
          ]),
        ]),
        const SizedBox(height: 20),
        if (rawSchedule.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('Tidak ada jadwal hari ini', style: TextStyle(color: AppColors.gray500))))
        else
          ...rawSchedule.map((j) => _buildScheduleCard(j as Map<String, dynamic>)),
      ]),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> j) {
    final status = _scheduleStatus(j);
    final isActive = status == 'active';
    final isPast = status == 'past';
    final time = '${j['startTime'] ?? ''} - ${j['endTime'] ?? ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent.withValues(alpha: 0.05) : isPast ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? AppColors.accent : const Color(0xFFE5E7EB), width: 2),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.gray700)),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(99)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Berlangsung', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                ]),
              ),
            ],
            if (isPast) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(99)),
                child: const Text('Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray500)),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Text(j['subject'] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: isPast ? AppColors.gray400 : AppColors.foreground)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.people_outline, size: 16, color: isPast ? AppColors.gray300 : AppColors.gray500),
            const SizedBox(width: 4),
            Text(j['className'] ?? '', style: TextStyle(fontSize: 13, color: isPast ? AppColors.gray400 : AppColors.gray600)),
            const SizedBox(width: 16),
            Icon(Icons.location_on_outlined, size: 16, color: isPast ? AppColors.gray300 : AppColors.gray500),
            const SizedBox(width: 4),
            Text(j['room'] ?? '-', style: TextStyle(fontSize: 13, color: isPast ? AppColors.gray400 : AppColors.gray600)),
          ]),
        ])),
        // Button logic
        if (isActive)
          ElevatedButton.icon(
            onPressed: _isOpeningSession ? null : () => _onBukaPertemuan(j),
            icon: _isOpeningSession
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.qr_code_2, size: 18),
            label: Text(_isOpeningSession ? 'Memproses...' : 'Buka Pertemuan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        else if (isPast)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: const Text('Selesai', style: TextStyle(color: AppColors.gray400, fontWeight: FontWeight.w500)),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: const Text('Belum Dimulai', style: TextStyle(color: AppColors.gray400, fontWeight: FontWeight.w500)),
          ),
      ]),
    );
  }

  Widget _buildJournalSection() {
    final journals = _dashboardData['jurnalTerbaru'] as List? ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.menu_book, color: AppColors.accent, size: 18)),
          const SizedBox(width: 10),
          const Text('Jurnal Terbaru', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
        ]),
        const SizedBox(height: 16),
        ...journals.take(3).map((j) => Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8),
            border: const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(j['judulMateri'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.foreground)),
            const SizedBox(height: 2),
            Text('${j['mapel'] ?? ''} • ${j['kelas'] ?? ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
          ]),
        )),
        if (journals.isEmpty)
          const Text('Belum ada jurnal', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
      ]),
    );
  }

  // ── QR Modal (overlay langsung di Dashboard) ──
  Widget _buildQrModal() {
    final mins = (_qrCountdown ~/ 60).toString().padLeft(2, '0');
    final secs = (_qrCountdown % 60).toString().padLeft(2, '0');
    final isUrgent = _qrCountdown <= 30;
    final timerColor = isUrgent ? const Color(0xFFDC2626) : const Color(0xFF059669);

    return GestureDetector(
      onTap: () {},
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(child: Container(
          width: 440,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 12))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(color: AppColors.primary,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF6EE7B7), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('Sesi Absensi Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showQrModal = false),
                  child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.minimize_rounded, color: Colors.white, size: 20)),
                ),
              ]),
            ),
            // Body
            Padding(padding: const EdgeInsets.fromLTRB(28, 24, 28, 0), child: Column(children: [
              const Text('QR Absensi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text('$_activeSubject • $_activeClassName — Pertemuan ke-$_activePertemuanKe',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray500), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              // Progress bar
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: _qrCountdown / 180,
                  backgroundColor: const Color(0xFFE5E7EB), valueColor: AlwaysStoppedAnimation<Color>(timerColor), minHeight: 5)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.timer_outlined, size: 15, color: timerColor),
                const SizedBox(width: 5),
                Text('QR diperbarui dalam $mins:$secs',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: timerColor)),
              ]),
              const SizedBox(height: 20),
              // QR Code
              Container(width: 260, height: 260, padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
                child: Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(size: const Size(240, 240), painter: _QRPainter(_qrData))),
                  Center(child: Container(width: 52, height: 52,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 2)),
                    child: const Center(child: Icon(Icons.school, color: AppColors.primary, size: 30)))),
                ]),
              ),
              const SizedBox(height: 8),
              const Text('Siswa scan melalui aplikasi mobile', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
              const SizedBox(height: 20),
            ])),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
              child: ElevatedButton.icon(
                onPressed: _endSession,
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text('Akhiri Sesi Pertemuan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ),
          ]),
        )),
      ),
    );
  }
}

// ── QR Painter (deterministic grid from data hash) ──
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
    for (int row = 0; row < 25; row++) {
      for (int col = 0; col < 25; col++) {
        if ((row < 9 && col < 9) || (row < 9 && col > 15) || (row > 15 && col < 9)) continue;
        if (row < 2 || col < 2 || row >= 23 || col >= 23) continue;
        if (rng.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(col * cellSize + 1, row * cellSize + 1, cellSize - 1, cellSize - 1), paint);
        }
      }
    }
    _drawFinder(canvas, paint, bgPaint, cellSize, 0, 0);
    _drawFinder(canvas, paint, bgPaint, cellSize, 18, 0);
    _drawFinder(canvas, paint, bgPaint, cellSize, 0, 18);
  }

  void _drawFinder(Canvas canvas, Paint dark, Paint light, double cs, double sc, double sr) {
    canvas.drawRect(Rect.fromLTWH(sc * cs, sr * cs, 7 * cs, 7 * cs), dark);
    canvas.drawRect(Rect.fromLTWH((sc + 1) * cs, (sr + 1) * cs, 5 * cs, 5 * cs), light);
    canvas.drawRect(Rect.fromLTWH((sc + 2) * cs, (sr + 2) * cs, 3 * cs, 3 * cs), dark);
  }

  @override
  bool shouldRepaint(_QRPainter old) => old.data != data;
}
