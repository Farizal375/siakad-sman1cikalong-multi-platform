// File: lib/features/guru/screens/student_deep_dive.dart
// ===========================================
// STUDENT DEEP DIVE – Wali Kelas
// Translated from StudentDeepDive.tsx
// Profil siswa + Tab transkrip 2 semester + catatan
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/success_toast.dart';
import '../utils/report_card_pdf_generator.dart';

class StudentDeepDive extends StatefulWidget {
  final String? studentId;
  const StudentDeepDive({super.key, this.studentId});

  @override
  State<StudentDeepDive> createState() => _StudentDeepDiveState();
}

class _StudentDeepDiveState extends State<StudentDeepDive> {
  String _activeTab = 'transcript'; // 'transcript' | 'chart'
  bool _showToast = false;
  String _toastMsg = '';

  // ── All student data keyed by ID ──
  static final Map<String, Map<String, dynamic>> _allStudents = {
    '1': {
      'id': 1,
      'name': 'Ahmad Fauzi',
      'nisn': '0012345671',
      'kelas': 'XI-1',
      'avgTotal': '87.2',
      'rank': '2 dari 36',
      'attendance': '98%',
      'catatan':
          'Ahmad menunjukkan perkembangan yang sangat baik dalam semester ini. Sikapnya sopan dan penuh tanggung jawab. Aktif dalam kegiatan organisasi OSIS dan selalu tepat waktu mengumpulkan tugas. Perlu ditingkatkan kemampuan presentasi di depan kelas.',
      'ganjil': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 84, 'predikat': 'Sangat Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 90, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 96, 'predikat': 'Sangat Baik'},
      ],
      'genap': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 85, 'predikat': 'Sangat Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 78, 'predikat': 'Baik'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 92, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 90, 'predikat': 'Sangat Baik'},
      ],
    },
    '2': {
      'id': 2,
      'name': 'Siti Rahmawati',
      'nisn': '0012345672',
      'kelas': 'XI-1',
      'avgTotal': '85.8',
      'rank': '4 dari 36',
      'attendance': '96%',
      'catatan':
          'Siti menunjukkan konsistensi yang baik dalam belajar. Aktif bertanya di kelas dan sering membantu teman yang kesulitan. Perlu terus dijaga motivasi belajarnya.',
      'ganjil': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 78, 'predikat': 'Baik'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 92, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 94, 'predikat': 'Sangat Baik'},
      ],
      'genap': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 84, 'predikat': 'Sangat Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 90, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 92, 'predikat': 'Sangat Baik'},
      ],
    },
    '3': {
      'id': 3,
      'name': 'Budi Santoso',
      'nisn': '0012345673',
      'kelas': 'XI-1',
      'avgTotal': '76.3',
      'rank': '18 dari 36',
      'attendance': '62%',
      'catatan':
          'Budi perlu lebih fokus dalam belajar. Kehadiran masih di bawah standar, sering terlambat datang ke kelas. Perlu bimbingan dan perhatian khusus dari orang tua.',
      'ganjil': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 75, 'predikat': 'Cukup'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 72, 'predikat': 'Cukup'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 76, 'predikat': 'Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 70, 'predikat': 'Cukup'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 78, 'predikat': 'Baik'},
      ],
      'genap': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 77, 'predikat': 'Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 74, 'predikat': 'Cukup'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 78, 'predikat': 'Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 72, 'predikat': 'Cukup'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
      ],
    },
    '4': {
      'id': 4,
      'name': 'Dewi Lestari',
      'nisn': '0012345674',
      'kelas': 'XI-1',
      'avgTotal': '88.5',
      'rank': '1 dari 36',
      'attendance': '58%',
      'catatan':
          'Dewi memiliki kemampuan akademik yang sangat baik. Nilainya konsisten tinggi di semua mata pelajaran. Namun kehadiran perlu diperbaiki, sering izin tanpa alasan jelas.',
      'ganjil': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 90, 'predikat': 'Sangat Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 92, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 90, 'predikat': 'Sangat Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
      ],
      'genap': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 94, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 92, 'predikat': 'Sangat Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 84, 'predikat': 'Sangat Baik'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
      ],
    },
    '5': {
      'id': 5,
      'name': 'Andi Wijaya',
      'nisn': '0012345675',
      'kelas': 'XI-1',
      'avgTotal': '83.0',
      'rank': '8 dari 36',
      'attendance': '65%',
      'catatan':
          'Andi cukup aktif dalam kegiatan ekstra namun perlu menyeimbangkan dengan kegiatan akademik. Kehadiran perlu ditingkatkan secara signifikan.',
      'ganjil': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 84, 'predikat': 'Sangat Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 78, 'predikat': 'Baik'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
      ],
      'genap': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
      ],
    },
    '6': {
      'id': 6,
      'name': 'Maya Sari',
      'nisn': '0012345676',
      'kelas': 'XI-1',
      'avgTotal': '84.7',
      'rank': '6 dari 36',
      'attendance': '95%',
      'catatan':
          'Maya siswa yang tekun dan rajin. Selalu mengerjakan tugas tepat waktu dan aktif dalam diskusi kelas. Perlu ditingkatkan keberanian dalam menyampaikan pendapat.',
      'ganjil': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 80, 'predikat': 'Baik'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 84, 'predikat': 'Sangat Baik'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 90, 'predikat': 'Sangat Baik'},
      ],
      'genap': [
        {'no': 1, 'subject': 'Matematika', 'kkm': 75, 'nilai': 84, 'predikat': 'Sangat Baik'},
        {'no': 2, 'subject': 'Fisika', 'kkm': 75, 'nilai': 78, 'predikat': 'Baik'},
        {'no': 3, 'subject': 'Bahasa Indonesia', 'kkm': 75, 'nilai': 86, 'predikat': 'Sangat Baik'},
        {'no': 4, 'subject': 'Bahasa Inggris', 'kkm': 75, 'nilai': 84, 'predikat': 'Sangat Baik'},
        {'no': 5, 'subject': 'Kimia', 'kkm': 75, 'nilai': 82, 'predikat': 'Sangat Baik'},
        {'no': 6, 'subject': 'Biologi', 'kkm': 75, 'nilai': 88, 'predikat': 'Sangat Baik'},
      ],
    },
  };

  Map<String, dynamic> get _student {
    return _allStudents[widget.studentId] ?? _allStudents['1']!;
  }

  List<Map<String, dynamic>> get _semesterGanjil =>
      (_student['ganjil'] as List).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _semesterGenap =>
      (_student['genap'] as List).cast<Map<String, dynamic>>();

  double _calcAverage(List<Map<String, dynamic>> grades) {
    final sum = grades.fold<int>(0, (acc, g) => acc + (g['nilai'] as int));
    return sum / grades.length;
  }

  // ── Show semester picker dialog & print ──
  void _showPrintSemesterDialog() {
    String selectedSemester = 'Semester Ganjil 2026/2027';
    bool digitalSignature = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 480,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(blurRadius: 32, color: Colors.black26)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF3B82F6)]),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.print, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cetak Rapor Siswa',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _student['name'] as String,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // ── Body ──
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Student Info Mini Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, Color(0xFF3B82F6)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _student['name'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.foreground, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'NISN: ${_student['nisn']} • Kelas ${_student['kelas']}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Semester Picker
                          const Text(
                            'Pilih Semester',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedSemester,
                            items: [
                              'Semester Ganjil 2025/2026',
                              'Semester Genap 2025/2026',
                              'Semester Ganjil 2026/2027',
                              'Semester Genap 2026/2027',
                            ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
                            onChanged: (v) => setDialogState(() => selectedSemester = v!),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.gray50,
                              prefixIcon: const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.gray200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.gray200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Digital Signature Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sertakan Tanda Tangan Digital',
                                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground, fontSize: 14)),
                                    SizedBox(height: 4),
                                    Text('Tambahkan TTD Kepala Sekolah & Wali Kelas',
                                        style: TextStyle(fontSize: 12, color: AppColors.gray600)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: digitalSignature,
                                onChanged: (v) => setDialogState(() => digitalSignature = v),
                                activeThumbColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Footer ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.gray700,
                              side: const BorderSide(color: AppColors.gray300, width: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              setState(() {
                                _toastMsg = 'Mencetak e-Rapor ${_student['name']}...';
                                _showToast = true;
                              });

                              final pdfBytes = await ReportCardPdfGenerator.generateBulkReportCards(
                                students: [_student],
                                semester: selectedSemester,
                                digitalSignature: digitalSignature,
                              );
                              await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
                            },
                            icon: const Icon(Icons.print, size: 18),
                            label: const Text('Cetak Rapor (PDF)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;
    final name = student['name'] as String;
    final nisn = student['nisn'] as String;
    final kelas = student['kelas'] as String;
    final avgTotal = student['avgTotal'] as String;
    final rank = student['rank'] as String;
    final attendance = student['attendance'] as String;
    final catatan = student['catatan'] as String;

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
                    onPressed: _showPrintSemesterDialog,
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
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
                      child: Center(
                        child: Text(
                          name.split(' ').map((e) => e[0]).take(2).join(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('NISN: $nisn', style: const TextStyle(color: AppColors.gray600)),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: AppColors.gray400)),
                              const SizedBox(width: 8),
                              Text('Kelas $kelas', style: const TextStyle(color: AppColors.gray600)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _kpiBox(Icons.emoji_events, const Color(0xFF3B82F6), const Color(0xFFEFF6FF), 'Rata-rata Keseluruhan', avgTotal),
                              const SizedBox(width: 12),
                              _kpiBox(Icons.trending_up, const Color(0xFF10B981), const Color(0xFFECFDF5), 'Peringkat', rank),
                              const SizedBox(width: 12),
                              _kpiBox(Icons.calendar_today, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF), 'Kehadiran', attendance),
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
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
                      child: Text(
                        catatan,
                        style: const TextStyle(color: AppColors.foreground, height: 1.6),
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
              message: _toastMsg,
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
