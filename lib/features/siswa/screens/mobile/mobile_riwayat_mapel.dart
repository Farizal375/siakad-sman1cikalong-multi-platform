// File: lib/features/siswa/screens/mobile/mobile_riwayat_mapel.dart
// ===========================================
// MOBILE ATTENDANCE HISTORY BY SUBJECT
// Shows an accordion list of meetings for a subject
// ===========================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MobileRiwayatMapel extends StatefulWidget {
  final String mapel;
  final String guru;
  final List<Map<String, dynamic>> meetings;

  const MobileRiwayatMapel({
    super.key,
    required this.mapel,
    required this.guru,
    required this.meetings,
  });

  @override
  State<MobileRiwayatMapel> createState() => _MobileRiwayatMapelState();
}

class _MobileRiwayatMapelState extends State<MobileRiwayatMapel> {
  // Store expanded state for each meeting item
  final Set<int> _expandedItems = {};

  String _formatDate(String? s) {
    if (s == null) return '-';
    try {
      final d = DateTime.parse(s);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return s;
    }
  }

  ({Color bg, Color text, IconData icon}) _statusStyle(String s) {
    switch (s) {
      case 'HADIR':
        return (bg: const Color(0xFFDCFCE7), text: const Color(0xFF15803D), icon: Icons.check_circle);
      case 'TERLAMBAT':
        return (bg: const Color(0xFFFEF3C7), text: const Color(0xFFB45309), icon: Icons.watch_later);
      case 'SAKIT':
        return (bg: const Color(0xFFFEF3C7), text: const Color(0xFFB45309), icon: Icons.local_hospital);
      case 'IZIN':
        return (bg: const Color(0xFFDBEAFE), text: const Color(0xFF1D4ED8), icon: Icons.description);
      case 'ALPA':
        return (bg: const Color(0xFFFEE2E2), text: const Color(0xFFB91C1C), icon: Icons.cancel);
      default:
        return (bg: AppColors.gray100, text: AppColors.gray600, icon: Icons.help_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    // Sort meetings descending by pertemuanKe or tanggal
    final sortedMeetings = List<Map<String, dynamic>>.from(widget.meetings);
    sortedMeetings.sort((a, b) {
      final pA = a['pertemuanKe'] as int? ?? 0;
      final pB = b['pertemuanKe'] as int? ?? 0;
      if (pA != pB) return pA.compareTo(pB); // Ascending pertemuan
      return (a['tanggal'] as String? ?? '').compareTo(b['tanggal'] as String? ?? '');
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.mapel,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.foreground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: isDark ? const Color(0xFF374151) : AppColors.gray200, height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Pertemuan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fgColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pengajar: ${widget.guru}',
                  style: TextStyle(fontSize: 13, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: sortedMeetings.length,
              itemBuilder: (context, index) {
                final meeting = sortedMeetings[index];
                final isExpanded = _expandedItems.contains(index);
                return _buildMeetingItem(context, meeting, index, isExpanded);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingItem(BuildContext context, Map<String, dynamic> meeting, int index, bool isExpanded) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    final pertemuanKe = meeting['pertemuanKe'] as int? ?? (index + 1);
    final tanggal = _formatDate(meeting['tanggal'] as String?);
    final status = (meeting['status'] as String? ?? 'HADIR').toUpperCase();
    final style = _statusStyle(status);
    final topik = meeting['topik'] as String? ?? '-';
    final keterangan = meeting['keterangan'] as String? ?? '-';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
        ],
      ),
      child: Column(
        children: [
          // Header (Clickable)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(index);
                } else {
                  _expandedItems.add(index);
                }
              });
            },
            borderRadius: isExpanded 
                ? const BorderRadius.vertical(top: Radius.circular(12)) 
                : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'Pertemuan $pertemuanKe',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fgColor),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tanggal,
                    style: TextStyle(fontSize: 13, color: AppColors.gray500),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(style.icon, size: 12, color: style.text),
                        const SizedBox(width: 4),
                        Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: style.text)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.gray400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Content
          if (isExpanded) ...[
            Divider(height: 1, color: isDark ? AppColors.gray700 : AppColors.gray100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Pertemuan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray500),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Tanggal Realisasi', tanggal),
                  const SizedBox(height: 8),
                  _infoRow('Judul Materi', topik),
                  if (keterangan.isNotEmpty && keterangan != '-') ...[
                    const SizedBox(height: 8),
                    _infoRow('Deskripsi / Catatan', keterangan),
                  ],
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
        ),
        Text(
          ':',
          style: TextStyle(fontSize: 13, color: AppColors.gray500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.foreground,
            ),
          ),
        ),
      ],
    );
  }
}
