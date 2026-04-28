// lib/features/kurikulum/screens/jadwal_pelajaran.dart
// Jadwal Pelajaran — full API-backed CRUD
// Tab 1: Pemetaan Guru-Mapel | Tab 2: Jadwal Per Kelas (grid)
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../shared_widgets/table_pagination.dart';
import '../../../shared_widgets/delete_confirmation_modal.dart';
import '../../../shared_widgets/success_toast.dart';
import 'jadwal_form_modals.dart';

// ═══════════════════════════════════════════════
// MAIN WIDGET
// ═══════════════════════════════════════════════
class JadwalPelajaran extends StatefulWidget {
  const JadwalPelajaran({super.key});
  @override
  State<JadwalPelajaran> createState() => _JadwalPelajaranState();
}

class _JadwalPelajaranState extends State<JadwalPelajaran> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSuccessToast = false;
  String _successMessage = '';
  List<Map<String, dynamic>> _kelasList = [];
  String? _selectedKelasId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadKelas();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadKelas() async {
    try {
      final res = await ApiService.getMasterKelas();
      final list = ((res['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() {
        _kelasList = list;
        if (_selectedKelasId == null && list.isNotEmpty) _selectedKelasId = list.first['id'] as String;
      });
    } catch (_) {}
  }

  void _showSuccess(String msg) {
    setState(() { _successMessage = msg; _showSuccessToast = true; });
    Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _showSuccessToast = false); });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Jadwal Pelajaran', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 8),
        const Text('Kelola pemetaan guru ke mata pelajaran dan susun jadwal mingguan per kelas', style: TextStyle(color: AppColors.gray600)),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))]),
          padding: const EdgeInsets.all(8),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            labelColor: Colors.white, unselectedLabelColor: AppColors.gray600,
            indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
            tabs: const [Tab(text: 'Pemetaan Guru-Mapel'), Tab(text: 'Jadwal Per Kelas')],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(child: TabBarView(controller: _tabController, children: [
          _TeacherSubjectMapping(onSuccess: _showSuccess),
          _WeeklyScheduleGrid(kelasList: _kelasList, selectedKelasId: _selectedKelasId,
            onKelasChanged: (id) => setState(() => _selectedKelasId = id), onSuccess: _showSuccess),
        ])),
      ]),
      if (_showSuccessToast)
        Positioned(top: 16, right: 16, child: SuccessToast(
          isVisible: true, message: _successMessage,
          onClose: () => setState(() => _showSuccessToast = false))),
    ]);
  }
}

// ═══════════════════════════════════════════════
// TAB 1: PEMETAAN GURU-MAPEL
// ═══════════════════════════════════════════════
class _TeacherSubjectMapping extends StatefulWidget {
  final void Function(String) onSuccess;
  const _TeacherSubjectMapping({required this.onSuccess});
  @override
  State<_TeacherSubjectMapping> createState() => _TeacherSubjectMappingState();
}

class _TeacherSubjectMappingState extends State<_TeacherSubjectMapping> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _list = [], _filtered = [];
  bool _loading = true;
  int _page = 1, _perPage = 10;
  final _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); _searchCtrl.addListener(_filter); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getGuruMapel(search: _searchCtrl.text);
      final data = ((res['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _list = data; _filter(); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? List.from(_list) : _list.where((m) =>
        (m['teacher'] ?? '').toString().toLowerCase().contains(q) ||
        (m['subject'] ?? '').toString().toLowerCase().contains(q)).toList();
      _page = 1;
    });
  }

  void _openModal({Map<String, dynamic>? data}) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: GuruMapelFormModal(initialData: data))),
    ).then((r) { if (r == true) { widget.onSuccess(data != null ? 'Pemetaan berhasil diperbarui' : 'Pemetaan berhasil ditambahkan'); _load(); }});
  }

  void _delete(Map<String, dynamic> item) {
    DeleteConfirmationModal.show(context,
      title: 'Hapus Pemetaan Guru',
      message: 'Apakah Anda yakin ingin menghapus pemetaan ini?',
      itemName: '${item['teacher']} - ${item['subject']}',
      onConfirm: () async {
        await ApiService.deleteGuruMapel(item['id']);
        widget.onSuccess('Pemetaan berhasil dihapus');
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final total = _filtered.length;
    final start = (_page - 1) * _perPage;
    final end = (start + _perPage).clamp(0, total);
    final pageData = total > 0 ? _filtered.sublist(start, end) : <Map<String, dynamic>>[];
    return Column(children: [
      Row(children: [
        Expanded(child: TextField(controller: _searchCtrl,
          decoration: InputDecoration(hintText: 'Cari guru atau mapel...', prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14)),
        )),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _openModal(),
          icon: const Icon(Icons.add, size: 20), label: const Text('Tambah Pemetaan'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
      const SizedBox(height: 24),
      Expanded(child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))]),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            color: AppColors.gray50,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: const Row(children: [
              Expanded(flex: 3, child: Text('Nama Guru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(flex: 3, child: Text('Mata Pelajaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(flex: 3, child: Text('Kelas Diampu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(flex: 1, child: Text('Kuota', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(flex: 2, child: Text('Terjadwal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              SizedBox(width: 80, child: Text('Aksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
            ]),
          ),
          const Divider(height: 1, color: AppColors.gray200),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : pageData.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.group_off_outlined, size: 48, color: AppColors.gray300),
                  SizedBox(height: 12),
                  Text('Belum ada pemetaan guru', style: TextStyle(color: AppColors.gray500)),
                ]))
              : ListView.separated(
                  itemCount: pageData.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
                  itemBuilder: (_, i) {
                    final m = pageData[i];
                    final scheduled = (m['scheduled'] as num?)?.toInt() ?? 0;
                    final quota = (m['hoursPerWeek'] as num?)?.toInt() ?? 0;
                    final isFull = scheduled >= quota && quota > 0;
                    final isOver = scheduled > quota && quota > 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(m['teacher'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground))),
                        Expanded(flex: 3, child: Text(m['subject'] ?? '-', style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                        Expanded(flex: 3, child: Text(m['classes'] ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.gray600))),
                        Expanded(flex: 1, child: Text('${quota > 0 ? quota : '-'} jp', style: const TextStyle(fontSize: 14))),
                        Expanded(flex: 2, child: Row(children: [
                          Text('$scheduled${quota > 0 ? " / $quota" : ""}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: isOver ? const Color(0xFFDC2626) : isFull ? const Color(0xFF16A34A) : AppColors.foreground)),
                          if (isFull) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: isOver ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(999)),
                              child: Text(isOver ? 'Melebihi!' : 'Penuh',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isOver ? const Color(0xFFDC2626) : const Color(0xFF16A34A))),
                            ),
                          ],
                        ])),
                        SizedBox(width: 80, child: Row(children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () => _openModal(data: m), tooltip: 'Edit'),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600), onPressed: () => _delete(m), tooltip: 'Hapus'),
                        ])),
                      ]),
                    );
                  },
                )
          ),
          TablePagination(currentPage: _page, totalItems: total, itemsPerPage: _perPage,
            onPageChange: (p) => setState(() => _page = p),
            onItemsPerPageChange: (n) => setState(() { _perPage = n; _page = 1; }),
            itemName: 'pemetaan'),
        ]),
      )),
    ]);
  }
}

// ═══════════════════════════════════════════════
// TAB 2: JADWAL PER KELAS (GRID)
// ═══════════════════════════════════════════════
class _WeeklyScheduleGrid extends StatefulWidget {
  final List<Map<String, dynamic>> kelasList;
  final String? selectedKelasId;
  final ValueChanged<String?> onKelasChanged;
  final void Function(String) onSuccess;
  const _WeeklyScheduleGrid({required this.kelasList, required this.selectedKelasId, required this.onKelasChanged, required this.onSuccess});
  @override
  State<_WeeklyScheduleGrid> createState() => _WeeklyScheduleGridState();
}

class _WeeklyScheduleGridState extends State<_WeeklyScheduleGrid> with AutomaticKeepAliveClientMixin {
  Map<String, Map<String, dynamic>> _schedule = {}; // key = 'slotIdx_dayIdx'
  bool _loading = false;
  String? _activeKelasId;

  static const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
  static const _timeSlots = [
    {'slot': '0', 'time': '07:00\n07:45'}, {'slot': '1', 'time': '07:45\n08:30'},
    {'slot': '2', 'time': '08:30\n09:15'}, {'slot': '3', 'time': '09:30\n10:15'},
    {'slot': '4', 'time': '10:15\n11:00'}, {'slot': '5', 'time': '11:00\n11:45'},
    {'slot': '6', 'time': '13:00\n13:45'}, {'slot': '7', 'time': '13:45\n14:30'},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _activeKelasId = widget.selectedKelasId; if (_activeKelasId != null) _loadJadwal(); }

  @override
  void didUpdateWidget(_WeeklyScheduleGrid old) {
    super.didUpdateWidget(old);
    if (widget.selectedKelasId != _activeKelasId) { _activeKelasId = widget.selectedKelasId; _loadJadwal(); }
  }

  Future<void> _loadJadwal() async {
    if (_activeKelasId == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.getJadwal(kelasId: _activeKelasId);
      final list = ((res['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      final dayMap = {'Senin': 0, 'Selasa': 1, 'Rabu': 2, 'Kamis': 3, 'Jumat': 4};
      final sched = <String, Map<String, dynamic>>{};
      for (final j in list) {
        final day = j['day'] ?? j['hari'] ?? 'Senin';
        final slot = (j['slotIndex'] as num?)?.toInt() ?? 0;
        sched['${slot}_${dayMap[day] ?? 0}'] = j;
      }
      if (mounted) setState(() { _schedule = sched; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _openAddModal() {
    if (_activeKelasId == null || widget.kelasList.isEmpty) return;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
          child: ScheduleFormModal(kelasId: _activeKelasId!, kelasList: widget.kelasList))),
    ).then((r) { if (r == true) { widget.onSuccess('Jadwal berhasil ditambahkan'); _loadJadwal(); }});
  }

  void _openEditModal(Map<String, dynamic> entry) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
          child: ScheduleFormModal(kelasId: _activeKelasId!, kelasList: widget.kelasList, initialData: entry, isEdit: true))),
    ).then((r) { if (r == true) { widget.onSuccess('Jadwal berhasil diperbarui'); _loadJadwal(); }});
  }

  void _delete(Map<String, dynamic> entry) {
    DeleteConfirmationModal.show(context,
      title: 'Hapus Jadwal', message: 'Apakah Anda yakin ingin menghapus jadwal ini?',
      itemName: '${entry['subject']} - ${entry['teacher']}',
      onConfirm: () async { await ApiService.deleteJadwal(entry['id']); widget.onSuccess('Jadwal berhasil dihapus'); _loadJadwal(); });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(
          value: widget.selectedKelasId,
          items: widget.kelasList.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] ?? e['nama'] ?? ''))).toList(),
          onChanged: (v) { widget.onKelasChanged(v); _activeKelasId = v; _loadJadwal(); },
          decoration: InputDecoration(labelText: 'Pilih Kelas', filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        )),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _openAddModal,
          icon: const Icon(Icons.add, size: 20), label: const Text('Tambah Jadwal'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
      const SizedBox(height: 24),
      Expanded(child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))]),
        clipBehavior: Clip.antiAlias,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(child: Column(children: [
                // Header row
                Container(color: AppColors.gray50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    const SizedBox(width: 80, child: Text('Jam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                    ..._days.map((d) => SizedBox(width: 160, child: Center(child: Text(d, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground))))),
                  ]),
                ),
                const Divider(height: 1, color: AppColors.gray200),
                // Time slots
                ..._timeSlots.map((slot) => Container(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray100))),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 80, child: Text(slot['time']!, style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontWeight: FontWeight.w500))),
                    ...List.generate(5, (dayIdx) {
                      final key = '${slot['slot']}_$dayIdx';
                      final entry = _schedule[key];
                      return SizedBox(width: 160, child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: entry != null
                          ? _ScheduleCard(entry: entry, onEdit: () => _openEditModal(entry), onDelete: () => _delete(entry))
                          : const SizedBox(height: 60),
                      ));
                    }),
                  ]),
                )),
              ])),
            )),
      )),
    ]);
  }
}

// ═══════════════════════════════════════════════
// SCHEDULE CARD (read-only display with actions)
// ═══════════════════════════════════════════════
class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ScheduleCard({required this.entry, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showMenu(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: Text(entry['subject'] ?? '-',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.more_vert, size: 14, color: AppColors.gray400),
            ]),
            const SizedBox(height: 2),
            Text(entry['teacher'] ?? '-', style: const TextStyle(fontSize: 10, color: AppColors.gray600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${entry['startTime'] ?? ''} - ${entry['endTime'] ?? ''}', style: const TextStyle(fontSize: 10, color: AppColors.gray500, fontWeight: FontWeight.w500)),
            if ((entry['room'] ?? '-') != '-')
              Text('📍 ${entry['room']}', style: const TextStyle(fontSize: 10, color: AppColors.gray500)),
          ]),
        ),
      ),
    );
  }

  void _showMenu(BuildContext ctx) {
    // Store navigator before async gap to avoid deactivated widget error
    final nav = Navigator.of(ctx);
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.schedule, color: AppColors.primary, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry['subject'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
              Text('${entry['teacher'] ?? '-'} • ${entry['startTime'] ?? ''}-${entry['endTime'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
            ])),
          ]),
        ),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
          title: const Text('Edit Jadwal', style: TextStyle(fontSize: 14)),
          onTap: () { nav.pop(); onEdit(); }),
        ListTile(leading: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
          title: const Text('Hapus Jadwal', style: TextStyle(fontSize: 14, color: Color(0xFFDC2626))),
          onTap: () { nav.pop(); onDelete(); }),
      ]),
    ));
  }
}
