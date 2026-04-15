// File: lib/features/guru/screens/student_deep_dive.dart
// ===========================================
// STUDENT DEEP DIVE – Wali Kelas
// Translated from StudentDeepDive.tsx
// Profil siswa + Tab transkrip 2 semester + catatan
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/success_toast.dart';

class StudentDeepDive extends StatefulWidget {
  final String? studentId;
  const StudentDeepDive({super.key, this.studentId});

  @override
  State<StudentDeepDive> createState() => _StudentDeepDiveState();
}

class _StudentDeepDiveState extends State<StudentDeepDive> {
  String _activeTab = 'transcript'; // 'transcript' | 'chart'
  bool _showToast = false;

  final _semesterGanjil = [
    {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 84, 'predikat': 'Sangat Baik'},
    {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
    {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 90, 'predikat': 'Sangat Baik'},
    {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
    {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
    {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 96, 'predikat': 'Sangat Baik'},
  ];

  final _semesterGenap = [
    {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 85, 'predikat': 'Sangat Baik'},
    {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 78, 'predikat': 'Baik'},
    {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 92, 'predikat': 'Sangat Baik'},
    {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
    {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
    {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 90, 'predikat': 'Sangat Baik'},
  ];

  double _calcAverage(List<Map<String, dynamic>> grades) {
    final sum = grades.fold<int>(0, (acc, g) => acc + (g['nilai'] as int));
    return sum / grades.length;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/guru/cetak-rapor'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Kembali ke Daftar Siswa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => setState(() { _showToast = true; }),
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Cetak Rapor Siswa (PDF)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Student Profile Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, Color(0xFF3B82F6)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ahmad Fauzi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Text('NISN: 0012345671', style: TextStyle(color: AppColors.gray600)),
                              SizedBox(width: 8),
                              Text('•', style: TextStyle(color: AppColors.gray400)),
                              SizedBox(width: 8),
                              Text('Kelas XI-1', style: TextStyle(color: AppColors.gray600)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _kpiBox(Icons.emoji_events, const Color(0xFF3B82F6), const Color(0xFFEFF6FF), 'Rata-rata Keseluruhan', '87.2'),
                              const SizedBox(width: 12),
                              _kpiBox(Icons.trending_up, const Color(0xFF10B981), const Color(0xFFECFDF5), 'Peringkat', '2 dari 36'),
                              const SizedBox(width: 12),
                              _kpiBox(Icons.calendar_today, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF), 'Kehadiran', '98%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Academic Performance
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    // Tab Bar
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _tabBtn('transcript', 'Transkrip 2 Semester')),
                          const SizedBox(width: 8),
                          Expanded(child: _tabBtn('chart', 'Grafik Perkembangan')),
                        ],
                      ),
                    ),

                    // Tab Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _activeTab == 'transcript'
                          ? Column(
                              children: [
                                _buildTranscript('Semester Ganjil 2025/2026', _semesterGanjil),
                                const SizedBox(height: 32),
                                _buildTranscript('Semester Genap 2025/2026', _semesterGenap),
                              ],
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.trending_up, size: 64, color: AppColors.gray300),
                                    SizedBox(height: 16),
                                    Text('Grafik perkembangan nilai sedang dalam pengembangan', style: TextStyle(color: AppColors.gray600)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Character Note
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
                    const Text('Catatan Wali Kelas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                      ),
                      child: const Text(
                        'Ahmad menunjukkan perkembangan yang sangat baik dalam semester ini. Sikapnya sopan dan penuh tanggung jawab. Aktif dalam kegiatan organisasi OSIS dan selalu tepat waktu mengumpulkan tugas. Perlu ditingkatkan kemampuan presentasi di depan kelas.',
                        style: TextStyle(color: AppColors.foreground, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),

        if (_showToast)
          Positioned(
            top: 16, right: 16,
            child: SuccessToast(
              isVisible: true,
              message: 'Mencetak e-Rapor Ahmad Fauzi.pdf',
              onClose: () => setState(() => _showToast = false),
            ),
          ),
      ],
    );
  }

  Widget _tabBtn(String id, String label) {
    final active = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.gray600, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscript(String title, List<Map<String, dynamic>> grades) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 12),
        Table(
          border: TableBorder.all(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
          columnWidths: const {0: FixedColumnWidth(50), 1: FlexColumnWidth(3), 2: FixedColumnWidth(60), 3: FixedColumnWidth(80), 4: FlexColumnWidth(2)},
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
              children: ['No', 'Mata Pelajaran', 'KKM', 'Nilai Angka', 'Predikat']
                  .map((h) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      ))
                  .toList(),
            ),
            ...grades.asMap().entries.map((e) {
              final g = e.value;
              return TableRow(
                decoration: BoxDecoration(color: e.key % 2 == 0 ? const Color(0xFFF9FAFB) : Colors.white),
                children: [
                  Padding(padding: const EdgeInsets.all(10), child: Text('${g['no']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.gray700))),
                  Padding(padding: const EdgeInsets.all(10), child: Text(g['subject'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.foreground))),
                  Padding(padding: const EdgeInsets.all(10), child: Text('${g['kkm']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.gray700))),
                  Padding(padding: const EdgeInsets.all(10), child: Text('${g['nilai']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  Padding(padding: const EdgeInsets.all(10), child: Text(g['predikat'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray700))),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rata-rata ${title.split(' ').take(2).join(' ')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              Text(_calcAverage(grades).toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kpiBox(IconData icon, Color iconBg, Color bgColor, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
