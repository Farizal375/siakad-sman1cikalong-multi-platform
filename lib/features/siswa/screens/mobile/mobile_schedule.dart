// File: lib/features/siswa/screens/mobile/mobile_schedule.dart
// ===========================================
// MOBILE WEEKLY SCHEDULE — Timeline Style
// Day pill tabs + vertical timeline + break cards
// Connected to /jadwal API
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/providers/auth_provider.dart';
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
  String _semesterLabel = '';

  @override
  void initState() {
    super.initState();
    final todayIndex = DateTime.now().weekday - 1;
    _selectedDay = todayIndex.clamp(0, 4);
    _loadSchedule();
    _loadSemester();
  }

  Future<void> _loadSemester() async {
    try {
      final res = await ApiService.getActiveSemester();
      final data = res['data'];
      if (mounted && data != null) {
        setState(() => _semesterLabel = data['label'] ?? '');
      }
    } catch (_) {}
  }

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    try {
      final dashboard = await ref.read(studentDashboardProvider.future);
      final kelasId = dashboard['kelasId'] as String?;

      if (kelasId == null || kelasId.trim().isEmpty) {
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

      for (final day in _days) {
        grouped[day]!.sort(
          (a, b) => (a['slotIndex'] as int? ?? 0).compareTo(
            b['slotIndex'] as int? ?? 0,
          ),
        );
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
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next && next != null) {
        _loadSchedule();
        _loadSemester();
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    // Get class name and parse semester info
    final kelasName = ref.watch(studentClassNameProvider);
    String semesterText = '';
    if (_semesterLabel.isNotEmpty) {
      semesterText = ', $_semesterLabel';
    }

    // Current month/year
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final monthYear = '${months[now.month - 1]} ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Pelajaran',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kelas $kelasName$semesterText',
                      style: TextStyle(fontSize: 13, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Month Banner ──
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_month,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                monthYear.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Day Tabs (Pill style) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _days.asMap().entries.map((e) {
                final isSelected = _selectedDay == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.gray700 : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? AppColors.gray600
                                    : AppColors.gray200,
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? AppColors.gray300
                                    : AppColors.gray600),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),

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
            Icon(Icons.weekend_outlined, size: 56, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(
              'Tidak ada jadwal di hari $dayName',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nikmati waktu luangmu! 🎉',
              style: TextStyle(fontSize: 13, color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    // Combine schedule with fixed breaks and home time
    final rawItems = <Map<String, dynamic>>[];
    for (final item in schedule) {
      rawItems.add({...item, '_type': 'lesson'});
    }

    // Add default breaks
    rawItems.add({
      'startTime': '09:00',
      'endTime': '10:00',
      'label': 'Istirahat 1',
      '_type': 'break',
    });
    rawItems.add({
      'startTime': '12:00',
      'endTime': '13:00',
      'label': 'Istirahat 2',
      '_type': 'break',
    });
    rawItems.add({
      'startTime': '16:00',
      'endTime': '',
      'label': 'Pulang',
      '_type': 'home',
    });

    int parseTime(String t) {
      try {
        final p = t.split(':');
        return int.parse(p[0]) * 60 + int.parse(p[1]);
      } catch (e) {
        return 0;
      }
    }

    rawItems.sort(
      (a, b) => parseTime(a['startTime']).compareTo(parseTime(b['startTime'])),
    );

    // Build timeline items
    final timelineItems = <_TimelineEntry>[];
    for (final item in rawItems) {
      if (item['_type'] == 'break') {
        timelineItems.add(
          _TimelineEntry(type: _TimelineType.breakTime, data: item),
        );
      } else if (item['_type'] == 'home') {
        timelineItems.add(
          _TimelineEntry(type: _TimelineType.endOfDay, data: item),
        );
      } else {
        timelineItems.add(
          _TimelineEntry(type: _TimelineType.lesson, data: item),
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: timelineItems.length,
      itemBuilder: (context, index) {
        final entry = timelineItems[index];
        final isLast = index == timelineItems.length - 1;

        if (entry.type == _TimelineType.breakTime ||
            entry.type == _TimelineType.endOfDay) {
          final isHome = entry.type == _TimelineType.endOfDay;
          return _buildBreakItem(
            context,
            entry.data,
            isLast,
            icon: isHome ? Icons.home_outlined : Icons.restaurant_outlined,
            isHome: isHome,
          );
        }
        return _buildTimelineItem(context, entry.data, index, isLast);
      },
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    final subject = item['subject'] ?? '-';
    final startTime = item['startTime'] ?? '';
    final endTime = item['endTime'] ?? '';
    final teacher = item['teacher'] ?? '-';
    final room = item['room'] ?? '-';

    // Determine JP (jam pelajaran) from time
    String jpText = '';
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      if (startParts.length == 2 && endParts.length == 2) {
        final startMin =
            int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        final jp = ((endMin - startMin) / 45).round();
        if (jp > 0) jpText = '($jp JP)';
      }
    } catch (_) {}

    // Accent colors for visual variety
    final accentColors = [
      AppColors.primary,
      const Color(0xFF059669),
      const Color(0xFF7C3AED),
      AppColors.accent,
      const Color(0xFFDC2626),
    ];
    final accentColor = accentColors[index % accentColors.length];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time Label ──
          SizedBox(
            width: 50,
            child: Text(
              startTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray500,
              ),
            ),
          ),

          // ── Timeline Line + Dot ──
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: accentColor.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),

          // ── Schedule Card ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: accentColor, width: 3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: fgColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              room,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 6),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 14,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$startTime - $endTime $jpText',
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

  Widget _buildBreakItem(
    BuildContext context,
    Map<String, dynamic> data,
    bool isLast, {
    IconData icon = Icons.restaurant_outlined,
    bool isHome = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final time = data['startTime'] ?? '';
    final label = data['label'] ?? 'Istirahat';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray500,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isHome ? AppColors.primary : AppColors.gray300,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.gray200),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isHome
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : (isDark
                          ? AppColors.gray700.withValues(alpha: 0.5)
                          : AppColors.gray50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHome
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : (isDark ? AppColors.gray600 : AppColors.gray200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isHome ? AppColors.primary : AppColors.gray400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isHome ? AppColors.primary : AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? const Color(0xFF1F2937) : AppColors.gray100;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: List.generate(
        5,
        (_) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

enum _TimelineType { lesson, breakTime, endOfDay }

class _TimelineEntry {
  final _TimelineType type;
  final Map<String, dynamic> data;

  _TimelineEntry({required this.type, required this.data});
}
