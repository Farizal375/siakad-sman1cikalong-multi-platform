// File: lib/features/siswa/screens/mobile/mobile_riwayat_kehadiran.dart
// ===========================================
// MOBILE ATTENDANCE HISTORY (FR-06.4)
// Subject filter + attendance cards + 2×2 summary grid
// Connected to /kehadiran/siswa/:id API
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/providers/auth_provider.dart';

class MobileRiwayatKehadiran extends ConsumerStatefulWidget {
  const MobileRiwayatKehadiran({super.key});

  @override
  ConsumerState<MobileRiwayatKehadiran> createState() => _MobileRiwayatKehadiranState();
}

class _MobileRiwayatKehadiranState extends ConsumerState<MobileRiwayatKehadiran> {
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
    setState(() => _loading = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      final response = await ApiService.getKehadiranSiswa(userId);
      final List data = response['data'] ?? [];
      final meetings = data.cast<Map<String, dynamic>>();
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

  ({Color bg, Color text, Color border, IconData icon}) _statusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'HADIR':
        return (bg: const Color(0xFFDCFCE7), text: const Color(0xFF15803D), border: const Color(0xFF86EFAC), icon: Icons.check_circle_outline);
      case 'SAKIT':
        return (bg: const Color(0xFFFEF3C7), text: const Color(0xFFB45309), border: const Color(0xFFFDE68A), icon: Icons.local_hospital_outlined);
      case 'IZIN':
        return (bg: const Color(0xFFDBEAFE), text: const Color(0xFF1D4ED8), border: const Color(0xFFBFDBFE), icon: Icons.description_outlined);
      case 'ALPA':
        return (bg: const Color(0xFFFEE2E2), text: const Color(0xFFB91C1C), border: const Color(0xFFFCA5A5), icon: Icons.cancel_outlined);
      default:
        return (bg: AppColors.gray100, text: AppColors.gray600, border: AppColors.gray200, icon: Icons.help_outline);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final d = DateTime.parse(dateStr);
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton(context);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    final filtered = _allMeetings.where((m) => (m['mapel'] ?? '') == _selectedSubject).toList()
      ..sort((a, b) => (b['pertemuanKe'] ?? 0).compareTo(a['pertemuanKe'] ?? 0));

    final hadir = filtered.where((m) => (m['status'] as String).toUpperCase() == 'HADIR').length;
    final sakit = filtered.where((m) => (m['status'] as String).toUpperCase() == 'SAKIT').length;
    final izin = filtered.where((m) => (m['status'] as String).toUpperCase() == 'IZIN').length;
    final alpa = filtered.where((m) => (m['status'] as String).toUpperCase() == 'ALPA').length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Riwayat Kehadiran', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: fgColor)),
            const SizedBox(height: 4),
            Text('Rekap kehadiran per pertemuan', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          ]),
        ),
        const SizedBox(height: 16),
        if (_subjects.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: theme.cardTheme.color ?? Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _subjects.contains(_selectedSubject) ? _selectedSubject : (_subjects.isNotEmpty ? _subjects.first : null),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fgColor),
                dropdownColor: theme.cardTheme.color ?? Colors.white,
                items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) { if (v != null) setState(() => _selectedSubject = v); },
              ),
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAttendance,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              children: [
                _buildSummaryGrid(context, hadir, sakit, izin, alpa),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  _buildEmpty(context)
                else
                  ...filtered.map((m) => _buildMeetingCard(context, m)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(BuildContext context, int hadir, int sakit, int izin, int alpa) {
    return Column(children: [
      Row(children: [
        _tile(context, 'Hadir', hadir, const Color(0xFF16A34A), AppColors.green50),
        const SizedBox(width: 10),
        _tile(context, 'Sakit', sakit, const Color(0xFFD97706), AppColors.amber50),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _tile(context, 'Izin', izin, const Color(0xFF1D4ED8), AppColors.blue50),
        const SizedBox(width: 10),
        _tile(context, 'Alpa', alpa, const Color(0xFFDC2626), AppColors.red50),
      ]),
    ]);
  }

  Widget _tile(BuildContext context, String label, int count, Color color, Color bg) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.cardTheme.color ?? Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: isDark ? 0.4 : 0.2))),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)))),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  Widget _buildMeetingCard(BuildContext context, Map<String, dynamic> meeting) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    
    final status = (meeting['status'] as String? ?? 'HADIR').toUpperCase();
    final style = _statusStyle(status);
    final pertemuan = meeting['pertemuanKe'] ?? 0;
    final tanggal = _formatDate(meeting['tanggal'] as String?);
    final topik = meeting['topik'] as String? ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: theme.cardTheme.color ?? Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200)),
      child: IntrinsicHeight(
        child: Row(children: [
          Container(width: 4, decoration: BoxDecoration(color: style.text, borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)))),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Pertemuan $pertemuan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fgColor))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: style.border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(style.icon, size: 12, color: style.text),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: style.text)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.calendar_today, size: 12, color: AppColors.gray400),
                const SizedBox(width: 6),
                Text(tanggal, style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                const SizedBox(width: 16),
                Icon(Icons.description_outlined, size: 12, color: AppColors.gray400),
                const SizedBox(width: 6),
                Expanded(child: Text(topik, style: TextStyle(fontSize: 12, color: AppColors.gray600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Icon(Icons.history_toggle_off, size: 56, color: AppColors.gray300),
        const SizedBox(height: 12),
        Text('Tidak ada riwayat untuk $_selectedSubject', style: TextStyle(color: AppColors.gray500)),
      ]),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(padding: const EdgeInsets.all(20), children: List.generate(5, (_) => Container(
      height: 72, margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1F2937) : AppColors.gray100, borderRadius: BorderRadius.circular(14)),
    )));
  }
}
