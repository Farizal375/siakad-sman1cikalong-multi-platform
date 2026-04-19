// File: lib/features/kurikulum/screens/jadwal_overview.dart
// ===========================================
// JADWAL OVERVIEW (Schedule Monitoring)
// Connected to /jadwal + /rombel + /guru-mapel APIs
// Displays all classes' schedules for monitoring
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

class JadwalOverview extends StatefulWidget {
  const JadwalOverview({super.key});

  @override
  State<JadwalOverview> createState() => _JadwalOverviewState();
}

class _JadwalOverviewState extends State<JadwalOverview> {
  bool _loading = true;
  String? _expandedClass;

  List<Map<String, dynamic>> _classSchedules = [];
  List<Map<String, dynamic>> _teacherWorkloads = [];
  Map<String, List<Map<String, String>>> _classScheduleDetails = {};

  // KPI counters
  int _totalKelas = 0;
  int _terisiPenuh = 0;
  int _belumLengkap = 0;
  int _guruAktif = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load rombel (classes), jadwal, and guru-mapel concurrently
      final results = await Future.wait([
        ApiService.getRombel(),
        ApiService.getJadwal(),
        ApiService.getGuruMapel(),
      ]);

      final List rombelData = results[0]['data'] ?? [];
      final List jadwalData = results[1]['data'] ?? [];
      final List guruMapelData = results[2]['data'] ?? [];

      // Build class schedule summary
      final classMap = <String, Map<String, dynamic>>{};
      for (final r in rombelData) {
        final name = r['masterKelas'] ?? r['nama'] ?? r['kelas'] ?? '-';
        final wali = r['waliKelasName'] ?? r['waliKelas'] ?? '-';
        classMap[name] = {
          'name': name,
          'wali': wali,
          'filled': 0,
          'total': 40, // Default total slots per week
        };
      }

      // Count filled slots per class from jadwal
      final detailsMap = <String, List<Map<String, String>>>{};
      for (final j in jadwalData) {
        final kelas = j['kelas'] ?? j['masterKelas'] ?? '-';
        if (classMap.containsKey(kelas)) {
          classMap[kelas]!['filled'] = (classMap[kelas]!['filled'] as int) + 1;
        }
        // Build details
        detailsMap.putIfAbsent(kelas, () => []);
        detailsMap[kelas]!.add({
          'day': (j['hari'] ?? '-').toString(),
          'time': '${j['jamMulai'] ?? '07:00'}-${j['jamSelesai'] ?? '07:45'}',
          'subject': (j['mataPelajaran'] ?? j['mapel'] ?? '-').toString(),
          'teacher': (j['guru'] ?? j['guruName'] ?? '-').toString(),
        });
      }

      // Build teacher workloads from guru-mapel
      final workloads = <Map<String, dynamic>>[];
      final teacherSet = <String>{};
      for (final gm in guruMapelData) {
        final name = gm['guruName'] ?? gm['guru'] ?? '-';
        final subject = gm['mataPelajaranName'] ?? gm['mataPelajaran'] ?? '-';
        final quota = (gm['kuota'] as num?)?.toInt() ?? (gm['jumlahJam'] as num?)?.toInt() ?? 8;

        // Count how many jadwal entries this teacher has
        final scheduled = jadwalData.where((j) {
          final guruName = j['guru'] ?? j['guruName'] ?? '';
          return guruName == name;
        }).length;

        workloads.add({
          'name': name,
          'subject': subject,
          'scheduled': scheduled,
          'quota': quota,
        });
        teacherSet.add(name);
      }

      // KPI calculations
      final classes = classMap.values.toList();
      final fullCount = classes.where((c) => c['filled'] >= c['total']).length;

      if (mounted) {
        setState(() {
          _classSchedules = classes;
          _classScheduleDetails = detailsMap;
          _teacherWorkloads = workloads;
          _totalKelas = classes.length;
          _terisiPenuh = fullCount;
          _belumLengkap = classes.length - fullCount;
          _guruAktif = teacherSet.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        const Text('Monitoring Jadwal', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 8),
        const Text('Pantau jadwal seluruh kelas dalam satu halaman', style: TextStyle(color: AppColors.gray600)),
        const SizedBox(height: 32),

        // ── KPI Cards ──
        Row(
          children: [
            const Spacer(),
            _KpiMiniCard(icon: Icons.class_outlined, label: 'Total Kelas', value: '$_totalKelas', color: AppColors.primary),
            const SizedBox(width: 12),
            _KpiMiniCard(icon: Icons.check_circle_outline, label: 'Terisi Penuh', value: '$_terisiPenuh', color: const Color(0xFF16A34A)),
            const SizedBox(width: 12),
            _KpiMiniCard(icon: Icons.warning_amber_rounded, label: 'Belum Lengkap', value: '$_belumLengkap', color: const Color(0xFFD97706)),
            const SizedBox(width: 12),
            _KpiMiniCard(icon: Icons.people_outline, label: 'Guru Aktif', value: '$_guruAktif', color: const Color(0xFF7C3AED)),
          ],
        ),
        const SizedBox(height: 24),

        // ── Class Schedule Cards ──
        Expanded(
          child: _classSchedules.isEmpty
              ? const Center(child: Text('Belum ada data kelas', style: TextStyle(color: AppColors.gray500)))
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Class cards grid
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _classSchedules.map((cls) {
                            final name = cls['name'] as String;
                            final isExpanded = _expandedClass == name;
                            return _ClassScheduleCard(
                              className: name,
                              waliKelas: cls['wali'] as String,
                              filled: cls['filled'] as int,
                              total: cls['total'] as int,
                              isExpanded: isExpanded,
                              schedule: _classScheduleDetails[name] ?? [],
                              onTap: () {
                                setState(() {
                                  _expandedClass = isExpanded ? null : name;
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
                              child: _teacherWorkloads.isEmpty
                                  ? const Center(child: Text('Belum ada data guru', style: TextStyle(color: AppColors.gray500)))
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: _teacherWorkloads.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (_, i) {
                                        final tw = _teacherWorkloads[i];
                                        final scheduled = (tw['scheduled'] as num).toInt();
                                        final quota = (tw['quota'] as num).toInt();
                                        final ratio = quota > 0 ? (scheduled / quota).clamp(0.0, 1.0) : 0.0;
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
                                                  Expanded(child: Text(tw['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                                                  Text(
                                                    '$scheduled / $quota jp',
                                                    style: TextStyle(
                                                      fontSize: 13, fontWeight: FontWeight.w700,
                                                      color: isOver ? const Color(0xFFDC2626) : isFull ? const Color(0xFF16A34A) : AppColors.foreground,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(tw['subject'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
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

  const _KpiMiniCard({required this.icon, required this.label, required this.value, required this.color});

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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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
    required this.className, required this.waliKelas, required this.filled, required this.total,
    required this.isExpanded, required this.schedule, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (filled / total).clamp(0.0, 1.0) : 0.0;
    final isFull = filled >= total;
    final cardWidth = isExpanded ? MediaQuery.of(context).size.width * 0.6 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: isExpanded ? const Color(0x25000000) : const Color(0x15000000), blurRadius: isExpanded ? 16 : 10, offset: const Offset(0, 4))],
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
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2563EB)]), borderRadius: BorderRadius.circular(12)),
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
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.gray400),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: AppColors.gray200,
                        valueColor: AlwaysStoppedAnimation<Color>(isFull ? const Color(0xFF16A34A) : AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$filled / $total slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isFull ? const Color(0xFF16A34A) : AppColors.foreground)),
                ],
              ),
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
// MINI SCHEDULE TABLE
// ═══════════════════════════════════════════════
class _MiniScheduleTable extends StatelessWidget {
  final List<Map<String, String>> schedule;
  const _MiniScheduleTable({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray200))),
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
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray100))),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text(s['day'] ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.foreground))),
                SizedBox(width: 80, child: Text(s['time'] ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'monospace'))),
                Expanded(child: Text(s['subject'] ?? '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.foreground))),
                Expanded(child: Text(s['teacher'] ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.gray600))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
