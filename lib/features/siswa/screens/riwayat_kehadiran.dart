// File: lib/features/siswa/screens/riwayat_kehadiran.dart
// ===========================================
// RIWAYAT KEHADIRAN & JURNAL – Siswa
// Connected to /kehadiran/siswa/:id API
// Pertemuan-based cards + dropdown filter + summary card
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class RiwayatKehadiran extends ConsumerStatefulWidget {
  const RiwayatKehadiran({super.key});

  @override
  ConsumerState<RiwayatKehadiran> createState() => _RiwayatKehadiranState();
}

class _RiwayatKehadiranState extends ConsumerState<RiwayatKehadiran> {
  String _selectedSubject = '';
  bool _loading = true;
  List<Map<String, dynamic>> _allMeetings = [];
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      final response = await ApiService.getKehadiranSiswa(userId);
      final List data = response['data'] ?? [];
      final meetings = data.cast<Map<String, dynamic>>();

      // Extract unique subjects
      final subjectSet = <String>{};
      for (final m in meetings) {
        subjectSet.add(m['mapel'] ?? 'Lainnya');
      }
      final subjects = subjectSet.toList()..sort();

      if (mounted) {
        setState(() {
          _allMeetings = meetings;
          _subjects = subjects;
          _selectedSubject = subjects.isNotEmpty ? subjects.first : '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Status styling ──
  ({Color bg, Color text, Color border, IconData icon}) _statusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'HADIR':
        return (bg: const Color(0xFFDCFCE7), text: const Color(0xFF15803D), border: const Color(0xFF86EFAC), icon: Icons.check_circle_outline);
      case 'SAKIT':
        return (bg: const Color(0xFFFEF3C7), text: const Color(0xFFB45309), border: const Color(0xFFFDE68A), icon: Icons.cancel_outlined);
      case 'IZIN':
        return (bg: const Color(0xFFDBEAFE), text: const Color(0xFF1D4ED8), border: const Color(0xFFBFDBFE), icon: Icons.watch_later_outlined);
      case 'ALPA':
        return (bg: const Color(0xFFFEE2E2), text: const Color(0xFFB91C1C), border: const Color(0xFFFCA5A5), icon: Icons.cancel_outlined);
      default:
        return (bg: const Color(0xFFF3F4F6), text: AppColors.gray600, border: const Color(0xFFE5E7EB), icon: Icons.help_outline);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final d = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final filtered = _allMeetings
        .where((m) => (m['mapel'] ?? '') == _selectedSubject)
        .toList()
      ..sort((a, b) => (b['pertemuanKe'] ?? 0).compareTo(a['pertemuanKe'] ?? 0));

    final hadir = filtered.where((m) => (m['status'] as String).toUpperCase() == 'HADIR').length;
    final sakit = filtered.where((m) => (m['status'] as String).toUpperCase() == 'SAKIT').length;
    final izin  = filtered.where((m) => (m['status'] as String).toUpperCase() == 'IZIN').length;
    final alpa  = filtered.where((m) => (m['status'] as String).toUpperCase() == 'ALPA').length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Header ──
          const Text(
            'Riwayat Kehadiran & Jurnal',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rekap kehadiran dan materi pembelajaran per pertemuan',
            style: TextStyle(fontSize: 14, color: AppColors.gray600),
          ),
          const SizedBox(height: 24),

          // ── Subject Dropdown ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Mata Pelajaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                const SizedBox(height: 10),
                if (_subjects.isEmpty)
                  const Text('Belum ada data mata pelajaran', style: TextStyle(color: AppColors.gray500))
                else
                  DropdownButtonFormField<String>(
                    initialValue: _subjects.contains(_selectedSubject) ? _selectedSubject : (_subjects.isNotEmpty ? _subjects.first : null),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
                      filled: true, fillColor: Colors.white,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.foreground),
                    items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _selectedSubject = v); },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Meeting Cards ──
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    const Icon(Icons.history_toggle_off, size: 64, color: AppColors.gray300),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada data riwayat untuk $_selectedSubject',
                      style: const TextStyle(color: AppColors.gray600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((meeting) => _buildMeetingCard(meeting)),

          // ── Summary Card ──
          if (filtered.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ringkasan Kehadiran – $_selectedSubject', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _summaryBox('Hadir', hadir, const Color(0xFF16A34A), const Color(0xFFF0FDF4), const Color(0xFFBBF7D0)),
                      const SizedBox(width: 12),
                      _summaryBox('Sakit', sakit, const Color(0xFFD97706), const Color(0xFFFFFBEB), const Color(0xFFFDE68A)),
                      const SizedBox(width: 12),
                      _summaryBox('Izin',  izin,  const Color(0xFF1D4ED8), const Color(0xFFEFF6FF), const Color(0xFFBFDBFE)),
                      const SizedBox(width: 12),
                      _summaryBox('Alpa',  alpa,  const Color(0xFFB91C1C), const Color(0xFFFFF5F5), const Color(0xFFFECACA)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Meeting Card ──
  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    final status = (meeting['status'] as String? ?? 'HADIR').toUpperCase();
    final style = _statusStyle(status);
    final pertemuan = meeting['pertemuanKe'] ?? 0;
    final tanggal = _formatDate(meeting['tanggal'] as String?);
    final topik = meeting['topik'] as String? ?? '-';
    final keterangan = meeting['keterangan'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Gradient Header ─
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.80)])),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text('Pertemuan $pertemuan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 16, color: Colors.white.withValues(alpha: 0.50)),
                      const SizedBox(width: 10),
                      Text(tanggal, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: style.border)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 14, color: style.text),
                      const SizedBox(width: 5),
                      Text(status, style: TextStyle(color: style.text, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─ Body ─
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Topik: $topik', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                      if (keterangan.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(keterangan, style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.5)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Box ──
  Widget _summaryBox(String label, int count, Color fg, Color bg, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.8))),
            const SizedBox(height: 4),
            Text('$count', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}
