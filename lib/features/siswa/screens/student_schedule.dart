// File: lib/features/siswa/screens/student_schedule.dart
// ===========================================
// STUDENT WEEKLY SCHEDULE - Web
// Uses the same dashboard class context and /jadwal API as mobile.
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/student_providers.dart';

class StudentSchedule extends ConsumerStatefulWidget {
  const StudentSchedule({super.key});

  @override
  ConsumerState<StudentSchedule> createState() => _StudentScheduleState();
}

class _StudentScheduleState extends ConsumerState<StudentSchedule> {
  static const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  late int _selectedDay;
  bool _loading = true;
  String _semesterLabel = '';
  Map<String, List<Map<String, dynamic>>> _scheduleByDay = {};

  @override
  void initState() {
    super.initState();
    final todayIndex = DateTime.now().weekday - 1;
    _selectedDay = todayIndex.clamp(0, 4);
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    await Future.wait([_loadSemester(), _loadSchedule()]);
    if (mounted) setState(() => _loading = false);
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
    try {
      final dashboard = await ref.read(studentDashboardProvider.future);
      final kelasId = dashboard['kelasId'] as String?;
      if (kelasId == null || kelasId.trim().isEmpty) {
        if (mounted) {
          setState(() => _scheduleByDay = _emptySchedule());
        }
        return;
      }

      final response = await ApiService.getJadwal(kelasId: kelasId);
      final List data = response['data'] ?? [];
      final grouped = _emptySchedule();

      for (final item in data) {
        final schedule = item as Map<String, dynamic>;
        final day = schedule['day'] as String? ?? '';
        if (grouped.containsKey(day)) {
          grouped[day]!.add(schedule);
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
        setState(() => _scheduleByDay = grouped);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _scheduleByDay = _emptySchedule());
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> _emptySchedule() => {
    for (final day in _days) day: <Map<String, dynamic>>[],
  };

  String _monthYear() {
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
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next && next != null) {
        _load();
      }
    });

    final kelasName = ref.watch(studentClassNameProvider);
    final selectedDayName = _days[_selectedDay];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal Pelajaran',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelas $kelasName${_semesterLabel.isNotEmpty ? ' - $_semesterLabel' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Muat Ulang'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jadwal Pelajaran',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kelas $kelasName${_semesterLabel.isNotEmpty ? ' - $_semesterLabel' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Muat Ulang'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _monthYear(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedDayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _monthYear(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          selectedDayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _days.asMap().entries.map((entry) {
                final selected = entry.key == _selectedDay;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedDay = entry.key),
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.gray200,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.gray700,
                    fontWeight: FontWeight.w700,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? _buildSkeleton()
                  : _buildDaySchedule(selectedDayName),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDaySchedule(String dayName) {
    final schedule = _scheduleByDay[dayName] ?? [];

    if (schedule.isEmpty) {
      return _buildEmpty(dayName);
    }

    final rawItems = <Map<String, dynamic>>[
      for (final item in schedule) {...item, '_type': 'lesson'},
      {
        'startTime': '09:00',
        'endTime': '10:00',
        'label': 'Istirahat 1',
        '_type': 'break',
      },
      {
        'startTime': '12:00',
        'endTime': '13:00',
        'label': 'Istirahat 2',
        '_type': 'break',
      },
      {'startTime': '16:00', 'endTime': '', 'label': 'Pulang', '_type': 'home'},
    ];

    rawItems.sort(
      (a, b) =>
          _parseTime(a['startTime']).compareTo(_parseTime(b['startTime'])),
    );

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: rawItems.length,
      itemBuilder: (context, index) {
        final item = rawItems[index];
        final isLast = index == rawItems.length - 1;
        if (item['_type'] == 'break' || item['_type'] == 'home') {
          return _buildBreakItem(item, isLast);
        }
        return _buildLessonItem(item, index, isLast);
      },
    );
  }

  int _parseTime(dynamic value) {
    try {
      final parts = value.toString().split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  Widget _buildLessonItem(Map<String, dynamic> item, int index, bool isLast) {
    final subject = item['subject'] ?? '-';
    final startTime = item['startTime'] ?? '';
    final endTime = item['endTime'] ?? '';
    final teacher = item['teacher'] ?? '-';
    final room = item['room'] ?? '-';
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
          _timeColumn(startTime),
          _timelineDot(accentColor, isLast),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: accentColor, width: 4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 460;
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _meta(Icons.person_outline, teacher),
                            _meta(
                              Icons.schedule_outlined,
                              '$startTime - $endTime',
                            ),
                            _meta(Icons.meeting_room_outlined, room),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            room,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _meta(Icons.person_outline, teacher),
                                _meta(
                                  Icons.schedule_outlined,
                                  '$startTime - $endTime',
                                ),
                                _meta(Icons.meeting_room_outlined, room),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          room,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakItem(Map<String, dynamic> item, bool isLast) {
    final isHome = item['_type'] == 'home';
    final color = isHome ? AppColors.primary : AppColors.gray300;
    final label = item['label'] ?? 'Istirahat';
    final startTime = item['startTime'] ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timeColumn(startTime),
          _timelineDot(color, isLast),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isHome
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHome
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.gray200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isHome ? Icons.home_outlined : Icons.restaurant_outlined,
                    size: 16,
                    color: isHome ? AppColors.primary : AppColors.gray500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isHome ? AppColors.primary : AppColors.gray600,
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

  Widget _timeColumn(dynamic time) {
    return SizedBox(
      width: 72,
      child: Text(
        time.toString(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.gray500,
        ),
      ),
    );
  }

  Widget _timelineDot(Color color, bool isLast) {
    return SizedBox(
      width: 34,
      child: Column(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          if (!isLast)
            Expanded(
              child: Container(width: 2, color: color.withValues(alpha: 0.22)),
            ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, dynamic value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.gray400),
        const SizedBox(width: 5),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 13, color: AppColors.gray600),
        ),
      ],
    );
  }

  Widget _buildEmpty(String dayName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.weekend_outlined,
            size: 60,
            color: AppColors.gray300,
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada jadwal di hari $dayName',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Jadwal akan tampil setelah kurikulum mengatur kelas aktif.',
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: EdgeInsets.zero,
      children: List.generate(
        5,
        (_) => Container(
          height: 88,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
