// File: lib/features/guru/screens/my_classes.dart
// ===========================================
// MY CLASSES – Daftar Kelas Guru
// Connected to /jadwal/by-guru API
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

class MyClasses extends StatefulWidget {
  const MyClasses({super.key});

  @override
  State<MyClasses> createState() => _MyClassesState();
}

class _MyClassesState extends State<MyClasses> {
  bool _loading = true;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final response = await ApiService.getGuruDashboard();
      final data = response['data'] ?? {};
      final jadwalList = data['jadwalHariIni'] as List? ?? [];
      final mapelList = data['mapelDiampu'] as List? ?? [];

      // Group jadwal by class+subject to build class cards
      final Map<String, Map<String, dynamic>> classMap = {};
      for (final j in jadwalList) {
        final key = '${j['subject']}-${j['className']}';
        if (!classMap.containsKey(key)) {
          classMap[key] = {
            'id': j['id'] ?? key,
            'subject': j['subject'] ?? '-',
            'class': j['className'] ?? '-',
            'schedule': '${j['startTime'] ?? ''} - ${j['endTime'] ?? ''}',
            'color': AppColors.primary,
          };
        }
      }

      // Also add from mapelDiampu
      for (final m in mapelList) {
        final subject = m['subject'] ?? '-';
        final classes = m['classes'] ?? 0;
        final key = '$subject-all';
        if (!classMap.containsKey(key) && classes > 0) {
          classMap[key] = {
            'id': m['id'] ?? key,
            'subject': subject,
            'class': '$classes kelas',
            'schedule': '${m['hoursPerWeek'] ?? 0} jam/minggu',
            'color': const Color(0xFF7C3AED),
          };
        }
      }

      if (mounted) {
        setState(() {
          _classes = classMap.values.toList();
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

        if (_classes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 64),
            alignment: Alignment.center,
            child: const Column(
              children: [
                Icon(Icons.class_outlined, size: 64, color: AppColors.gray400),
                SizedBox(height: 16),
                Text('Belum ada kelas yang ditugaskan', style: TextStyle(color: AppColors.gray500, fontSize: 16)),
              ],
            ),
          )
        else
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
            itemCount: _classes.length,
            itemBuilder: (context, i) {
              final c = _classes[i];
              return _ClassCard(
                id: c['id'] as String,
                subject: c['subject'] as String,
                className: c['class'] as String,
                students: 0,
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
