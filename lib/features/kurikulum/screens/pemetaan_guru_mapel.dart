// File: lib/features/kurikulum/screens/pemetaan_guru_mapel.dart
// ===========================================
// PEMETAAN GURU MAPEL
// CRUD: daftar pemetaan guru ke mata pelajaran
// Form modal sinkron dengan validasi backend
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../shared_widgets/table_pagination.dart';
import '../../../shared_widgets/delete_confirmation_modal.dart';
import '../../../shared_widgets/success_toast.dart';

// ─── Model sederhana ──────────────────────────
class _GuruMapelItem {
  final String id;
  final String teacherId;
  final String teacher;
  final String subjectId;
  final String subject;
  final String classes;
  final int hoursPerWeek;
  final int scheduled;

  const _GuruMapelItem({
    required this.id,
    required this.teacherId,
    required this.teacher,
    required this.subjectId,
    required this.subject,
    required this.classes,
    required this.hoursPerWeek,
    required this.scheduled,
  });

  factory _GuruMapelItem.fromMap(Map<String, dynamic> m) => _GuruMapelItem(
        id: m['id']?.toString() ?? '',
        teacherId: m['teacherId']?.toString() ?? '',
        teacher: m['teacher']?.toString() ?? '',
        subjectId: m['subjectId']?.toString() ?? '',
        subject: m['subject']?.toString() ?? '',
        classes: m['classes']?.toString() ?? '',
        hoursPerWeek: (m['hoursPerWeek'] as num?)?.toInt() ?? 0,
        scheduled: (m['scheduled'] as num?)?.toInt() ?? 0,
      );
}

class _DropdownOption {
  final String id;
  final String label;
  const _DropdownOption(this.id, this.label);
}

// ════════════════════════════════════════════════
// MAIN SCREEN
// ════════════════════════════════════════════════
class PemetaanGuruMapel extends StatefulWidget {
  const PemetaanGuruMapel({super.key});

  @override
  State<PemetaanGuruMapel> createState() => _PemetaanGuruMapelState();
}

class _PemetaanGuruMapelState extends State<PemetaanGuruMapel> {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  String _searchQuery = '';
  bool _loading = true;
  bool _showSuccessToast = false;
  String _successMessage = '';

  List<_GuruMapelItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiService.getGuruMapel(search: _searchQuery);
      final raw = res['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _items = raw.map((e) => _GuruMapelItem.fromMap(Map<String, dynamic>.from(e))).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showToast(String msg) {
    setState(() {
      _successMessage = msg;
      _showSuccessToast = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSuccessToast = false);
    });
  }

  void _openForm({_GuruMapelItem? item}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _GuruMapelFormModal(editItem: item),
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
        _showToast(item == null
            ? 'Pemetaan guru-mapel berhasil ditambahkan'
            : 'Pemetaan guru-mapel berhasil diperbarui');
      }
    });
  }

  void _handleDelete(_GuruMapelItem item) {
    DeleteConfirmationModal.show(
      context,
      title: 'Hapus Pemetaan',
      message: 'Pemetaan ini akan dihapus permanen. Jadwal terkait mungkin terpengaruh.',
      itemName: '${item.teacher} → ${item.subject}',
      onConfirm: () async {
        try {
          await ApiService.deleteGuruMapel(item.id);
          _loadData();
          _showToast('Pemetaan "${item.teacher} → ${item.subject}" berhasil dihapus');
        } catch (_) {}
      },
    );
  }

  List<_GuruMapelItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items
        .where((i) =>
            i.teacher.toLowerCase().contains(q) ||
            i.subject.toLowerCase().contains(q) ||
            i.classes.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final filtered = _filteredItems;
    final total = filtered.length;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, total);
    final pageData = filtered.sublist(start, end);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            const Text(
              'Pemetaan Guru - Mata Pelajaran',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola penugasan guru ke mata pelajaran yang diampu',
              style: TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 32),

            // ── Action Bar ──
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: TextField(
                      onChanged: (v) => setState(() {
                        _searchQuery = v;
                        _currentPage = 1;
                      }),
                      decoration: InputDecoration(
                        hintText: 'Cari guru, mata pelajaran, atau kelas...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gray300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gray300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
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

            // ── Table ──
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Header row
                    Container(
                      color: AppColors.gray50,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _ColHeader('Nama Guru')),
                          Expanded(flex: 3, child: _ColHeader('Mata Pelajaran')),
                          Expanded(flex: 3, child: _ColHeader('Kelas Diampu')),
                          Expanded(flex: 1, child: _ColHeader('Jam/Mgg')),
                          Expanded(flex: 1, child: _ColHeader('Terjadwal')),
                          SizedBox(width: 80, child: _ColHeader('Aksi')),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.gray200),

                    // Rows
                    Expanded(
                      child: pageData.isEmpty
                          ? _buildEmpty()
                          : ListView.separated(
                              itemCount: pageData.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: AppColors.gray200),
                              itemBuilder: (_, i) => _buildRow(pageData[i]),
                            ),
                    ),

                    TablePagination(
                      currentPage: _currentPage,
                      totalItems: total,
                      itemsPerPage: _itemsPerPage,
                      onPageChange: (p) => setState(() => _currentPage = p),
                      onItemsPerPageChange: (n) =>
                          setState(() {
                            _itemsPerPage = n;
                            _currentPage = 1;
                          }),
                      itemName: 'pemetaan',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (_showSuccessToast)
          Positioned(
            top: 16,
            right: 16,
            child: SuccessToast(
              isVisible: true,
              message: _successMessage,
              onClose: () => setState(() => _showSuccessToast = false),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(_GuruMapelItem item) {
    final isOver = item.scheduled > item.hoursPerWeek && item.hoursPerWeek > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Text(
                    item.teacher.isNotEmpty ? item.teacher[0].toUpperCase() : 'G',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(item.teacher,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(item.subject,
                style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 3,
            child: item.classes.isEmpty
                ? const Text('-', style: TextStyle(fontSize: 14, color: AppColors.gray400))
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: item.classes
                        .split(',')
                        .map((c) => c.trim())
                        .where((c) => c.isNotEmpty)
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(999)),
                              child: Text(c,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF16A34A))),
                            ))
                        .toList(),
                  ),
          ),
          Expanded(
            flex: 1,
            child: Text('${item.hoursPerWeek} jam',
                style: const TextStyle(fontSize: 14, color: AppColors.foreground)),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOver ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.scheduled}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOver ? const Color(0xFFDC2626) : AppColors.gray600,
                    ),
                  ),
                ),
                if (isOver) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600),
                  onPressed: () => _openForm(item: item),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600),
                  onPressed: () => _handleDelete(item),
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty ? 'Belum ada pemetaan guru' : 'Tidak ada hasil pencarian',
              style: const TextStyle(color: AppColors.gray500, fontSize: 14),
            ),
          ],
        ),
      );
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground));
}

// ════════════════════════════════════════════════
// FORM MODAL — sinkron dengan validasi backend
//   Backend rules:
//   - teacherId  : wajib (requireFields)
//   - subjectId  : wajib (requireFields)
//   - hoursPerWeek: 0–50 (guruMapelController)
//   - kombinasi guru+mapel harus unik (P2002)
// ════════════════════════════════════════════════
class _GuruMapelFormModal extends StatefulWidget {
  final _GuruMapelItem? editItem;
  const _GuruMapelFormModal({this.editItem});

  @override
  State<_GuruMapelFormModal> createState() => _GuruMapelFormModalState();
}

class _GuruMapelFormModalState extends State<_GuruMapelFormModal> {
  bool _loadingOptions = true;
  bool _saving = false;

  List<_DropdownOption> _guruOptions = [];
  List<_DropdownOption> _mapelOptions = [];

  String? _selectedGuruId;
  String? _selectedMapelId;
  String? _guruError;
  String? _mapelError;
  String? _hoursError;

  late final TextEditingController _classesCtrl;
  late final TextEditingController _hoursCtrl;

  @override
  void initState() {
    super.initState();
    _classesCtrl = TextEditingController(text: widget.editItem?.classes ?? '');
    _hoursCtrl =
        TextEditingController(text: (widget.editItem?.hoursPerWeek ?? 0).toString());
    _selectedGuruId = widget.editItem?.teacherId;
    _selectedMapelId = widget.editItem?.subjectId;
    _loadOptions();
  }

  @override
  void dispose() {
    _classesCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final res = await ApiService.getGuruMapelOptions();
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final guruList = data['guru'] as List? ?? [];
      final mapelList = data['mapel'] as List? ?? [];

      if (mounted) {
        setState(() {
          _guruOptions = guruList
              .map((g) => _DropdownOption(
                    g['id']?.toString() ?? '',
                    g['nip'] != null && g['nip'].toString().isNotEmpty
                        ? '${g['name']} (${g['nip']})'
                        : g['name']?.toString() ?? '',
                  ))
              .toList();

          _mapelOptions = mapelList
              .map((m) => _DropdownOption(
                    m['id']?.toString() ?? '',
                    '[${m['code']}] ${m['name']}',
                  ))
              .toList();

          _loadingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingOptions = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat opsi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── CLIENT-SIDE VALIDATION (mirrors backend rules) ──
  bool _validate() {
    bool ok = true;
    setState(() {
      _guruError = null;
      _mapelError = null;
      _hoursError = null;

      // Rule 1 — wajib diisi
      if (_selectedGuruId == null || _selectedGuruId!.isEmpty) {
        _guruError = 'Pilih guru terlebih dahulu';
        ok = false;
      }
      if (_selectedMapelId == null || _selectedMapelId!.isEmpty) {
        _mapelError = 'Pilih mata pelajaran terlebih dahulu';
        ok = false;
      }

      // Rule 2 — jam per minggu 0–50
      final hours = int.tryParse(_hoursCtrl.text.trim());
      if (_hoursCtrl.text.trim().isNotEmpty) {
        if (hours == null || hours < 0 || hours > 50) {
          _hoursError = 'Jam per minggu harus antara 0 – 50';
          ok = false;
        }
      }
    });
    return ok;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _saving = true);

    final payload = {
      'teacherId': _selectedGuruId,
      'subjectId': _selectedMapelId,
      'classes': _classesCtrl.text.trim(),
      'hoursPerWeek': int.tryParse(_hoursCtrl.text.trim()) ?? 0,
    };

    try {
      if (widget.editItem != null) {
        await ApiService.updateGuruMapel(widget.editItem!.id, payload);
      } else {
        await ApiService.createGuruMapel(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        String msg = 'Terjadi kesalahan. Silakan coba lagi.';
        if (e is DioException && e.response?.data != null) {
          msg = e.response!.data['message']?.toString() ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_ind_outlined,
                    color: Color(0xFF1D4ED8), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.editItem == null
                      ? 'Tambah Pemetaan Guru - Mapel'
                      : 'Edit Pemetaan Guru - Mapel',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Semua field bertanda * wajib diisi',
            style: TextStyle(fontSize: 12, color: AppColors.gray400),
          ),
          const SizedBox(height: 24),

          if (_loadingOptions)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else ...[
            // ── Guru Dropdown * ──
            _buildLabel('Guru *'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedGuruId,
              isExpanded: true,
              decoration: _inputDeco('Pilih guru', errorText: _guruError),
              items: _guruOptions
                  .map((o) => DropdownMenuItem(value: o.id, child: Text(o.label, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedGuruId = v;
                _guruError = null;
              }),
            ),
            const SizedBox(height: 16),

            // ── Mata Pelajaran Dropdown * ──
            _buildLabel('Mata Pelajaran *'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedMapelId,
              isExpanded: true,
              decoration: _inputDeco('Pilih mata pelajaran', errorText: _mapelError),
              items: _mapelOptions
                  .map((o) => DropdownMenuItem(value: o.id, child: Text(o.label, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedMapelId = v;
                _mapelError = null;
              }),
            ),
            const SizedBox(height: 16),

            // ── Kelas Diampu ──
            _buildLabel('Kelas Diampu'),
            const SizedBox(height: 6),
            TextField(
              controller: _classesCtrl,
              decoration: _inputDeco('Contoh: X IPA 1, X IPA 2, XI IPA 1'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pisahkan nama kelas dengan koma',
              style: TextStyle(fontSize: 11, color: AppColors.gray400),
            ),
            const SizedBox(height: 16),

            // ── Jam Per Minggu ──
            _buildLabel('Jam Per Minggu'),
            const SizedBox(height: 6),
            TextField(
              controller: _hoursCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _hoursError = null),
              decoration: _inputDeco('0 – 50', errorText: _hoursError),
            ),
            const SizedBox(height: 6),
            const Text(
              'Jumlah jam mengajar per minggu (maksimal 50 jam)',
              style: TextStyle(fontSize: 11, color: AppColors.gray400),
            ),
            const SizedBox(height: 28),

            // ── Actions ──
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
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.editItem == null ? 'Simpan Pemetaan' : 'Simpan Perubahan'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground),
      );

  InputDecoration _inputDeco(String hint, {String? errorText}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray400),
        filled: true,
        fillColor: AppColors.gray50,
        errorText: errorText,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gray300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gray300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
}
