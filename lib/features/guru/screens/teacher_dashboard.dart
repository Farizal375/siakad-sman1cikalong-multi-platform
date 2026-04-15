// File: lib/features/guru/screens/teacher_dashboard.dart
// ===========================================
// TEACHER DASHBOARD
// Translated from TeacherDashboard.tsx
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final todaySchedule = [
      {
        'id': 1,
        'time': '07:00 - 08:30',
        'subject': 'Matematika',
        'class': 'Kelas XI-1',
        'room': 'Lab Komputer 1',
        'isActive': true,
        'canStart': true,
      },
      {
        'id': 2,
        'time': '09:00 - 10:30',
        'subject': 'Fisika',
        'class': 'Kelas XI-2',
        'room': 'Ruang 204',
        'isActive': false,
        'canStart': false,
      },
      {
        'id': 3,
        'time': '13:00 - 14:30',
        'subject': 'Matematika',
        'class': 'Kelas XI-3',
        'room': 'Ruang 301',
        'isActive': false,
        'canStart': false,
      },
    ];

    final kpiData = [
      {'title': 'Kelas Hari Ini', 'value': '3', 'subtitle': 'Pertemuan', 'color1': const Color(0xFF3B82F6), 'color2': const Color(0xFF2563EB), 'icon': Icons.calendar_today},
      {'title': 'Siswa Diajar', 'value': '142', 'subtitle': 'Siswa', 'color1': const Color(0xFF10B981), 'color2': const Color(0xFF059669), 'icon': Icons.people},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ──
        Text(
          '${_getGreeting()}, Ibu Siti!',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.foreground),
        ),
        const SizedBox(height: 8),
        const Text('Berikut adalah ringkasan jadwal dan tugas Anda hari ini.', style: TextStyle(color: AppColors.gray600)),
        const SizedBox(height: 24),

        // ── KPI Cards ──
        Row(
          children: kpiData.map((kpi) {
            final highlight = kpi['highlight'] as bool? ?? false;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(kpi['title'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                kpi['value'] as String,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: highlight ? AppColors.accent : AppColors.foreground,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(kpi['subtitle'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [kpi['color1'] as Color, kpi['color2'] as Color],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(kpi['icon'] as IconData, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // ── Main Content ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT – 70%
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  // Jadwal Hari Ini
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Jadwal Mengajar Hari Ini', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                                SizedBox(height: 4),
                                Text('Senin, 13 April 2026', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: AppColors.gray600),
                                const SizedBox(width: 4),
                                Text(
                                  TimeOfDay.now().format(context),
                                  style: const TextStyle(fontSize: 13, color: AppColors.gray600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ...todaySchedule.map((s) => _buildScheduleCard(s)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // RIGHT – 30%
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Pengumuman
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.campaign, color: AppColors.accent, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text('Pengumuman Sekolah', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAnnouncement('1. Rapat Pleno Guru', 'Jumat, 13:00 WIB', const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                        const SizedBox(height: 8),
                        _buildAnnouncement('2. Batas Pengisian Nilai UTS', 'Deadline: 15 April 2026', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                      ],
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

  Widget _buildScheduleCard(Map<String, dynamic> s) {
    final isActive = s['isActive'] as bool;
    final canStart = s['canStart'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? AppColors.accent : const Color(0xFFE5E7EB), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.accent : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        s['time'] as String,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.gray700,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            const Text('Berlangsung', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(s['subject'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text(s['class'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text(s['room'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                  ],
                ),
              ],
            ),
          ),
          if (canStart)
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('Buka Pertemuan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Belum Dimulai', style: TextStyle(color: AppColors.gray400, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }



  Widget _buildAnnouncement(String title, String sub, Color accent, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.foreground)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 12, color: accent)),
        ],
      ),
    );
  }

}
