// File: lib/features/siswa/screens/riwayat_kehadiran.dart
// ===========================================
// RIWAYAT KEHADIRAN & JURNAL – Siswa
// Migrated from RiwayatKehadiran.tsx
// Pertemuan-based cards + dropdown filter + summary card
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class _Meeting {
  final int pertemuan;
  final String tanggal;
  final String status; // HADIR | SAKIT | IZIN | ALPA
  final String topik;
  final String deskripsi;
  final bool hasAttachment;
  final String mataPelajaran;

  const _Meeting({
    required this.pertemuan,
    required this.tanggal,
    required this.status,
    required this.topik,
    required this.deskripsi,
    required this.mataPelajaran,
    this.hasAttachment = false,
  });
}

class RiwayatKehadiran extends StatefulWidget {
  const RiwayatKehadiran({super.key});

  @override
  State<RiwayatKehadiran> createState() => _RiwayatKehadiranState();
}

class _RiwayatKehadiranState extends State<RiwayatKehadiran> {
  String _selectedSubject = 'Matematika';

  static const _subjects = [
    'Matematika',
    'Fisika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Kimia',
    'Biologi',
  ];

  static const _allMeetings = <_Meeting>[
    _Meeting(
      pertemuan: 8,
      tanggal: '10 April 2026',
      status: 'HADIR',
      mataPelajaran: 'Matematika',
      topik: 'Integral Tentu dan Tak Tentu',
      deskripsi:
          'Pembahasan konsep integral, contoh soal integral tentu dan tak tentu, serta aplikasi integral dalam kehidupan sehari-hari.',
      hasAttachment: true,
    ),
    _Meeting(
      pertemuan: 7,
      tanggal: '8 April 2026',
      status: 'HADIR',
      mataPelajaran: 'Matematika',
      topik: 'Turunan Fungsi Trigonometri',
      deskripsi:
          'Pengenalan turunan fungsi trigonometri, rumus-rumus dasar, dan latihan soal halaman 45-50.',
      hasAttachment: false,
    ),
    _Meeting(
      pertemuan: 6,
      tanggal: '5 April 2026',
      status: 'SAKIT',
      mataPelajaran: 'Matematika',
      topik: 'Rumus Identitas Trigonometri',
      deskripsi:
          'Pembahasan soal latihan halaman 45-50 dan pengumpulan tugas kelompok tentang identitas trigonometri.',
      hasAttachment: true,
    ),
    _Meeting(
      pertemuan: 5,
      tanggal: '3 April 2026',
      status: 'HADIR',
      mataPelajaran: 'Matematika',
      topik: 'Limit Fungsi Aljabar',
      deskripsi:
          'Penjelasan konsep limit, teknik menghitung limit fungsi aljabar, dan pengerjaan soal-soal limit.',
      hasAttachment: false,
    ),
    _Meeting(
      pertemuan: 4,
      tanggal: '1 April 2026',
      status: 'HADIR',
      mataPelajaran: 'Matematika',
      topik: 'Fungsi Komposisi dan Invers',
      deskripsi:
          'Pembahasan fungsi komposisi, sifat-sifat fungsi invers, dan contoh aplikasi dalam soal.',
      hasAttachment: true,
    ),
    _Meeting(
      pertemuan: 3,
      tanggal: '29 Maret 2026',
      status: 'IZIN',
      mataPelajaran: 'Matematika',
      topik: 'Sistem Persamaan Linear',
      deskripsi:
          'Metode eliminasi, substitusi, dan determinan untuk menyelesaikan sistem persamaan linear tiga variabel.',
      hasAttachment: false,
    ),
    // Fisika
    _Meeting(
      pertemuan: 6,
      tanggal: '10 April 2026',
      status: 'HADIR',
      mataPelajaran: 'Fisika',
      topik: 'Gelombang Mekanik',
      deskripsi:
          'Memahami karakteristik gelombang mekanik dan persamaan gelombang berjalan.',
      hasAttachment: true,
    ),
    _Meeting(
      pertemuan: 5,
      tanggal: '7 April 2026',
      status: 'ALPA',
      mataPelajaran: 'Fisika',
      topik: 'Bunyi dan Intensitas',
      deskripsi: 'Menganalisis intensitas bunyi dan faktor-faktor yang mempengaruhinya.',
      hasAttachment: false,
    ),
    _Meeting(
      pertemuan: 4,
      tanggal: '3 April 2026',
      status: 'HADIR',
      mataPelajaran: 'Fisika',
      topik: 'Hukum Newton',
      deskripsi: 'Penerapan hukum Newton pada gerak benda di berbagai kondisi.',
      hasAttachment: true,
    ),
    // Bahasa Indonesia
    _Meeting(
      pertemuan: 5,
      tanggal: '9 April 2026',
      status: 'IZIN',
      mataPelajaran: 'Bahasa Indonesia',
      topik: 'Teks Argumentasi',
      deskripsi: 'Menganalisis struktur dan kaidah kebahasaan teks argumentasi.',
      hasAttachment: false,
    ),
    _Meeting(
      pertemuan: 4,
      tanggal: '5 April 2026',
      status: 'HADIR',
      mataPelajaran: 'Bahasa Indonesia',
      topik: 'Teks Eksplanasi',
      deskripsi: 'Memahami struktur teks eksplanasi dan cara penulisannya.',
      hasAttachment: true,
    ),
    // Kimia
    _Meeting(
      pertemuan: 5,
      tanggal: '8 April 2026',
      status: 'HADIR',
      mataPelajaran: 'Kimia',
      topik: 'Reaksi Redoks',
      deskripsi:
          'Mengidentifikasi reaksi oksidasi dan reduksi dalam kehidupan sehari-hari.',
      hasAttachment: false,
    ),
    _Meeting(
      pertemuan: 4,
      tanggal: '4 April 2026',
      status: 'SAKIT',
      mataPelajaran: 'Kimia',
      topik: 'Larutan Elektrolit',
      deskripsi:
          'Klasifikasi larutan berdasarkan daya hantar listrik dan uji larutan elektrolit.',
      hasAttachment: true,
    ),
  ];

  // ── Status styling ────────────────────────────────────────────────────────
  ({Color bg, Color text, Color border, IconData icon}) _statusStyle(String status) {
    switch (status) {
      case 'HADIR':
        return (
          bg: const Color(0xFFDCFCE7),
          text: const Color(0xFF15803D),
          border: const Color(0xFF86EFAC),
          icon: Icons.check_circle_outline,
        );
      case 'SAKIT':
        return (
          bg: const Color(0xFFFEF3C7),
          text: const Color(0xFFB45309),
          border: const Color(0xFFFDE68A),
          icon: Icons.cancel_outlined,
        );
      case 'IZIN':
        return (
          bg: const Color(0xFFDBEAFE),
          text: const Color(0xFF1D4ED8),
          border: const Color(0xFFBFDBFE),
          icon: Icons.watch_later_outlined,
        );
      case 'ALPA':
        return (
          bg: const Color(0xFFFEE2E2),
          text: const Color(0xFFB91C1C),
          border: const Color(0xFFFCA5A5),
          icon: Icons.cancel_outlined,
        );
      default:
        return (
          bg: const Color(0xFFF3F4F6),
          text: AppColors.gray600,
          border: const Color(0xFFE5E7EB),
          icon: Icons.help_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allMeetings
        .where((m) => m.mataPelajaran == _selectedSubject)
        .toList()
      ..sort((a, b) => b.pertemuan.compareTo(a.pertemuan));

    final hadir = filtered.where((m) => m.status == 'HADIR').length;
    final sakit = filtered.where((m) => m.status == 'SAKIT').length;
    final izin  = filtered.where((m) => m.status == 'IZIN').length;
    final alpa  = filtered.where((m) => m.status == 'ALPA').length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Header ──────────────────────────────────────────────────
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

          // ── Subject Dropdown ─────────────────────────────────────────────
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
                const Text(
                  'Pilih Mata Pelajaran',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubject,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.foreground),
                  items: _subjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSubject = v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Meeting Cards ─────────────────────────────────────────────────
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

          // ── Summary Card ──────────────────────────────────────────────────
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
                  Text(
                    'Ringkasan Kehadiran – $_selectedSubject',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
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

  // ── Meeting Card ─────────────────────────────────────────────────────────
  Widget _buildMeetingCard(_Meeting meeting) {
    final style = _statusStyle(meeting.status);

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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.80)],
              ),
            ),
            child: Row(
              children: [
                // Pertemuan + Tanggal
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Pertemuan ${meeting.pertemuan}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 1,
                        height: 16,
                        color: Colors.white.withValues(alpha: 0.50),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        meeting.tanggal,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: style.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 14, color: style.text),
                      const SizedBox(width: 5),
                      Text(
                        meeting.status,
                        style: TextStyle(
                          color: style.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─ Body: Journal Section ─
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FileText icon box
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    // Topic + Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Topik: ${meeting.topik}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            meeting.deskripsi,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gray700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ─ Attachment ─
                if (meeting.hasAttachment) ...[
                  const Divider(height: 28, color: Color(0xFFF3F4F6)),
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Materi_Pertemuan_${meeting.pertemuan}.pdf',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Box ───────────────────────────────────────────────────────────
  Widget _summaryBox(String label, int count, Color fg, Color bg, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
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
