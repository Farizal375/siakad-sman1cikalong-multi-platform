// File: lib/features/siswa/screens/mobile/mobile_riwayat_kehadiran.dart
// ===========================================
// MOBILE ATTENDANCE HISTORY — Redesigned
// Summary cards + detail list + FAB QR
// Connected to /kehadiran/siswa/:id API
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../providers/student_providers.dart';
import 'mobile_qr_scanner.dart';
import 'mobile_riwayat_mapel.dart';

class MobileRiwayatKehadiran extends ConsumerStatefulWidget {
  const MobileRiwayatKehadiran({super.key});
  @override
  ConsumerState<MobileRiwayatKehadiran> createState() => _State();
}

class _State extends ConsumerState<MobileRiwayatKehadiran>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _semesterLabel = 'Memuat...';
  String? _selectedSemesterId;
  List<Map<String, dynamic>> _semesters = [];
  List<Map<String, dynamic>> _allMeetings = [];
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Map<String, Map<String, dynamic>> _groupedMapel = {};

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      // 1. Fetch all semesters
      try {
        final semRes = await ApiService.getSemester();
        final List sems = semRes['data'] ?? [];
        if (mounted) {
          _semesters = sems.cast<Map<String, dynamic>>();

          if (_selectedSemesterId == null) {
            // Find active semester
            final active = _semesters.firstWhere(
              (s) => s['isActive'] == true,
              orElse: () => _semesters.isNotEmpty ? _semesters.first : {},
            );
            if (active.isNotEmpty) {
              _selectedSemesterId = active['id'];
              _semesterLabel = '${active['name']} - ${active['academicYear']}';
            } else {
              _semesterLabel = 'Semester Aktif';
            }
          } else {
            // Update label based on selected
            final selected = _semesters.firstWhere(
              (s) => s['id'] == _selectedSemesterId,
              orElse: () => {},
            );
            if (selected.isNotEmpty) {
              _semesterLabel =
                  '${selected['name']} - ${selected['academicYear']}';
            }
          }
        }
      } catch (_) {
        _semesterLabel = 'Semester Aktif';
      }

      // 2. Get student's class ID from dashboard provider
      String? kelasId;
      try {
        final dashboard = await ref.read(studentDashboardProvider.future);
        kelasId = dashboard['kelasId'] as String?;
      } catch (_) {}

      final Map<String, Map<String, dynamic>> grouped = {};

      // 2. Fetch all subjects for this class from Jadwal to initialize 0%
      if (kelasId != null) {
        try {
          final jadwalRes = await ApiService.getJadwal(kelasId: kelasId);
          final List jadwalData = jadwalRes['data'] ?? [];
          for (final item in jadwalData) {
            final subject = item['subject'] as String? ?? '';
            final teacher = item['teacher'] as String? ?? '-';
            if (subject.isNotEmpty && !grouped.containsKey(subject)) {
              grouped[subject] = {
                'mapel': subject,
                'guru': teacher,
                'meetings': <Map<String, dynamic>>[],
                'totalHadir': 0,
                'totalAll': 0,
              };
            }
          }
        } catch (_) {}
      }

      // 3. Fetch attendance history filtered by semester
      final response = await ApiService.getKehadiranSiswa(
        userId,
        _selectedSemesterId,
      );
      final List data = response['data'] ?? [];

      // 4. Merge attendance history into grouped mapels
      for (final item in data) {
        final m = item as Map<String, dynamic>;
        final mapel = m['mapel'] as String? ?? '-';
        final guru = m['guru'] as String? ?? '-';

        if (!grouped.containsKey(mapel)) {
          grouped[mapel] = {
            'mapel': mapel,
            'guru': guru,
            'meetings': <Map<String, dynamic>>[],
            'totalHadir': 0,
            'totalAll': 0,
          };
        }

        grouped[mapel]!['meetings'].add(m);
        grouped[mapel]!['totalAll'] = (grouped[mapel]!['totalAll'] as int) + 1;
        if ((m['status'] as String? ?? '').toUpperCase() == 'HADIR') {
          grouped[mapel]!['totalHadir'] =
              (grouped[mapel]!['totalHadir'] as int) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _allMeetings = data.cast<Map<String, dynamic>>();
          _groupedMapel = grouped;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _count(String status) => _allMeetings
      .where((m) => (m['status'] as String).toUpperCase() == status)
      .length;

  IconData _mapelIcon(String mapel) {
    final lower = mapel.toLowerCase();
    if (lower.contains('matematika')) return Icons.functions;
    if (lower.contains('fisika')) return Icons.science_outlined;
    if (lower.contains('biologi')) return Icons.biotech_outlined;
    if (lower.contains('kimia')) return Icons.science;
    if (lower.contains('inggris')) return Icons.language;
    if (lower.contains('indonesia')) return Icons.menu_book_outlined;
    if (lower.contains('sejarah')) return Icons.history_edu;
    if (lower.contains('agama')) return Icons.mosque_outlined;
    if (lower.contains('olahraga') || lower.contains('penjas')) {
      return Icons.sports_soccer;
    }
    if (lower.contains('seni')) return Icons.palette_outlined;
    if (lower.contains('ekonomi')) return Icons.account_balance_outlined;
    if (lower.contains('geografi')) return Icons.public;
    if (lower.contains('informatika') || lower.contains('komputer')) {
      return Icons.computer;
    }
    return Icons.book_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    final hadir = _count('HADIR');
    final sakit = _count('SAKIT');
    final izin = _count('IZIN');
    final alpa = _count('ALPA');

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Riwayat Presensi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: fgColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.gray700 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.gray600 : AppColors.gray200,
                      ),
                    ),
                    child: _semesters.isEmpty
                        ? Text(
                            _semesterLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: fgColor,
                            ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSemesterId,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: AppColors.gray400,
                              ),
                              isDense: true,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: fgColor,
                              ),
                              dropdownColor: isDark
                                  ? AppColors.gray900
                                  : Colors.white,
                              items: _semesters.map((s) {
                                final label =
                                    '${s['name']} - ${s['academicYear']}';
                                return DropdownMenuItem(
                                  value: s['id'] as String,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null && val != _selectedSemesterId) {
                                  setState(() => _selectedSemesterId = val);
                                  _load();
                                }
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _summaryCard(
                    context,
                    '$hadir',
                    'Hadir',
                    const Color(0xFF16A34A),
                    Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    context,
                    '$sakit',
                    'Sakit',
                    const Color(0xFFD97706),
                    Icons.sick_outlined,
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    context,
                    '$izin',
                    'Izin',
                    const Color(0xFF2563EB),
                    Icons.assignment_outlined,
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    context,
                    '$alpa',
                    'Alpa',
                    const Color(0xFFDC2626),
                    Icons.cancel_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tabs ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.gray500,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book, size: 16),
                        const SizedBox(width: 8),
                        Text('Mata Pelajaran (${_groupedMapel.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 16),
                        const SizedBox(width: 8),
                        Text('Riwayat (${_allMeetings.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: _loading
                  ? _buildSkeleton(context)
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        RefreshIndicator(
                          onRefresh: _load,
                          child: _groupedMapel.isEmpty
                              ? ListView(children: [_buildEmpty(context)])
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    100,
                                  ),
                                  itemCount: _groupedMapel.length,
                                  itemBuilder: (ctx, i) {
                                    final key = _groupedMapel.keys.elementAt(i);
                                    return _buildMapelCard(
                                      context,
                                      _groupedMapel[key]!,
                                    );
                                  },
                                ),
                        ),
                        RefreshIndicator(
                          onRefresh: _load,
                          child: _allMeetings.isEmpty
                              ? ListView(children: [_buildEmpty(context)])
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    100,
                                  ),
                                  itemCount: _allMeetings.length,
                                  itemBuilder: (ctx, i) => _buildRiwayatCard(
                                    context,
                                    _allMeetings[i],
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),

        // FAB QR Scanner
        Positioned(
          right: 20,
          bottom: 20,
          child: GestureDetector(
            onTap: () => _openQRScanner(context),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openQRScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: const MobileQRScanner(),
        ),
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapelCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    final mapel = data['mapel'] as String;
    final guru = data['guru'] as String;
    final meetings = data['meetings'] as List<Map<String, dynamic>>;
    final totalHadir = data['totalHadir'] as int;
    final totalAll = data['totalAll'] as int;

    final percentage = totalAll > 0 ? (totalHadir / totalAll) : 0.0;
    final pctString = (percentage * 100).toStringAsFixed(0);

    Color progressColor = AppColors.primary;
    if (percentage < 0.75) progressColor = const Color(0xFFD97706);
    if (percentage < 0.5) progressColor = const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MobileRiwayatMapel(
                  mapel: mapel,
                  guru: guru,
                  meetings: meetings,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _mapelIcon(mapel),
                    size: 24,
                    color: progressColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mapel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: fgColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              guru,
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? AppColors.gray700
                                    : AppColors.gray100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$pctString%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: progressColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right, color: AppColors.gray300, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    final mapel = data['mapel'] as String? ?? '-';
    final pertemuanKe = data['pertemuanKe'] as int? ?? 1;
    final tanggalStr = data['tanggal'] as String? ?? '';
    final status = (data['status'] as String? ?? 'HADIR').toUpperCase();

    // Base color for icon area depending on status
    Color iconBg = const Color(0xFFDCFCE7);
    Color iconColor = const Color(0xFF16A34A);
    if (status == 'SAKIT' || status == 'TERLAMBAT') {
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFB45309);
    } else if (status == 'IZIN') {
      iconBg = const Color(0xFFDBEAFE);
      iconColor = const Color(0xFF1D4ED8);
    } else if (status == 'ALPA') {
      iconBg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFB91C1C);
    }

    // Format date nicely
    String formattedDate = tanggalStr;
    String timeAgo = '';
    try {
      final d = DateTime.parse(tanggalStr).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inDays == 0) {
        timeAgo = 'Hari ini';
      } else if (diff.inDays == 1) {
        timeAgo = 'Kemarin';
      } else if (diff.inDays < 30) {
        timeAgo = '${diff.inDays} hari yang lalu';
      } else if (diff.inDays < 365) {
        timeAgo = '${(diff.inDays / 30).floor()} bulan yang lalu';
      } else {
        timeAgo = '${(diff.inDays / 365).floor()} tahun yang lalu';
      }

      formattedDate =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.qr_code_2, size: 24, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        mapel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: fgColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pertemuan $pertemuanKe',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '-',
                  style: TextStyle(color: AppColors.gray400),
                ), // placeholder
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        timeAgo.isNotEmpty
                            ? '$timeAgo • $formattedDate'
                            : formattedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off, size: 56, color: AppColors.gray300),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat kehadiran',
            style: TextStyle(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: List.generate(
        5,
        (_) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : AppColors.gray100,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
