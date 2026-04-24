// File: lib/features/siswa/screens/mobile/mobile_dashboard.dart
// ===========================================
// MOBILE STUDENT DASHBOARD (FR-06.1)
// Greeting + today's schedule + attendance stats + announcements
// Connected to /dashboard/siswa API
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/student_providers.dart';

class MobileDashboard extends ConsumerStatefulWidget {
  const MobileDashboard({super.key});

  @override
  ConsumerState<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends ConsumerState<MobileDashboard> {
  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(studentDashboardProvider);
    final studentName = ref.watch(studentNameProvider);
    final initials = ref.watch(studentInitialsProvider);

    return dashboardAsync.when(
      loading: () => _buildSkeleton(),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.gray300),
            const SizedBox(height: 16),
            const Text('Gagal memuat data', style: TextStyle(color: AppColors.gray600)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(studentDashboardProvider.notifier).refresh(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () => ref.read(studentDashboardProvider.notifier).refresh(),
        color: AppColors.primary,
        child: _buildContent(context, data, studentName, initials),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> data,
    String studentName,
    String initials,
  ) {
    final kelas = data['kelas'] ?? '-';
    final hari = data['hari'] ?? '-';
    final todaySchedule = (data['jadwalHariIni'] as List?) ?? [];
    final announcements = (data['pengumuman'] as List?) ?? [];
    final kehadiran = data['kehadiran'] as Map<String, dynamic>? ?? {};

    final totalHadir = kehadiran['hadir'] ?? 0;
    final totalSakit = kehadiran['sakit'] ?? 0;
    final totalIzin = kehadiran['izin'] ?? 0;
    final totalAlpa = kehadiran['alpa'] ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // ── Greeting Header ──
        _buildGreeting(context, studentName, initials, kelas),
        const SizedBox(height: 20),

        // ── Attendance Summary ──
        _buildAttendanceStats(context, totalHadir, totalSakit, totalIzin, totalAlpa),
        const SizedBox(height: 24),

        // ── Today's Schedule ──
        _buildSectionHeader(context, 'Jadwal Hari Ini', hari, Icons.calendar_today),
        const SizedBox(height: 12),
        if (todaySchedule.isEmpty)
          _buildEmptyState('Tidak ada jadwal hari ini', Icons.event_busy_outlined)
        else
          ...todaySchedule.asMap().entries.map((e) =>
              _buildScheduleCard(context, e.value as Map<String, dynamic>, e.key == 0)),
        const SizedBox(height: 24),

        // ── Announcements ──
        _buildSectionHeader(context, 'Pengumuman', '${announcements.length} berita', Icons.campaign_outlined),
        const SizedBox(height: 12),
        if (announcements.isEmpty)
          _buildEmptyState('Belum ada pengumuman', Icons.notifications_off_outlined)
        else
          ...announcements.map((a) => _buildAnnouncementCard(context, a as Map<String, dynamic>)),
      ],
    );
  }

  // ── Greeting Card ──
  Widget _buildGreeting(BuildContext context, String name, String initials, String kelas) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentHover],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Kelas $kelas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Attendance Stats ──
  Widget _buildAttendanceStats(BuildContext context, int hadir, int sakit, int izin, int alpa) {
    final total = hadir + sakit + izin + alpa;
    final rate = total > 0 ? ((hadir / total) * 100).round() : 100;

    return Row(
      children: [
        _statCard(context, 'Kehadiran', '$rate%', AppColors.primary, AppColors.blue50, Icons.verified),
        const SizedBox(width: 10),
        _statCard(context, 'Hadir', '$hadir', const Color(0xFF16A34A), AppColors.green50, Icons.check_circle_outline),
        const SizedBox(width: 10),
        _statCard(context, 'Alpa', '$alpa', const Color(0xFFDC2626), AppColors.red50, Icons.cancel_outlined),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value, Color color, Color bg, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ──
  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: fgColor,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Schedule Card ──
  Widget _buildScheduleCard(BuildContext context, Map<String, dynamic> schedule, bool isFirst) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    
    final subject = schedule['subject'] ?? '-';
    final startTime = schedule['startTime'] ?? '';
    final endTime = schedule['endTime'] ?? '';
    final teacher = schedule['teacher'] ?? '-';
    final room = schedule['room'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isFirst
            ? Border.all(color: AppColors.accent, width: 2)
            : Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: isFirst ? AppColors.accent : AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.amber50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.amber200),
                            ),
                            child: const Text(
                              'Berlangsung',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentHover,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _scheduleDetail(Icons.access_time, '$startTime – $endTime'),
                        const SizedBox(width: 16),
                        _scheduleDetail(Icons.location_on_outlined, room),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _scheduleDetail(Icons.person_outline, teacher),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.gray400),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: AppColors.gray600),
        ),
      ],
    );
  }

  // ── Announcement Card ──
  Widget _buildAnnouncementCard(BuildContext context, Map<String, dynamic> announcement) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    
    final title = announcement['title'] ?? '-';
    final content = announcement['content'] ?? '';
    final createdAt = announcement['createdAt'] ?? '';

    String dateStr = '';
    try {
      final dt = DateTime.parse(createdAt);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      dateStr = createdAt.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.article_outlined, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 2),
                    Text(dateStr, style: TextStyle(fontSize: 11, color: AppColors.gray400)),
                  ],
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.gray300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: AppColors.gray500, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Skeleton Loading ──
  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Greeting skeleton
        Container(
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 20),
        // Stats skeleton
        Row(
          children: List.generate(3, (index) => Expanded(
            child: Container(
              height: 90,
              margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          )),
        ),
        const SizedBox(height: 24),
        // Schedule skeleton
        ...List.generate(3, (_) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(16),
          ),
        )),
      ],
    );
  }
}
