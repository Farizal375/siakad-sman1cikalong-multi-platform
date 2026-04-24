// File: lib/features/siswa/screens/mobile/mobile_schedule.dart
// ===========================================
// MOBILE WEEKLY SCHEDULE
// Day tabs + schedule cards per day
// Connected to /jadwal API
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../providers/student_providers.dart';

class MobileSchedule extends ConsumerStatefulWidget {
  const MobileSchedule({super.key});

  @override
  ConsumerState<MobileSchedule> createState() => _MobileScheduleState();
}

class _MobileScheduleState extends ConsumerState<MobileSchedule> {
  static const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  late int _selectedDay;
  bool _loading = true;
  Map<String, List<Map<String, dynamic>>> _scheduleByDay = {};

  @override
  void initState() {
    super.initState();
    // Default to today
    final todayIndex = DateTime.now().weekday - 1; // Monday = 0
    _selectedDay = todayIndex.clamp(0, 4);
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    try {
      // Get kelasId from dashboard
      final dashboard = ref.read(studentDashboardProvider).valueOrNull;
      final kelasId = dashboard?['kelasId'] as String?;

      if (kelasId == null) {
        // Try to get from rombel in dashboard
        setState(() => _loading = false);
        return;
      }

      final response = await ApiService.getJadwal(kelasId: kelasId);
      final List data = response['data'] ?? [];

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final day in _days) {
        grouped[day] = [];
      }
      for (final item in data) {
        final day = item['day'] as String? ?? '';
        if (grouped.containsKey(day)) {
          grouped[day]!.add(item as Map<String, dynamic>);
        }
      }

      // Sort each day by slot
      for (final day in _days) {
        grouped[day]!.sort((a, b) =>
            (a['slotIndex'] as int? ?? 0).compareTo(b['slotIndex'] as int? ?? 0));
      }

      if (mounted) {
        setState(() {
          _scheduleByDay = grouped;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // ── Day Selector Tabs ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(4),
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
          child: Row(
            children: _days.asMap().entries.map((e) {
              final isSelected = _selectedDay == e.key;
              final isToday = (DateTime.now().weekday - 1) == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          e.value.substring(0, 3),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.gray500,
                          ),
                        ),
                        if (isToday && !isSelected) ...[
                          const SizedBox(height: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // ── Schedule Content ──
        Expanded(
          child: _loading
              ? _buildSkeleton(context)
              : _buildDaySchedule(context),
        ),
      ],
    );
  }

  Widget _buildDaySchedule(BuildContext context) {
    final dayName = _days[_selectedDay];
    final schedule = _scheduleByDay[dayName] ?? [];

    if (schedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.weekend_outlined, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              'Tidak ada jadwal di hari $dayName',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nikmati waktu luangmu! 🎉',
              style: TextStyle(fontSize: 13, color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        final item = schedule[index];
        return _buildScheduleCard(context, item, index);
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context, Map<String, dynamic> item, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    
    final subject = item['subject'] ?? '-';
    final startTime = item['startTime'] ?? '';
    final endTime = item['endTime'] ?? '';
    final teacher = item['teacher'] ?? '-';
    final room = item['room'] ?? '-';

    // Alternate accent colors
    final colors = [
      AppColors.primary,
      const Color(0xFF059669),
      const Color(0xFF7C3AED),
      AppColors.accent,
      const Color(0xFFDC2626),
    ];
    final accentColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Time column
                    SizedBox(
                      width: 56,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            startTime,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 12,
                            color: isDark ? AppColors.gray700 : AppColors.gray200,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                          ),
                          Text(
                            endTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: isDark ? AppColors.gray700 : AppColors.gray200,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: fgColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _detailRow(Icons.person_outline, teacher),
                          const SizedBox(height: 3),
                          _detailRow(Icons.location_on_outlined, room),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.gray400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: AppColors.gray600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: List.generate(5, (_) => Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : AppColors.gray100,
          borderRadius: BorderRadius.circular(16),
        ),
      )),
    );
  }
}
