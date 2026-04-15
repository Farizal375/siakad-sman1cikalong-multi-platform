// File: lib/features/guru/screens/catatan_akademik.dart
// ===========================================
// CATATAN AKADEMIK – Wali Kelas
// Translated from CatatanAkademik.tsx
// Form evaluasi karakter siswa per semester
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/success_toast.dart';

class CatatanAkademik extends StatefulWidget {
  const CatatanAkademik({super.key});

  @override
  State<CatatanAkademik> createState() => _CatatanAkademikState();
}

class _CatatanAkademikState extends State<CatatanAkademik> {
  bool _showToast = false;
  static const int _maxChar = 500;

  final List<Map<String, dynamic>> _students = [
    {'id': 1, 'nisn': '0012345671', 'name': 'Ahmad Fauzi', 'note': '', 'count': 0},
    {'id': 2, 'nisn': '0012345672', 'name': 'Siti Rahmawati', 'note': '', 'count': 0},
    {'id': 3, 'nisn': '0012345673', 'name': 'Budi Santoso', 'note': '', 'count': 0},
    {'id': 4, 'nisn': '0012345674', 'name': 'Dewi Lestari', 'note': '', 'count': 0},
    {'id': 5, 'nisn': '0012345675', 'name': 'Andi Wijaya', 'note': '', 'count': 0},
    {'id': 6, 'nisn': '0012345676', 'name': 'Maya Sari', 'note': '', 'count': 0},
  ];

  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _students.map((_) => TextEditingController()).toList();
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        setState(() {
          _students[i]['note'] = _controllers[i].text;
          _students[i]['count'] = _controllers[i].text.length;
        });
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  int get _filledCount => _students.where((s) => (s['note'] as String).trim().isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text('Catatan Akademik XI-1', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.foreground)),
              const SizedBox(height: 8),
              const Text('Input evaluasi karakter dan perkembangan siswa selama semester', style: TextStyle(color: AppColors.gray600)),
              const SizedBox(height: 24),

              // Control Card
              Container(
                padding: const EdgeInsets.all(24),
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
                          const Text('Evaluasi Karakter Siswa Semester Ganjil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                          const SizedBox(height: 4),
                          Text('$_filledCount dari ${_students.length} siswa telah diisi', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showToast = true),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Simpan Semua Catatan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Student Cards
              ..._students.asMap().entries.map((e) {
                final idx = e.key;
                final s = e.value;
                final filled = (s['note'] as String).trim().isNotEmpty;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Info
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                                colors: [AppColors.primary, Color(0xFF3B82F6)],
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                                Text('NISN: ${s['nisn']}', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: filled ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              filled ? 'Terisi' : 'Belum Diisi',
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: filled ? const Color(0xFF15803D) : AppColors.gray600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Textarea
                      Stack(
                        children: [
                          TextField(
                            controller: _controllers[idx],
                            maxLines: 4,
                            maxLength: _maxChar,
                            buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
                            decoration: InputDecoration(
                              hintText: 'Tuliskan perkembangan karakter, sikap, dan saran untuk siswa ini selama satu semester...',
                              hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
                              filled: true, fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200, width: 2)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200, width: 2)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            ),
                          ),
                          Positioned(
                            bottom: 10, right: 12,
                            child: Text(
                              '${s['count']}/$_maxChar karakter',
                              style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),

        if (_showToast)
          Positioned(
            top: 16, right: 16,
            child: SuccessToast(
              isVisible: true,
              message: 'Berhasil menyimpan $_filledCount catatan dari ${_students.length} siswa',
              onClose: () => setState(() => _showToast = false),
            ),
          ),
      ],
    );
  }
}
