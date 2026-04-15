// File: lib/features/kurikulum/screens/jadwal_overview.dart
// ===========================================
// JADWAL OVERVIEW (Schedule Monitoring)
// Displays all classes' schedules for monitoring
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class JadwalOverview extends StatefulWidget {
  const JadwalOverview({super.key});

  @override
  State<JadwalOverview> createState() => _JadwalOverviewState();
}

class _JadwalOverviewState extends State<JadwalOverview> {
  String _selectedTahunAjaran = '2026/2027';
  String? _expandedClass;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        const Text(
          'Monitoring Jadwal',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pantau jadwal seluruh kelas dalam satu halaman',
          style: TextStyle(color: AppColors.gray600),
        ),
        const SizedBox(height: 32),

        // ── Filter + KPI Cards ──
        Row(
          children: [
            // Filter
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedTahunAjaran,
                items: ['2026/2027', '2025/2026'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedTahunAjaran = v ?? _selectedTahunAjaran),
                decoration: InputDecoration(
                  labelText: 'Tahun Ajaran',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const Spacer(),
            // KPI Mini Cards
            _KpiMiniCard(icon: Icons.class_outlined, label: 'Total Kelas', value: '5', color: AppColors.primary),
            const SizedBox(width: 12),
            _KpiMiniCard(icon: Icons.check_circle_outline, label: 'Terisi Penuh', value: '3', color: const Color(0xFF16A34A)),
            const SizedBox(width: 12),
            _KpiMiniCard(icon: Icons.warning_amber_rounded, label: 'Belum Lengkap', value: '2', color: const Color(0xFFD97706)),
            const SizedBox(width: 12),
            _KpiMiniCard(icon: Icons.people_outline, label: 'Guru Aktif', value: '7', color: const Color(0xFF7C3AED)),
          ],
        ),
        const SizedBox(height: 24),

        // ── Class Schedule Cards ──
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Class cards grid
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _allClassSchedules.map((cls) {
                      final isExpanded = _expandedClass == cls['name'];
                      return _ClassScheduleCard(
                        className: cls['name']!,
                        waliKelas: cls['wali']!,
                        filled: int.parse(cls['filled']!),
                        total: int.parse(cls['total']!),
                        isExpanded: isExpanded,
                        schedule: _classScheduleDetails[cls['name']!] ?? [],
                        onTap: () {
                          setState(() {
                            _expandedClass = isExpanded ? null : cls['name'];
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Right: Teacher Workload Summary
              SizedBox(
                width: 360,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9333EA)]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text('Beban Mengajar Guru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.gray200),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _teacherWorkloads.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final tw = _teacherWorkloads[i];
                            final scheduled = int.parse(tw['scheduled']!);
                            final quota = int.parse(tw['quota']!);
                            final ratio = (scheduled / quota).clamp(0.0, 1.0);
                            final isFull = scheduled >= quota;
                            final isOver = scheduled > quota;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isOver ? const Color(0xFFFEF2F2) : AppColors.gray50,
                                borderRadius: BorderRadius.circular(12),
                                border: isOver ? Border.all(color: const Color(0xFFFCA5A5)) : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(tw['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                                      ),
                                      Text(
                                        '$scheduled / $quota jp',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isOver ? const Color(0xFFDC2626) : isFull ? const Color(0xFF16A34A) : AppColors.foreground,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(tw['subject']!, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 6,
                                      backgroundColor: AppColors.gray200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isOver ? const Color(0xFFDC2626) : isFull ? const Color(0xFF16A34A) : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  if (isFull) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isOver ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isOver ? 'Melebihi Kuota!' : 'Kuota Penuh',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isOver ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// KPI MINI CARD
// ═══════════════════════════════════════════════
class _KpiMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
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
    );
  }
}

// ═══════════════════════════════════════════════
// CLASS SCHEDULE CARD (Expandable)
// ═══════════════════════════════════════════════
class _ClassScheduleCard extends StatelessWidget {
  final String className;
  final String waliKelas;
  final int filled;
  final int total;
  final bool isExpanded;
  final List<Map<String, String>> schedule;
  final VoidCallback onTap;

  const _ClassScheduleCard({
    required this.className,
    required this.waliKelas,
    required this.filled,
    required this.total,
    required this.isExpanded,
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (filled / total).clamp(0.0, 1.0);
    final isFull = filled >= total;
    final cardWidth = isExpanded ? MediaQuery.of(context).size.width * 0.6 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? const Color(0x25000000) : const Color(0x15000000),
            blurRadius: isExpanded ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isFull ? Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4), width: 2) : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(className.split(' ').last, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(className, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                        Text('Wali: $waliKelas', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.gray400,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: AppColors.gray200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isFull ? const Color(0xFF16A34A) : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$filled / $total slot',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isFull ? const Color(0xFF16A34A) : AppColors.foreground,
                    ),
                  ),
                ],
              ),

              // Expanded mini schedule
              if (isExpanded && schedule.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.gray200),
                const SizedBox(height: 12),
                const Text('Jadwal Mingguan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                const SizedBox(height: 8),
                _MiniScheduleTable(schedule: schedule),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// MINI SCHEDULE TABLE (inside expanded card)
// ═══════════════════════════════════════════════
class _MiniScheduleTable extends StatelessWidget {
  final List<Map<String, String>> schedule;
  const _MiniScheduleTable({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.gray200)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 60, child: Text('Hari', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                SizedBox(width: 80, child: Text('Waktu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                Expanded(child: Text('Mapel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                Expanded(child: Text('Guru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              ],
            ),
          ),
          ...schedule.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.gray100)),
            ),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text(s['day']!, style: const TextStyle(fontSize: 11, color: AppColors.foreground))),
                SizedBox(width: 80, child: Text(s['time']!, style: const TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'monospace'))),
                Expanded(child: Text(s['subject']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.foreground))),
                Expanded(child: Text(s['teacher']!, style: const TextStyle(fontSize: 11, color: AppColors.gray600))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// STATIC DATA
// ═══════════════════════════════════════════════
const List<Map<String, String>> _allClassSchedules = [
  {'name': 'X IPA 1', 'wali': 'Dr. Siti Nurhaliza', 'filled': '18', 'total': '40'},
  {'name': 'X IPA 2', 'wali': 'Budi Santoso, M.Pd', 'filled': '22', 'total': '40'},
  {'name': 'XI IPA 1', 'wali': 'Ahmad Hidayat, S.Pd', 'filled': '40', 'total': '40'},
  {'name': 'XI IPS 1', 'wali': 'Prof. Dr. Ani W.', 'filled': '30', 'total': '40'},
  {'name': 'XII IPA 1', 'wali': 'Rina Kartika, S.Pd', 'filled': '36', 'total': '40'},
];

const List<Map<String, String>> _teacherWorkloads = [
  {'name': 'Dr. Siti Nurhaliza, S.Pd', 'subject': 'Matematika Wajib', 'scheduled': '12', 'quota': '12'},
  {'name': 'Budi Santoso, M.Pd', 'subject': 'Fisika', 'scheduled': '8', 'quota': '8'},
  {'name': 'Ahmad Hidayat, S.Pd', 'subject': 'Kimia', 'scheduled': '10', 'quota': '12'},
  {'name': 'Rina Kartika, S.Pd', 'subject': 'Biologi', 'scheduled': '6', 'quota': '8'},
  {'name': 'Prof. Dr. Ani Widiastuti', 'subject': 'Bahasa Indonesia', 'scheduled': '12', 'quota': '12'},
  {'name': 'Drs. Hendra Gunawan', 'subject': 'Bahasa Inggris', 'scheduled': '7', 'quota': '8'},
  {'name': 'Ir. Subekti, M.Si', 'subject': 'Matematika Peminatan', 'scheduled': '8', 'quota': '8'},
];

final Map<String, List<Map<String, String>>> _classScheduleDetails = {
  'X IPA 1': [
    {'day': 'Senin', 'time': '07:00-07:45', 'subject': 'Matematika', 'teacher': 'Dr. Siti N.'},
    {'day': 'Senin', 'time': '07:45-08:30', 'subject': 'Matematika', 'teacher': 'Dr. Siti N.'},
    {'day': 'Senin', 'time': '08:30-09:15', 'subject': 'Fisika', 'teacher': 'Budi S.'},
    {'day': 'Selasa', 'time': '07:00-07:45', 'subject': 'B. Indonesia', 'teacher': 'Prof. Ani'},
    {'day': 'Selasa', 'time': '07:45-08:30', 'subject': 'B. Indonesia', 'teacher': 'Prof. Ani'},
    {'day': 'Selasa', 'time': '08:30-09:15', 'subject': 'Kimia', 'teacher': 'Ahmad H.'},
    {'day': 'Selasa', 'time': '09:30-10:15', 'subject': 'Kimia', 'teacher': 'Ahmad H.'},
    {'day': 'Rabu', 'time': '07:00-07:45', 'subject': 'B. Inggris', 'teacher': 'Drs. Hendra'},
    {'day': 'Rabu', 'time': '07:45-08:30', 'subject': 'B. Inggris', 'teacher': 'Drs. Hendra'},
    {'day': 'Rabu', 'time': '09:30-10:15', 'subject': 'Biologi', 'teacher': 'Rina K.'},
    {'day': 'Rabu', 'time': '10:15-11:00', 'subject': 'Biologi', 'teacher': 'Rina K.'},
    {'day': 'Kamis', 'time': '07:00-07:45', 'subject': 'PKN', 'teacher': 'Drs. Agus'},
    {'day': 'Kamis', 'time': '07:45-08:30', 'subject': 'Sejarah', 'teacher': 'Dra. Lina'},
    {'day': 'Kamis', 'time': '09:30-10:15', 'subject': 'Fisika', 'teacher': 'Budi S.'},
    {'day': 'Kamis', 'time': '10:15-11:00', 'subject': 'Fisika', 'teacher': 'Budi S.'},
    {'day': 'Jumat', 'time': '07:00-07:45', 'subject': 'PAI', 'teacher': 'Ust. Rahman'},
    {'day': 'Jumat', 'time': '07:45-08:30', 'subject': 'B. Sunda', 'teacher': 'Ibu Neng'},
    {'day': 'Jumat', 'time': '08:30-09:15', 'subject': 'Olahraga', 'teacher': 'Pak Deni'},
  ],
  'X IPA 2': [
    {'day': 'Senin', 'time': '07:00-08:30', 'subject': 'Matematika', 'teacher': 'Dr. Siti N.'},
    {'day': 'Senin', 'time': '08:30-09:15', 'subject': 'Kimia', 'teacher': 'Ahmad H.'},
    {'day': 'Selasa', 'time': '07:00-08:30', 'subject': 'B. Indonesia', 'teacher': 'Prof. Ani'},
    {'day': 'Rabu', 'time': '07:00-08:30', 'subject': 'B. Inggris', 'teacher': 'Drs. Hendra'},
  ],
  'XI IPA 1': [
    {'day': 'Senin', 'time': '07:00-08:30', 'subject': 'Mat. Peminatan', 'teacher': 'Ir. Subekti'},
    {'day': 'Senin', 'time': '08:30-10:15', 'subject': 'Fisika', 'teacher': 'Budi S.'},
    {'day': 'Selasa', 'time': '07:00-08:30', 'subject': 'Kimia', 'teacher': 'Ahmad H.'},
    {'day': 'Selasa', 'time': '08:30-10:15', 'subject': 'Biologi', 'teacher': 'Rina K.'},
    {'day': 'Rabu', 'time': '07:00-09:15', 'subject': 'Matematika', 'teacher': 'Dr. Siti N.'},
    {'day': 'Kamis', 'time': '07:00-08:30', 'subject': 'B. Indonesia', 'teacher': 'Prof. Ani'},
    {'day': 'Jumat', 'time': '07:00-09:15', 'subject': 'B. Inggris', 'teacher': 'Drs. Hendra'},
  ],
};
