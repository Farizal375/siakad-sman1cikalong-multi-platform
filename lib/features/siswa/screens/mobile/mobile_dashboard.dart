// File: lib/features/siswa/screens/mobile/mobile_dashboard.dart
// ===========================================
// MOBILE STUDENT DASHBOARD (FR-06.1)
// Design: Circle attendance + today schedule + school news carousel
// Connected to /dashboard/siswa API
// ===========================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/student_providers.dart';

class MobileDashboard extends ConsumerStatefulWidget {
  const MobileDashboard({super.key});

  @override
  ConsumerState<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends ConsumerState<MobileDashboard> {
  final PageController _newsPageCtrl = PageController();
  int _currentNewsPage = 0;

  @override
  void dispose() {
    _newsPageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(studentDashboardProvider);

    return dashboardAsync.when(
      loading: () => _buildSkeleton(context),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.gray300),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data',
              style: TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(studentDashboardProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () => ref.read(studentDashboardProvider.notifier).refresh(),
        color: AppColors.primary,
        child: _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final todaySchedule = (data['jadwalHariIni'] as List?) ?? [];
    final announcements = (data['pengumuman'] as List?) ?? [];
    final kehadiran = data['kehadiran'] as Map<String, dynamic>? ?? {};

    final totalHadir = kehadiran['hadir'] ?? 0;
    final totalSakit = kehadiran['sakit'] ?? 0;
    final totalIzin = kehadiran['izin'] ?? 0;
    final totalAlpa = kehadiran['alpa'] ?? 0;
    final total = totalHadir + totalSakit + totalIzin + totalAlpa;
    final rate = total > 0 ? ((totalHadir / total) * 100).round() : 0;
    final periode = kehadiran['periode'] as Map<String, dynamic>?;
    final periodeLabel = periode?['label'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // ── Presensi Bulan Ini ──
        _buildAttendanceCard(
          context,
          rate,
          totalHadir,
          totalSakit,
          totalIzin,
          totalAlpa,
          total,
          periodeLabel,
          isDark,
        ),
        const SizedBox(height: 20),

        // ── Jadwal Hari Ini ──
        _buildScheduleSection(context, todaySchedule, isDark),
        const SizedBox(height: 24),

        // ── Berita Sekolah ──
        _buildNewsSection(context, announcements, isDark),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // ATTENDANCE CIRCLE CARD
  // ═══════════════════════════════════════════
  Widget _buildAttendanceCard(
    BuildContext context,
    int rate,
    int hadir,
    int sakit,
    int izin,
    int alpa,
    int total,
    String periodeLabel,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Presensi Bulan Ini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.foreground,
            ),
          ),
          if (periodeLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              periodeLabel,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Circle progress
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _AttendanceCirclePainter(
                percentage: rate / 100,
                trackColor: isDark
                    ? AppColors.gray700
                    : const Color(0xFFE8F5E9),
                progressColor: const Color(0xFF4CAF50),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$rate%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.foreground,
                      ),
                    ),
                    Text(
                      'Hadir',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (total == 0) ...[
            Text(
              'Belum ada data presensi bulan ini',
              style: TextStyle(fontSize: 12, color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          // Bottom stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statChip('Hadir', hadir, const Color(0xFF16A34A)),
              _statChip('Sakit', sakit, AppColors.gray500),
              _statChip('Izin', izin, AppColors.primary),
              _statChip('Alpa', alpa, const Color(0xFFEF5350)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.gray500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // JADWAL HARI INI
  // ═══════════════════════════════════════════
  Widget _buildScheduleSection(
    BuildContext context,
    List todaySchedule,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Jadwal Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/siswa/jadwal'),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (todaySchedule.isEmpty)
            _buildEmptySchedule(context)
          else
            ...todaySchedule.asMap().entries.map(
              (e) => _buildScheduleItem(
                context,
                e.value as Map<String, dynamic>,
                e.key == 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    Map<String, dynamic> schedule,
    bool isFirst,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    final subject = schedule['subject'] ?? '-';
    final startTime = schedule['startTime'] ?? '';
    final teacher = schedule['teacher'] ?? '-';
    final room = schedule['room'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time badge
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.gray700 : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  startTime,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'WIB',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.gray400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Info card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.gray700.withValues(alpha: 0.5)
                    : AppColors.gray50,
                borderRadius: BorderRadius.circular(14),
                border: isFirst
                    ? Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: fgColor,
                          ),
                        ),
                      ),
                      if (isFirst)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Sedang Berlangsung',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Akan Datang',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 13,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          teacher,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        room,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 40, color: AppColors.gray300),
            const SizedBox(height: 8),
            Text(
              'Tidak ada jadwal hari ini',
              style: TextStyle(color: AppColors.gray500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // BERITA SEKOLAH — Carousel
  // ═══════════════════════════════════════════
  Widget _buildNewsSection(
    BuildContext context,
    List announcements,
    bool isDark,
  ) {
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Berita Sekolah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
            const Spacer(),
            if (announcements.length > 1) ...[
              GestureDetector(
                onTap: () {
                  if (_currentNewsPage > 0) {
                    _newsPageCtrl.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Icon(
                  Icons.chevron_left,
                  size: 24,
                  color: _currentNewsPage > 0 ? fgColor : AppColors.gray300,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  if (_currentNewsPage < announcements.length - 1) {
                    _newsPageCtrl.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: _currentNewsPage < announcements.length - 1
                      ? fgColor
                      : AppColors.gray300,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (announcements.isEmpty)
          _buildEmptyNews(context)
        else
          SizedBox(
            height: 260,
            child: PageView.builder(
              controller: _newsPageCtrl,
              itemCount: announcements.length,
              onPageChanged: (i) => setState(() => _currentNewsPage = i),
              itemBuilder: (context, i) => _buildNewsCard(
                context,
                announcements[i] as Map<String, dynamic>,
                isDark,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNewsCard(
    BuildContext context,
    Map<String, dynamic> news,
    bool isDark,
  ) {
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;

    final title = news['title'] ?? news['judul'] ?? '-';
    final content = news['content'] ?? news['konten'] ?? '';
    final createdAt = news['createdAt'] ?? news['created_at'] ?? '';

    String dateStr = '';
    try {
      final dt = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        dateStr = 'Hari ini';
      } else if (diff.inDays == 1) {
        dateStr = 'Kemarin';
      } else {
        dateStr = '${diff.inDays} hari yang lalu';
      }
    } catch (_) {
      dateStr = createdAt.toString();
    }

    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.accent.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Icon(
                    Icons.article_outlined,
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BERITA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 11, color: AppColors.gray400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNews(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 40,
            color: AppColors.gray300,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada berita sekolah',
            style: TextStyle(color: AppColors.gray500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SKELETON LOADING
  // ═══════════════════════════════════════════
  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? const Color(0xFF1F2937) : AppColors.gray100;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// CUSTOM PAINTER — Attendance Circle
// ═══════════════════════════════════════════
class _AttendanceCirclePainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color progressColor;

  _AttendanceCirclePainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
