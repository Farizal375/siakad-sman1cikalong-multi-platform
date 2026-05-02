// File: lib/features/siswa/screens/student_dashboard.dart
// ===========================================
// STUDENT DASHBOARD
// Connected to /dashboard/siswa API
// Jadwal hari ini + berita sekolah + info cepat
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final response = await ApiService.getSiswaDashboard();
      if (mounted) {
        setState(() {
          _data = response['data'] ?? {};
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

    final kelas = _data['kelas'] ?? '-';
    final hari = _data['hari'] ?? '-';
    final todaySchedule = (_data['jadwalHariIni'] as List? ?? [])
        .map<Map<String, dynamic>>(
          (j) => {
            'id': j['id'] ?? '',
            'jam': '${j['startTime'] ?? ''} - ${j['endTime'] ?? ''}',
            'mapel': j['subject'] ?? '-',
            'guru': j['teacher'] ?? '-',
            'ruang': j['room'] ?? '-',
            'isActive': false,
          },
        )
        .toList();

    // Mark first upcoming as active
    if (todaySchedule.isNotEmpty) {
      todaySchedule[0]['isActive'] = true;
    }

    final announcements = (_data['pengumuman'] as List? ?? [])
        .map<Map<String, dynamic>>((a) {
          final createdAt = a['createdAt'] ?? '';
          String dateStr = '';
          try {
            final dt = DateTime.parse(createdAt);
            dateStr = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
          } catch (_) {
            dateStr = createdAt;
          }
          return {
            'id': a['id'] ?? '',
            'title': a['title'] ?? a['judul'] ?? '-',
            'date': dateStr,
            'preview': a['content'] ?? a['konten'] ?? '',
          };
        })
        .toList();

    final kehadiran = _data['kehadiran'] as Map<String, dynamic>? ?? {};
    final totalHadir = kehadiran['hadir'] ?? 0;
    final totalSakit = kehadiran['sakit'] ?? 0;
    final totalIzin = kehadiran['izin'] ?? 0;
    final totalAlpa = kehadiran['alpa'] ?? 0;
    final totalAll = totalHadir + totalSakit + totalIzin + totalAlpa;
    final attendanceRate = totalAll > 0
        ? ((totalHadir / totalAll) * 100).round()
        : 0;
    final periode = kehadiran['periode'] as Map<String, dynamic>?;
    final periodeLabel = periode?['label'] as String? ?? '';

    final quickInfo = [
      {
        'title': 'Presensi Bulan Ini',
        'value': '$attendanceRate%',
        'icon': Icons.calendar_today,
        'color': const Color(0xFF2563EB),
        'cardColor': const Color(0xFFEFF6FF),
      },
      {
        'title': 'Hadir',
        'value': '$totalHadir',
        'subtitle': 'Sesi',
        'icon': Icons.check_circle,
        'color': const Color(0xFF059669),
        'cardColor': const Color(0xFFECFDF5),
      },
      {
        'title': 'Tidak Hadir',
        'value': '${totalSakit + totalIzin + totalAlpa}',
        'subtitle': 'Sesi',
        'icon': Icons.cancel,
        'color': const Color(0xFFD97706),
        'cardColor': const Color(0xFFFFFBEB),
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          const Text(
            'Selamat Datang, Siswa!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelas $kelas • Hari: $hari',
            style: const TextStyle(color: AppColors.gray600),
          ),
          const SizedBox(height: 24),

          // Jadwal Hari Ini
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Jadwal Pelajaran Hari Ini',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/siswa/jadwal'),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('Lihat Semua'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (todaySchedule.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Tidak ada jadwal hari ini',
                        style: TextStyle(color: AppColors.gray500),
                      ),
                    ),
                  )
                else
                  ...todaySchedule.map((s) => _buildScheduleItem(s)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Split
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left – Announcements (70%)
              Expanded(
                flex: 7,
                child: Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Berita Sekolah',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (announcements.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Belum ada berita sekolah',
                              style: TextStyle(color: AppColors.gray500),
                            ),
                          ),
                        )
                      else
                        ...announcements.map(
                          (a) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        a['title'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.foreground,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      a['date'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  a['preview'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.gray600,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'Baca Selengkapnya →',
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
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Right – Quick Info (30%)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Info Cepat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    if (periodeLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Presensi $periodeLabel',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                    if (totalAll == 0) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Belum ada data presensi bulan ini',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...quickInfo.map(
                      (info) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
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
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        info['value'] as String,
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: info['color'] as Color,
                                        ),
                                      ),
                                      if (info.containsKey('subtitle')) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          info['subtitle'] as String,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: info['cardColor'] as Color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                info['icon'] as IconData,
                                color: info['color'] as Color,
                                size: 20,
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
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  Widget _buildScheduleItem(Map<String, dynamic> s) {
    final isActive = s['isActive'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFFBEB) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.accent : const Color(0xFFE5E7EB),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Time
              SizedBox(
                width: 130,
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s['jam'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Subject
              Expanded(
                child: Text(
                  s['mapel'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              // Room
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.gray500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s['ruang'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFFDE68A)),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Sedang Berlangsung',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
