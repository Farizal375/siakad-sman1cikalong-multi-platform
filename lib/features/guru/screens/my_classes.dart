// File: lib/features/guru/screens/my_classes.dart
// ===========================================
// MY CLASSES – Daftar Kelas Guru
// Connected to /dashboard/guru → daftarKelas
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
  bool _error = false;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final response = await ApiService.getGuruDashboard();
      final data = response['data'] ?? {};

      // daftarKelas: array dari backend, berisi semua kelas yang diampu
      final rawList = data['daftarKelas'] as List? ?? [];

      // Fallback ke jadwalHariIni + mapelDiampu jika daftarKelas kosong
      // (backend lama / belum diupdate)
      if (rawList.isEmpty) {
        final jadwalList = data['jadwalHariIni'] as List? ?? [];
        final mapelList = data['mapelDiampu'] as List? ?? [];

        final Map<String, Map<String, dynamic>> classMap = {};
        for (final j in jadwalList) {
          final key = '${j['subject']}-${j['className']}';
          if (!classMap.containsKey(key)) {
            classMap[key] = {
              'id': j['id'] ?? key,
              'subject': j['subject'] ?? '-',
              'className': j['class'] ?? j['className'] ?? '-',
              'scheduleSummary':
                  '${j['startTime'] ?? ''} - ${j['endTime'] ?? ''}',
              'studentCount': 0,
              'rombelId': null,
              '_color': AppColors.primary,
            };
          }
        }
        for (final m in mapelList) {
          final subject = m['subject'] ?? '-';
          final classes = (m['classes'] ?? 0) as int;
          final key = '$subject-all';
          if (!classMap.containsKey(key) && classes > 0) {
            classMap[key] = {
              'id': m['id'] ?? key,
              'subject': subject,
              'className': '$classes kelas',
              'scheduleSummary': '${m['hoursPerWeek'] ?? 0} jam/minggu',
              'studentCount': 0,
              'rombelId': null,
              '_color': const Color(0xFF7C3AED),
            };
          }
        }
        if (mounted) {
          setState(() {
            _classes = classMap.values.toList();
            _loading = false;
          });
        }
        return;
      }

      // Map warna bergantian
      const colors = [
        AppColors.primary,
        Color(0xFF7C3AED),
        Color(0xFF0891B2),
        Color(0xFF059669),
        Color(0xFFD97706),
      ];

      final List<Map<String, dynamic>> classList = [];
      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i] as Map<String, dynamic>;
        classList.add({
          'id': item['id'] ?? 'kelas-$i',
          'masterKelasId': item['masterKelasId'],
          'mataPelajaranId': item['mataPelajaranId'],
          'rombelId': item['rombelId'],
          'subject': item['subject'] ?? '-',
          'className': item['className'] ?? '-',
          'scheduleSummary': item['scheduleSummary'] ?? '-',
          'studentCount': (item['studentCount'] ?? 0) as int,
          '_color': colors[i % colors.length],
        });
      }

      if (mounted) {
        setState(() {
          _classes = classList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 56,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data kelas',
              style: TextStyle(color: AppColors.gray500, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadClasses,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Daftar Kelas Anda',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
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
                  Icon(
                    Icons.class_outlined,
                    size: 64,
                    color: AppColors.gray400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada kelas yang ditugaskan',
                    style: TextStyle(color: AppColors.gray500, fontSize: 16),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 380,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 230,
              ),
              itemCount: _classes.length,
              itemBuilder: (context, i) {
                final c = _classes[i];
                return _ClassCard(
                  id: c['id'] as String,
                  subject: c['subject'] as String,
                  className: c['className'] as String,
                  scheduleSummary: c['scheduleSummary'] as String,
                  studentCount: c['studentCount'] as int,
                  accentColor: c['_color'] as Color,
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
  final String id, subject, className, scheduleSummary;
  final int studentCount;
  final Color accentColor;
  final VoidCallback onTap;

  const _ClassCard({
    required this.id,
    required this.subject,
    required this.className,
    required this.scheduleSummary,
    required this.studentCount,
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subject,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: widget.accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.className,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.scheduleSummary,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.studentCount} Siswa',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(height: 1, color: const Color(0xFFF3F4F6)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Masuk Ruang Kelas',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _hovered
                                ? AppColors.accent
                                : widget.accentColor,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: _hovered
                              ? AppColors.accent
                              : widget.accentColor,
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
