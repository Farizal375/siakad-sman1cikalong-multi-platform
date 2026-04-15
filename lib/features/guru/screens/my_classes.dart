// File: lib/features/guru/screens/my_classes.dart
// ===========================================
// MY CLASSES – Daftar Kelas Guru
// Translated from MyClasses.tsx
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class MyClasses extends StatelessWidget {
  const MyClasses({super.key});

  @override
  Widget build(BuildContext context) {
    final classes = [
      {'id': 'mat-xi-1', 'subject': 'Matematika', 'class': 'Kelas XI-1', 'students': 36, 'schedule': 'Senin & Rabu', 'color': AppColors.primary},
      {'id': 'mat-xi-2', 'subject': 'Matematika', 'class': 'Kelas XI-2', 'students': 34, 'schedule': 'Selasa & Kamis', 'color': AppColors.primary},
      {'id': 'mat-xi-3', 'subject': 'Matematika', 'class': 'Kelas XI-3', 'students': 35, 'schedule': 'Rabu & Jumat', 'color': AppColors.primary},
      {'id': 'fis-x-1', 'subject': 'Fisika', 'class': 'Kelas X-1', 'students': 32, 'schedule': 'Senin & Kamis', 'color': const Color(0xFF7C3AED)},
      {'id': 'fis-x-2', 'subject': 'Fisika', 'class': 'Kelas X-2', 'students': 33, 'schedule': 'Selasa & Jumat', 'color': const Color(0xFF7C3AED)},
      {'id': 'mat-x-1', 'subject': 'Matematika', 'class': 'Kelas X-1', 'students': 31, 'schedule': 'Rabu & Kamis', 'color': AppColors.primary},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
          'Daftar Kelas Anda',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pilih kelas untuk mengelola jurnal, memulai sesi absensi, dan melihat rekapitulasi.',
          style: TextStyle(fontSize: 16, color: AppColors.foreground),
        ),
        const SizedBox(height: 24),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 380,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 220,
          ),
          itemCount: classes.length,
          itemBuilder: (context, i) {
            final c = classes[i];
            return _ClassCard(
              id: c['id'] as String,
              subject: c['subject'] as String,
              className: c['class'] as String,
              students: c['students'] as int,
              schedule: c['schedule'] as String,
              accentColor: c['color'] as Color,
              onTap: () => context.go('/guru/kelas/${c['id']}'),
            );
          },
        ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatefulWidget {
  final String id, subject, className, schedule;
  final int students;
  final Color accentColor;
  final VoidCallback onTap;

  const _ClassCard({
    required this.id,
    required this.subject,
    required this.className,
    required this.students,
    required this.schedule,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.12 : 0.07),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color Banner
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subject,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: widget.accentColor),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.className, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray600)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text('${widget.students} Siswa', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined, size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text('Jadwal: ${widget.schedule}', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: const Color(0xFFF3F4F6),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Masuk Ruang Kelas',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _hovered ? AppColors.accent : widget.accentColor,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: _hovered ? AppColors.accent : widget.accentColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
