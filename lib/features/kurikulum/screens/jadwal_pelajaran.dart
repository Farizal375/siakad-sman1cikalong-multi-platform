// File: lib/features/kurikulum/screens/jadwal_pelajaran.dart
// ===========================================
// JADWAL PELAJARAN (Schedule Management)
// Features: Guru-Mapel mapping with quota tracking,
// Weekly grid with TimePicker, Edit/Delete, Drag & Drop
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../shared_widgets/table_pagination.dart';
import '../../../shared_widgets/delete_confirmation_modal.dart';
import '../../../shared_widgets/success_toast.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// DATA MODELS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class ScheduleEntry {
  String subject;
  String teacher;
  String room;
  TimeOfDay startTime;
  TimeOfDay endTime;

  ScheduleEntry({
    required this.subject,
    required this.teacher,
    required this.room,
    required this.startTime,
    required this.endTime,
  });

  ScheduleEntry copyWith({
    String? subject,
    String? teacher,
    String? room,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return ScheduleEntry(
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  double get durationHours {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return (endMinutes - startMinutes) / 60.0;
  }

  String get timeLabel =>
      '${_fmt(startTime)} - ${_fmt(endTime)}';

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class TeacherMapping {
  String teacher;
  String subject;
  String classes;
  int hoursPerWeek; // Kuota (stok) jam per minggu

  TeacherMapping({
    required this.teacher,
    required this.subject,
    required this.classes,
    required this.hoursPerWeek,
  });
}

// ════════════════════════════════════════════════════════════════════════════════
// SHARED STATE – loaded from API
// ════════════════════════════════════════════════════════════════════════════════
// Key: '{slotIndex}_{dayIndex}'
final Map<String, ScheduleEntry> _globalScheduleData = {
  '0_0': ScheduleEntry(subject: 'Matematika', teacher: 'Dr. Siti N.', room: 'R-101', startTime: const TimeOfDay(hour: 7, minute: 0), endTime: const TimeOfDay(hour: 7, minute: 45)),
  '1_0': ScheduleEntry(subject: 'Matematika', teacher: 'Dr. Siti N.', room: 'R-101', startTime: const TimeOfDay(hour: 7, minute: 45), endTime: const TimeOfDay(hour: 8, minute: 30)),
  '2_0': ScheduleEntry(subject: 'Fisika', teacher: 'Budi S.', room: 'LAB-01', startTime: const TimeOfDay(hour: 8, minute: 30), endTime: const TimeOfDay(hour: 9, minute: 15)),
  '0_1': ScheduleEntry(subject: 'B. Indonesia', teacher: 'Prof. Ani', room: 'R-101', startTime: const TimeOfDay(hour: 7, minute: 0), endTime: const TimeOfDay(hour: 7, minute: 45)),
  '1_1': ScheduleEntry(subject: 'B. Indonesia', teacher: 'Prof. Ani', room: 'R-101', startTime: const TimeOfDay(hour: 7, minute: 45), endTime: const TimeOfDay(hour: 8, minute: 30)),
  '2_1': ScheduleEntry(subject: 'Kimia', teacher: 'Ahmad H.', room: 'LAB-01', startTime: const TimeOfDay(hour: 8, minute: 30), endTime: const TimeOfDay(hour: 9, minute: 15)),
  '3_1': ScheduleEntry(subject: 'Kimia', teacher: 'Ahmad H.', room: 'LAB-01', startTime: const TimeOfDay(hour: 9, minute: 30), endTime: const TimeOfDay(hour: 10, minute: 15)),
  '0_2': ScheduleEntry(subject: 'B. Inggris', teacher: 'Drs. Hendra', room: 'R-101', startTime: const TimeOfDay(hour: 7, minute: 0), endTime: const TimeOfDay(hour: 7, minute: 45)),
  '1_2': ScheduleEntry(subject: 'B. Inggris', teacher: 'Drs. Hendra', room: 'R-101', startTime: const TimeOfDay(hour: 7, minute: 45), endTime: const TimeOfDay(hour: 8, minute: 30)),
  '3_2': ScheduleEntry(subject: 'Biologi', teacher: 'Rina K.', room: 'LAB-01', startTime: const TimeOfDay(hour: 9, minute: 30), endTime: const TimeOfDay(hour: 10, minute: 15)),
  '4_2': ScheduleEntry(subject: 'Biologi', teacher: 'Rina K.', room: 'LAB-01', startTime: const TimeOfDay(hour: 10, minute: 15), endTime: const TimeOfDay(hour: 11, minute: 0)),
  '0_3': ScheduleEntry(subject: 'PKN', teacher: 'Drs. Agus', room: 'R-101', startTime: const TimeOfDay(hour: 7, minute: 0), endTime: const TimeOfDay(hour: 7, minute: 45)),
  '1_3': ScheduleEntry(subject: 'Sejarah', teacher: 'Dra. Lina', room: 'R-101', startTime: const TimeOfDay(hour: 7, minute: 45), endTime: const TimeOfDay(hour: 8, minute: 30)),
  '3_3': ScheduleEntry(subject: 'Fisika', teacher: 'Budi S.', room: 'LAB-01', startTime: const TimeOfDay(hour: 9, minute: 30), endTime: const TimeOfDay(hour: 10, minute: 15)),
  '4_3': ScheduleEntry(subject: 'Fisika', teacher: 'Budi S.', room: 'LAB-01', startTime: const TimeOfDay(hour: 10, minute: 15), endTime: const TimeOfDay(hour: 11, minute: 0)),
  '0_4': ScheduleEntry(subject: 'PAI', teacher: 'Ust. Rahman', room: 'R-101', startTime: const TimeOfDay(hour: 7, minute: 0), endTime: const TimeOfDay(hour: 7, minute: 45)),
  '1_4': ScheduleEntry(subject: 'B. Sunda', teacher: 'Ibu Neng', room: 'R-101', startTime: const TimeOfDay(hour: 7, minute: 45), endTime: const TimeOfDay(hour: 8, minute: 30)),
  '2_4': ScheduleEntry(subject: 'Olahraga', teacher: 'Pak Deni', room: 'Lapangan', startTime: const TimeOfDay(hour: 8, minute: 30), endTime: const TimeOfDay(hour: 9, minute: 15)),
};

// Jadwal IDs mapped to same keys for CRUD
final Map<String, String> _globalScheduleIds = {};

final List<TeacherMapping> _globalTeacherMappings = [
  TeacherMapping(teacher: 'Dr. Siti Nurhaliza, S.Pd', subject: 'Matematika Wajib', classes: 'X IPA 1, X IPA 2, XI IPA 1', hoursPerWeek: 12),
  TeacherMapping(teacher: 'Budi Santoso, M.Pd', subject: 'Fisika', classes: 'X IPA 1, XI IPA 1', hoursPerWeek: 8),
  TeacherMapping(teacher: 'Ahmad Hidayat, S.Pd', subject: 'Kimia', classes: 'X IPA 2, XI IPA 1, XII IPA 1', hoursPerWeek: 12),
  TeacherMapping(teacher: 'Rina Kartika, S.Pd', subject: 'Biologi', classes: 'XI IPA 1, XII IPA 1', hoursPerWeek: 8),
  TeacherMapping(teacher: 'Prof. Dr. Ani Widiastuti', subject: 'Bahasa Indonesia', classes: 'X IPA 1, X IPA 2, XI IPS 1', hoursPerWeek: 12),
  TeacherMapping(teacher: 'Drs. Hendra Gunawan', subject: 'Bahasa Inggris', classes: 'XI IPS 1, XII IPA 1', hoursPerWeek: 8),
  TeacherMapping(teacher: 'Ir. Subekti, M.Si', subject: 'Matematika Peminatan', classes: 'XI IPA 1, XII IPA 1', hoursPerWeek: 8),
];

// Guru-mapel IDs for CRUD
final List<String> _globalTeacherMappingIds = [];

// Helper: count scheduled hours for a teacher (simplified: each slot = ~0.75h â‰ˆ 1 jam pelajaran)
int _countScheduledSlots(String teacherShortName) {
  return _globalScheduleData.values
      .where((e) => e.teacher == teacherShortName)
      .length;
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// MAIN WIDGET
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class JadwalPelajaran extends StatefulWidget {
  const JadwalPelajaran({super.key});

  @override
  State<JadwalPelajaran> createState() => _JadwalPelajaranState();
}

class _JadwalPelajaranState extends State<JadwalPelajaran> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSuccessToast = false;
  String _successMessage = '';
  String? _selectedKelas = 'X IPA 1';
  String? _selectedTahunAjaran = '2026/2027';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      // Load guru-mapel mappings
      final gmResponse = await ApiService.getGuruMapel();
      final List gmData = gmResponse['data'] ?? [];
      _globalTeacherMappings.clear();
      _globalTeacherMappingIds.clear();
      for (final gm in gmData) {
        _globalTeacherMappings.add(TeacherMapping(
          teacher: gm['teacher'] ?? '-',
          subject: gm['subject'] ?? '-',
          classes: gm['classes'] ?? '-',
          hoursPerWeek: (gm['hoursPerWeek'] as num?)?.toInt() ?? 8,
        ));
        _globalTeacherMappingIds.add((gm['id'] ?? '').toString());
      }

      // Load jadwal
      final jResponse = await ApiService.getJadwal();
      final List jData = jResponse['data'] ?? [];
      _globalScheduleData.clear();
      _globalScheduleIds.clear();
      final dayMap = {'Senin': 0, 'Selasa': 1, 'Rabu': 2, 'Kamis': 3, 'Jumat': 4};
      for (final j in jData) {
        final hari = j['hari'] ?? 'Senin';
        final dayIdx = dayMap[hari] ?? 0;
        final jamMulai = j['jamMulai'] ?? '07:00';
        final jamSelesai = j['jamSelesai'] ?? '07:45';
        final slotIdx = _timeStringToSlotIndex(jamMulai);
        final key = '${slotIdx}_$dayIdx';
        _globalScheduleData[key] = ScheduleEntry(
          subject: j['mataPelajaran'] ?? j['mapel'] ?? '-',
          teacher: j['guru'] ?? j['guruName'] ?? '-',
          room: j['ruang'] ?? '',
          startTime: _parseTime(jamMulai),
          endTime: _parseTime(jamSelesai),
        );
        _globalScheduleIds[key] = (j['id'] ?? '').toString();
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  static TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 7, minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
  }

  static int _timeStringToSlotIndex(String t) {
    final slotStarts = ['07:00', '07:45', '08:30', '09:30', '10:15', '11:00', '13:00', '13:45'];
    final idx = slotStarts.indexOf(t);
    return idx >= 0 ? idx : 0;
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSuccess(String msg) {
    setState(() {
      _successMessage = msg;
      _showSuccessToast = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Page Title â”€â”€
            const Text(
              'Jadwal Pelajaran',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola pemetaan guru ke mata pelajaran dan susun jadwal mingguan',
              style: TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 32),

            // â”€â”€ 2-Tab navigation â”€â”€
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(8),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.gray600,
                labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Pemetaan Guru-Mapel'),
                  Tab(text: 'Jadwal Per Kelas'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // â”€â”€ Tab Content â”€â”€
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TeacherSubjectMapping(onSuccess: _showSuccess),
                  _WeeklyScheduleGrid(
                    selectedKelas: _selectedKelas,
                    selectedTahunAjaran: _selectedTahunAjaran,
                    onKelasChanged: (v) => setState(() => _selectedKelas = v),
                    onTahunAjaranChanged: (v) => setState(() => _selectedTahunAjaran = v),
                    onSuccess: _showSuccess,
                    onDataChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_showSuccessToast)
          Positioned(
            top: 16, right: 16,
            child: SuccessToast(isVisible: true, message: _successMessage, onClose: () => setState(() => _showSuccessToast = false)),
          ),
      ],
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB 1: TEACHER-SUBJECT MAPPING TABLE
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _TeacherSubjectMapping extends StatefulWidget {
  final void Function(String msg) onSuccess;
  const _TeacherSubjectMapping({required this.onSuccess});

  @override
  State<_TeacherSubjectMapping> createState() => _TeacherSubjectMappingState();
}

class _TeacherSubjectMappingState extends State<_TeacherSubjectMapping> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  bool get wantKeepAlive => true;

  // Mapping from full name â†’ short name used in schedule data
  static const Map<String, String> _teacherShortNames = {
    'Dr. Siti Nurhaliza, S.Pd': 'Dr. Siti N.',
    'Budi Santoso, M.Pd': 'Budi S.',
    'Ahmad Hidayat, S.Pd': 'Ahmad H.',
    'Rina Kartika, S.Pd': 'Rina K.',
    'Prof. Dr. Ani Widiastuti': 'Prof. Ani',
    'Drs. Hendra Gunawan': 'Drs. Hendra',
    'Ir. Subekti, M.Si': 'Ir. Subekti',
  };

  void _showMappingModal({bool isEdit = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _TeacherMappingFormModal(isEdit: isEdit),
        ),
      ),
    ).then((result) {
      if (result == true) {
        widget.onSuccess(isEdit ? 'Pemetaan guru berhasil diperbarui' : 'Pemetaan guru baru berhasil ditambahkan');
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final total = _globalTeacherMappings.length;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, total);
    final pageData = _globalTeacherMappings.sublist(start, end);

    return Column(
      children: [
        // Action bar
        Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari guru atau mapel...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showMappingModal(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Tambah Pemetaan'),
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
        const SizedBox(height: 24),

        // Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: AppColors.gray50,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Nama Guru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                      Expanded(flex: 3, child: Text('Mata Pelajaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                      Expanded(flex: 3, child: Text('Kelas Diampu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                      Expanded(flex: 1, child: Text('Kuota', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                      Expanded(flex: 2, child: Text('Terjadwal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                      SizedBox(width: 80, child: Text('Aksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.gray200),
                Expanded(
                  child: ListView.separated(
                    itemCount: pageData.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
                    itemBuilder: (_, i) {
                      final m = pageData[i];
                      final shortName = _teacherShortNames[m.teacher] ?? m.teacher;
                      final scheduled = _countScheduledSlots(shortName);
                      final isFull = scheduled >= m.hoursPerWeek;
                      final isOver = scheduled > m.hoursPerWeek;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(m.teacher, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground))),
                            Expanded(flex: 3, child: Text(m.subject, style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                            Expanded(
                              flex: 3,
                              child: Wrap(
                                spacing: 4, runSpacing: 4,
                                children: m.classes.split(', ').map((c) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(999)),
                                  child: Text(c, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF1D4ED8))),
                                )).toList(),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${m.hoursPerWeek} jp',
                                style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Text(
                                    '$scheduled / ${m.hoursPerWeek}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isOver ? const Color(0xFFDC2626) : isFull ? const Color(0xFF16A34A) : AppColors.foreground,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isFull)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isOver ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        isOver ? 'Melebihi!' : 'Penuh',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isOver ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () => _showMappingModal(isEdit: true), tooltip: 'Edit'),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600),
                                    onPressed: () {
                                      DeleteConfirmationModal.show(
                                        context,
                                        title: 'Hapus Pemetaan Guru',
                                        message: 'Apakah Anda yakin ingin menghapus pemetaan guru ini?',
                                        itemName: '${m.teacher} - ${m.subject}',
                                        onConfirm: () => widget.onSuccess('Pemetaan berhasil dihapus'),
                                      );
                                    },
                                    tooltip: 'Hapus',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                TablePagination(currentPage: _currentPage, totalItems: total, itemsPerPage: _itemsPerPage, onPageChange: (p) => setState(() => _currentPage = p), onItemsPerPageChange: (n) => setState(() { _itemsPerPage = n; _currentPage = 1; }), itemName: 'pemetaan'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB 2: WEEKLY SCHEDULE GRID (StatefulWidget)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _WeeklyScheduleGrid extends StatefulWidget {
  final String? selectedKelas;
  final String? selectedTahunAjaran;
  final ValueChanged<String?> onKelasChanged;
  final ValueChanged<String?> onTahunAjaranChanged;
  final void Function(String msg) onSuccess;
  final VoidCallback onDataChanged;

  const _WeeklyScheduleGrid({
    required this.selectedKelas,
    required this.selectedTahunAjaran,
    required this.onKelasChanged,
    required this.onTahunAjaranChanged,
    required this.onSuccess,
    required this.onDataChanged,
  });

  @override
  State<_WeeklyScheduleGrid> createState() => _WeeklyScheduleGridState();
}

class _WeeklyScheduleGridState extends State<_WeeklyScheduleGrid> with AutomaticKeepAliveClientMixin {
  String? _dragTargetKey;
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  double _pointerY = 0;
  final GlobalKey _scrollAreaKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  static const List<Map<String, String>> _timeSlots = [
    {'slot': '0', 'time': '07:00\n07:45'},
    {'slot': '1', 'time': '07:45\n08:30'},
    {'slot': '2', 'time': '08:30\n09:15'},
    {'slot': '3', 'time': '09:30\n10:15'},
    {'slot': '4', 'time': '10:15\n11:00'},
    {'slot': '5', 'time': '11:00\n11:45'},
    {'slot': '6', 'time': '13:00\n13:45'},
    {'slot': '7', 'time': '13:45\n14:30'},
  ];

  // Auto-scroll logic: called on every pointer move during drag
  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDragging) return;
    _pointerY = event.position.dy;
    _performAutoScroll();
  }

  void _performAutoScroll() {
    if (!_isDragging || !_scrollController.hasClients) return;

    final scrollAreaBox = _scrollAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (scrollAreaBox == null) return;

    final scrollAreaTop = scrollAreaBox.localToGlobal(Offset.zero).dy;
    final scrollAreaHeight = scrollAreaBox.size.height;
    final scrollAreaBottom = scrollAreaTop + scrollAreaHeight;

    const edgeThreshold = 60.0; // pixels from edge to start scrolling
    const scrollSpeed = 8.0; // pixels per frame

    double scrollDelta = 0;

    // Near bottom edge â†’ scroll down
    if (_pointerY > scrollAreaBottom - edgeThreshold) {
      final intensity = ((_pointerY - (scrollAreaBottom - edgeThreshold)) / edgeThreshold).clamp(0.0, 1.0);
      scrollDelta = scrollSpeed * (1 + intensity * 2);
    }
    // Near top edge â†’ scroll up
    else if (_pointerY < scrollAreaTop + edgeThreshold) {
      final intensity = (((scrollAreaTop + edgeThreshold) - _pointerY) / edgeThreshold).clamp(0.0, 1.0);
      scrollDelta = -scrollSpeed * (1 + intensity * 2);
    }

    if (scrollDelta != 0) {
      final newOffset = (_scrollController.offset + scrollDelta)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(newOffset);

      // Continue auto-scrolling while dragging
      Future.delayed(const Duration(milliseconds: 16), () {
        if (_isDragging) _performAutoScroll();
      });
    }
  }

  void _showAddScheduleModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _ScheduleFormModal(
            onSave: (entry, day, slotIdx) {
              final key = '${slotIdx}_$day';
              setState(() {
                _globalScheduleData[key] = entry;
              });
              widget.onDataChanged();
              widget.onSuccess('Jadwal baru berhasil ditambahkan');
            },
          ),
        ),
      ),
    );
  }

  void _showEditScheduleModal(String key, ScheduleEntry entry) {
    final parts = key.split('_');
    final slotIdx = int.parse(parts[0]);
    final dayIdx = int.parse(parts[1]);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _ScheduleFormModal(
            initialEntry: entry,
            initialDay: dayIdx,
            initialSlot: slotIdx,
            isEdit: true,
            onSave: (newEntry, day, slot) {
              setState(() {
                _globalScheduleData.remove(key);
                _globalScheduleData['${slot}_$day'] = newEntry;
              });
              widget.onDataChanged();
              widget.onSuccess('Jadwal berhasil diperbarui');
            },
          ),
        ),
      ),
    );
  }

  void _deleteSchedule(String key, ScheduleEntry entry) {
    DeleteConfirmationModal.show(
      context,
      title: 'Hapus Jadwal',
      message: 'Apakah Anda yakin ingin menghapus jadwal ini?',
      itemName: '${entry.subject} (${entry.teacher})',
      onConfirm: () {
        setState(() {
          _globalScheduleData.remove(key);
        });
        widget.onDataChanged();
        widget.onSuccess('Jadwal berhasil dihapus');
      },
    );
  }

  void _handleDrop(String targetKey, String sourceKey) {
    if (targetKey == sourceKey) return;

    final entry = _globalScheduleData[sourceKey];
    if (entry == null) return;

    // Check clash: same teacher at same slot on target day
    final targetDayIdx = targetKey.split('_')[1];
    final targetSlotIdx = targetKey.split('_')[0];
    for (final e in _globalScheduleData.entries) {
      if (e.key == sourceKey) continue;
      final eDayIdx = e.key.split('_')[1];
      final eSlotIdx = e.key.split('_')[0];
      if (eDayIdx == targetDayIdx && eSlotIdx == targetSlotIdx && e.value.teacher == entry.teacher) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('âš ï¸ Bentrok! ${entry.teacher} sudah dijadwalkan pada slot ${_days[int.parse(targetDayIdx)]}, jam ke-${int.parse(targetSlotIdx) + 1}'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
    }

    // Check if target already has a schedule
    if (_globalScheduleData.containsKey(targetKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('âš ï¸ Slot ini sudah terisi. Hapus jadwal yang ada terlebih dahulu.'),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _globalScheduleData[targetKey] = entry;
      _globalScheduleData.remove(sourceKey);
      _dragTargetKey = null;
    });
    widget.onDataChanged();
    widget.onSuccess('Jadwal berhasil dipindahkan');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Filters
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: widget.selectedKelas,
                items: ['X IPA 1', 'X IPA 2', 'XI IPA 1', 'XI IPS 1', 'XII IPA 1'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: widget.onKelasChanged,
                decoration: InputDecoration(
                  labelText: 'Kelas',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: widget.selectedTahunAjaran,
                items: ['2026/2027', '2025/2026'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: widget.onTahunAjaranChanged,
                decoration: InputDecoration(
                  labelText: 'Tahun Ajaran',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _showAddScheduleModal,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Tambah Jadwal'),
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
        const SizedBox(height: 24),

        // Weekly grid with auto-scroll on drag
        Expanded(
          child: Container(
            key: _scrollAreaKey,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Listener(
              onPointerMove: _onPointerMove,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // Day headers
                    Container(
                      color: AppColors.gray50,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const SizedBox(width: 70, child: Text('Jam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                          ..._days.map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground))))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.gray200),

                    // Time slots
                    ..._timeSlots.map((slot) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(
                              slot['time']!,
                              style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontWeight: FontWeight.w500),
                            ),
                          ),
                          ...List.generate(5, (dayIdx) {
                            final scheduleKey = '${slot['slot']}_$dayIdx';
                            final schedule = _globalScheduleData[scheduleKey];
                            final isHighlighted = _dragTargetKey == scheduleKey;

                            return Expanded(
                              child: DragTarget<String>(
                                onWillAcceptWithDetails: (details) {
                                  setState(() => _dragTargetKey = scheduleKey);
                                  return true;
                                },
                                onLeave: (_) {
                                  setState(() {
                                    if (_dragTargetKey == scheduleKey) _dragTargetKey = null;
                                  });
                                },
                                onAcceptWithDetails: (details) {
                                  _dragTargetKey = null;
                                  _isDragging = false;
                                  _handleDrop(scheduleKey, details.data);
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    constraints: const BoxConstraints(minHeight: 60),
                                    decoration: BoxDecoration(
                                      color: isHighlighted
                                          ? AppColors.primary.withValues(alpha: 0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isHighlighted
                                          ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2, strokeAlign: BorderSide.strokeAlignInside)
                                          : null,
                                    ),
                                    child: schedule != null
                                        ? Draggable<String>(
                                            data: scheduleKey,
                                            onDragStarted: () {
                                              _isDragging = true;
                                            },
                                            onDragEnd: (_) {
                                              _isDragging = false;
                                            },
                                            onDraggableCanceled: (_, __) {
                                              _isDragging = false;
                                            },
                                            feedback: Material(
                                              elevation: 8,
                                              borderRadius: BorderRadius.circular(8),
                                              child: SizedBox(
                                                width: 140,
                                                child: _ScheduleCardContent(
                                                  subject: schedule.subject,
                                                  teacher: schedule.teacher,
                                                  time: schedule.timeLabel,
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: Container(
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: AppColors.gray100,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppColors.gray300, style: BorderStyle.solid),
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.drag_indicator, color: AppColors.gray400),
                                              ),
                                            ),
                                            child: _ScheduleCardWithActions(
                                              entry: schedule,
                                              onEdit: () => _showEditScheduleModal(scheduleKey, schedule),
                                              onDelete: () => _deleteSchedule(scheduleKey, schedule),
                                            ),
                                          )
                                        : const SizedBox(height: 60),
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SCHEDULE CARD CONTENT (reusable for drag feedback)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ScheduleCardContent extends StatelessWidget {
  final String subject;
  final String teacher;
  final String time;

  const _ScheduleCardContent({
    required this.subject,
    required this.teacher,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(teacher, style: const TextStyle(fontSize: 10, color: AppColors.gray600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(time, style: const TextStyle(fontSize: 10, color: AppColors.gray500, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SCHEDULE CARD WITH EDIT/DELETE
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ScheduleCardWithActions extends StatelessWidget {
  final ScheduleEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleCardWithActions({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _showPopupMenu(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(entry.subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.more_vert, size: 14, color: AppColors.gray400),
                ],
              ),
              const SizedBox(height: 2),
              Text(entry.teacher, style: const TextStyle(fontSize: 10, color: AppColors.gray600), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(entry.timeLabel, style: const TextStyle(fontSize: 10, color: AppColors.gray500, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  void _showPopupMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.schedule, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.subject, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
                      Text('${entry.teacher} â€¢ ${entry.timeLabel}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              title: const Text('Edit Jadwal', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
              title: const Text('Hapus Jadwal', style: TextStyle(fontSize: 14, color: Color(0xFFDC2626))),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.drag_indicator, size: 20, color: AppColors.gray500),
              title: const Text('Seret untuk Pindahkan', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
              subtitle: const Text('Tahan & seret ke slot lain', style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TEACHER MAPPING FORM MODAL
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _TeacherMappingFormModal extends StatelessWidget {
  final bool isEdit;
  const _TeacherMappingFormModal({this.isEdit = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEdit ? 'Edit Pemetaan Guru' : 'Tambah Pemetaan Guru', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormDropdown('Guru', ['Dr. Siti Nurhaliza, S.Pd', 'Budi Santoso, M.Pd', 'Ahmad Hidayat, S.Pd', 'Rina Kartika, S.Pd', 'Prof. Dr. Ani Widiastuti']),
          const SizedBox(height: 16),
          _buildFormDropdown('Mata Pelajaran', ['Matematika Wajib', 'Fisika', 'Kimia', 'Biologi', 'Bahasa Indonesia', 'Bahasa Inggris']),
          const SizedBox(height: 16),
          _buildFormDropdown('Kelas', ['X IPA 1', 'X IPA 2', 'XI IPA 1', 'XI IPS 1', 'XII IPA 1']),
          const SizedBox(height: 16),
          _buildFormTextField('Jam per Minggu (Kuota Stok)', 'Contoh: 4'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gray600,
                  side: const BorderSide(color: AppColors.gray300),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SCHEDULE FORM MODAL (with TimePicker)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ScheduleFormModal extends StatefulWidget {
  final ScheduleEntry? initialEntry;
  final int? initialDay;
  final int? initialSlot;
  final bool isEdit;
  final void Function(ScheduleEntry entry, int dayIndex, int slotIndex) onSave;

  const _ScheduleFormModal({
    this.initialEntry,
    this.initialDay,
    this.initialSlot,
    this.isEdit = false,
    required this.onSave,
  });

  @override
  State<_ScheduleFormModal> createState() => _ScheduleFormModalState();
}

class _ScheduleFormModalState extends State<_ScheduleFormModal> {
  String? _selectedDay;
  String? _selectedMapel;
  String? _selectedGuru;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 45);
  String? _warningMessage;

  static const List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialEntry != null) {
      _selectedMapel = widget.initialEntry!.subject;
      _selectedGuru = widget.initialEntry!.teacher;
      _startTime = widget.initialEntry!.startTime;
      _endTime = widget.initialEntry!.endTime;
      if (widget.initialDay != null) {
        _selectedDay = _days[widget.initialDay!];
      }
    }
  }

  void _checkQuota() {
    if (_selectedGuru == null) return;

    // Find the teacher mapping that matches
    final mapping = _globalTeacherMappings.where(
      (m) {
        // Simple matching: check if the short name corresponds
        final shortNames = {
          'Dr. Siti Nurhaliza, S.Pd': 'Dr. Siti N.',
          'Budi Santoso, M.Pd': 'Budi S.',
          'Ahmad Hidayat, S.Pd': 'Ahmad H.',
          'Rina Kartika, S.Pd': 'Rina K.',
          'Prof. Dr. Ani Widiastuti': 'Prof. Ani',
          'Drs. Hendra Gunawan': 'Drs. Hendra',
        };
        return shortNames[m.teacher] == _selectedGuru || m.teacher == _selectedGuru;
      },
    );

    if (mapping.isNotEmpty) {
      final m = mapping.first;
      final shortNames = {
        'Dr. Siti Nurhaliza, S.Pd': 'Dr. Siti N.',
        'Budi Santoso, M.Pd': 'Budi S.',
        'Ahmad Hidayat, S.Pd': 'Ahmad H.',
        'Rina Kartika, S.Pd': 'Rina K.',
        'Prof. Dr. Ani Widiastuti': 'Prof. Ani',
        'Drs. Hendra Gunawan': 'Drs. Hendra',
      };
      final shortName = shortNames[m.teacher] ?? m.teacher;
      final scheduled = _countScheduledSlots(shortName);
      if (scheduled >= m.hoursPerWeek) {
        setState(() {
          _warningMessage = 'âš ï¸ ${m.teacher} sudah mencapai kuota $scheduled/${m.hoursPerWeek} jam/minggu. Menambah jadwal baru akan melebihi batas!';
        });
        return;
      }
    }
    setState(() => _warningMessage = null);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _timeToSlotIndex(TimeOfDay t) {
    // Map start time to closest slot index
    final slotStarts = [
      const TimeOfDay(hour: 7, minute: 0),
      const TimeOfDay(hour: 7, minute: 45),
      const TimeOfDay(hour: 8, minute: 30),
      const TimeOfDay(hour: 9, minute: 30),
      const TimeOfDay(hour: 10, minute: 15),
      const TimeOfDay(hour: 11, minute: 0),
      const TimeOfDay(hour: 13, minute: 0),
      const TimeOfDay(hour: 13, minute: 45),
    ];

    int closest = 0;
    int minDiff = 9999;
    for (int i = 0; i < slotStarts.length; i++) {
      final diff = ((slotStarts[i].hour * 60 + slotStarts[i].minute) - (t.hour * 60 + t.minute)).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.isEdit ? 'Edit Jadwal' : 'Tambah Jadwal Baru', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),

          // Warnings
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Sistem akan menolak jika Guru yang sama dijadwalkan ganda pada hari & jam yang sama.', style: TextStyle(fontSize: 13, color: Color(0xFF92400E)))),
              ],
            ),
          ),

          if (_warningMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_warningMessage!, style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          _buildFormDropdown('Hari', _days, value: _selectedDay, onChanged: (v) => setState(() => _selectedDay = v)),
          const SizedBox(height: 16),

          // TimePicker Row
          const Text('Waktu Mulai & Selesai', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(_fmtTime(_startTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                        const Spacer(),
                        const Text('Mulai', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, size: 20, color: AppColors.gray400),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(_fmtTime(_endTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                        const Spacer(),
                        const Text('Selesai', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildFormDropdown('Mata Pelajaran', ['Matematika', 'Matematika Wajib', 'Fisika', 'Kimia', 'Biologi', 'B. Indonesia', 'Bahasa Indonesia', 'B. Inggris', 'Bahasa Inggris', 'B. Sunda', 'PKN', 'Sejarah', 'PAI', 'Olahraga'], value: _selectedMapel, onChanged: (v) => setState(() => _selectedMapel = v)),
          const SizedBox(height: 16),
          _buildFormDropdown('Guru', ['Dr. Siti N.', 'Budi S.', 'Ahmad H.', 'Rina K.', 'Prof. Ani', 'Drs. Hendra', 'Ir. Subekti', 'Drs. Agus', 'Dra. Lina', 'Ust. Rahman', 'Ibu Neng', 'Pak Deni'],
            value: _selectedGuru,
            onChanged: (v) {
              setState(() => _selectedGuru = v);
              _checkQuota();
            },
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gray600,
                  side: const BorderSide(color: AppColors.gray300),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_selectedDay == null || _selectedMapel == null || _selectedGuru == null) return;

                  final dayIdx = _days.indexOf(_selectedDay!);
                  final slotIdx = widget.isEdit && widget.initialSlot != null
                      ? widget.initialSlot!
                      : _timeToSlotIndex(_startTime);

                  final entry = ScheduleEntry(
                    subject: _selectedMapel!,
                    teacher: _selectedGuru!,
                    room: '',
                    startTime: _startTime,
                    endTime: _endTime,
                  );

                  widget.onSave(entry, dayIdx, slotIdx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: Text(widget.isEdit ? 'Simpan Perubahan' : 'Simpan Jadwal'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SHARED FORM HELPERS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
Widget _buildFormDropdown(String label, List<String> items, {String? value, ValueChanged<String?>? onChanged}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged ?? (_) {},
        decoration: InputDecoration(
          filled: true, fillColor: AppColors.gray50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ],
  );
}

Widget _buildFormTextField(String label, String hint) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground)),
      const SizedBox(height: 8),
      TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.gray400),
          filled: true, fillColor: AppColors.gray50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ],
  );
}
