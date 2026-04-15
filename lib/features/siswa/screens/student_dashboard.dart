// File: lib/features/siswa/screens/student_dashboard.dart
// ===========================================
// STUDENT DASHBOARD
// Translated from StudentDashboard.tsx
// Jadwal hari ini + pengumuman + info cepat
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final todaySchedule = [
      {'id': 1, 'jam': '07:30 - 09:00', 'mapel': 'Matematika', 'guru': 'Drs. Ahmad Hidayat', 'ruang': 'XII-1', 'isActive': false},
      {'id': 2, 'jam': '09:15 - 10:45', 'mapel': 'Fisika', 'guru': 'Dr. Siti Nurhaliza, M.Pd', 'ruang': 'Lab Fisika', 'isActive': true},
      {'id': 3, 'jam': '11:00 - 12:30', 'mapel': 'Bahasa Inggris', 'guru': 'Sarah Johnson, S.Pd', 'ruang': 'XII-1', 'isActive': false},
      {'id': 4, 'jam': '13:00 - 14:30', 'mapel': 'Kimia', 'guru': 'Prof. Dr. Budi Santoso', 'ruang': 'Lab Kimia', 'isActive': false},
    ];

    final announcements = [
      {'id': 1, 'title': 'Ujian Tengah Semester - Jadwal Terbaru', 'date': '8 April 2026', 'preview': 'Jadwal UTS telah diperbarui. Mohon perhatikan perubahan waktu untuk mata pelajaran Matematika dan Fisika.'},
      {'id': 2, 'title': 'Libur Hari Raya Idul Fitri', 'date': '5 April 2026', 'preview': 'Sekolah akan libur mulai tanggal 15-25 April 2026. Pembelajaran online akan dimulai tanggal 26 April.'},
      {'id': 3, 'title': 'Pengumpulan Tugas Proyek Akhir', 'date': '3 April 2026', 'preview': 'Batas akhir pengumpulan tugas proyek semester adalah 20 April 2026 pukul 23:59 WIB.'},
    ];

    final quickInfo = [
      {'title': 'Rata-rata Smt Terakhir', 'value': '88.5', 'icon': Icons.trending_up, 'color': const Color(0xFF059669), 'cardColor': const Color(0xFFECFDF5)},
      {'title': 'Total Kehadiran', 'value': '95%', 'icon': Icons.calendar_today, 'color': const Color(0xFF2563EB), 'cardColor': const Color(0xFFEFF6FF)},
      {'title': 'Tugas Tertunda', 'value': '2', 'subtitle': 'Tugas', 'icon': Icons.menu_book, 'color': const Color(0xFFD97706), 'cardColor': const Color(0xFFFFFBEB)},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          const Text('Selamat Datang, Ahmad!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 8),
        const Text('Kelas XII-1 • NISN: 2023001', style: TextStyle(color: AppColors.gray600)),
        const SizedBox(height: 24),

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
              const Text('Jadwal Pelajaran Hari Ini', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 20),
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pengumuman', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 20),
                    ...announcements.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(a['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.foreground))),
                              Text(a['date'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(a['preview'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {},
                            child: const Text('Baca Selengkapnya →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ),
                        ],
                      ),
                    )),
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
                  const Text('Info Cepat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  ...quickInfo.map((info) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                              Text(info['title'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(info['value'] as String, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: info['color'] as Color)),
                                  if (info.containsKey('subtitle')) ...[
                                    const SizedBox(width: 4),
                                    Text(info['subtitle'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: info['cardColor'] as Color, borderRadius: BorderRadius.circular(10)),
                          child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 20),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> s) {
    final isActive = s['isActive'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFFBEB) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? AppColors.accent : const Color(0xFFE5E7EB), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Time
              SizedBox(
                width: 110,
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(s['jam'] as String, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
                  ],
                ),
              ),
              // Subject
              Expanded(child: Text(s['mapel'] as String, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.foreground))),
              // Teacher
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Expanded(child: Text(s['guru'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray700), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              // Room
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray500),
                  const SizedBox(width: 4),
                  Text(s['ruang'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
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
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Sedang Berlangsung', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
