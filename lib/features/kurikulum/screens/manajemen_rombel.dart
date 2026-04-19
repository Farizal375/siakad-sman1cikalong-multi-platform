// File: lib/features/kurikulum/screens/manajemen_rombel.dart
// ===========================================
// MANAJEMEN ROMBEL (Class Group Management)
// Connected to /rombel API endpoints
// Dual-pane transfer list + config card
// ===========================================

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../shared_widgets/success_toast.dart';
import '../../../shared_widgets/delete_confirmation_modal.dart';

class ManajemenRombel extends StatefulWidget {
  const ManajemenRombel({super.key});

  @override
  State<ManajemenRombel> createState() => _ManajemenRombelState();
}

class _ManajemenRombelState extends State<ManajemenRombel> {
  String? _selectedRombelId;
  String _leftSearch = '';
  String _rightSearch = '';
  bool _showSuccessToast = false;
  String _successMessage = '';
  bool _loading = true;
  bool _loadingStudents = false;

  // Rombel list from API
  List<Map<String, dynamic>> _rombelList = [];

  // All available students (not in this rombel)
  List<Map<String, dynamic>> _availableStudents = [];

  // Students currently assigned to the selected rombel
  List<Map<String, dynamic>> _assignedStudents = [];

  // Selected checkboxes on the left
  final Set<String> _leftSelected = {};

  @override
  void initState() {
    super.initState();
    _loadRombelList();
  }

  Future<void> _loadRombelList() async {
    try {
      final response = await ApiService.getRombel();
      final items = response['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _rombelList = items.map<Map<String, dynamic>>((item) => ({
            'id': item['id'] ?? '',
            'name': item['masterKelasName'] ?? '',
            'tahunAjaran': item['tahunAjaranCode'] ?? '',
            'ruangKelasId': item['ruangKelasId'] ?? '',
            'ruangKelasCode': item['ruangKelasCode'] ?? '-',
            'ruangKelasCapacity': item['ruangKelasCapacity'] ?? 0,
            'waliKelas': item['waliKelasName'] ?? '-',
            'totalSiswa': item['siswaCount'] ?? 0,
          })).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRombelModal({bool isEdit = false, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _RombelFormModal(isEdit: isEdit, initialData: data),
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadRombelList();
        setState(() {
          _successMessage = isEdit ? 'Rombel berhasil diperbarui' : 'Rombel baru berhasil ditambahkan';
          _showSuccessToast = true;
          if (!isEdit) _selectedRombelId = null;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showSuccessToast = false);
        });
      }
    });
  }

  void _deleteRombel() {
    if (_selectedRombelId == null) return;
    final r = _rombelList.firstWhere((x) => x['id'] == _selectedRombelId);
    DeleteConfirmationModal.show(
      context,
      title: 'Hapus Rombongan Belajar',
      message: 'Apakah Anda yakin ingin menghapus rombongan belajar ini? Aksi ini akan menghapus semua pemetaan siswa di dalamnya secara permanen.',
      itemName: '${r['name']} • ${r['tahunAjaran']}',
      onConfirm: () async {
        try {
          await ApiService.deleteRombel(_selectedRombelId!);
          setState(() {
            _selectedRombelId = null;
            _assignedStudents.clear();
            _availableStudents.clear();
            _successMessage = 'Rombel berhasil dihapus';
            _showSuccessToast = true;
          });
          _loadRombelList();
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showSuccessToast = false);
          });
        } catch (_) {}
      },
    );
  }

  Future<void> _loadStudentsForRombel(String rombelId) async {
    setState(() => _loadingStudents = true);
    try {
      // Load assigned students
      final assignedRes = await ApiService.getRombelSiswa(rombelId);
      final assignedItems = assignedRes['data'] as List? ?? [];

      // Load available students
      final availableRes = await ApiService.getAvailableSiswa(rombelId);
      final availableItems = availableRes['data'] as List? ?? [];

      if (mounted) {
        setState(() {
          _assignedStudents = assignedItems.map<Map<String, dynamic>>((s) => ({
            'id': s['id'] ?? '',
            'name': s['name'] ?? '',
            'nisn': s['nisn'] ?? '-',
          })).toList();

          _availableStudents = availableItems.map<Map<String, dynamic>>((s) => ({
            'id': s['id'] ?? '',
            'name': s['name'] ?? '',
            'nisn': s['nisn'] ?? '-',
          })).toList();

          _leftSelected.clear();
          _loadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAvailable {
    var list = _availableStudents;
    if (_leftSearch.isNotEmpty) {
      final q = _leftSearch.toLowerCase();
      list = list.where((s) => (s['name'] ?? '').toLowerCase().contains(q) || (s['nisn'] ?? '').contains(q)).toList();
    }
    return list;
  }

  List<Map<String, dynamic>> get _filteredAssigned {
    if (_rightSearch.isEmpty) return _assignedStudents;
    final q = _rightSearch.toLowerCase();
    return _assignedStudents.where((s) => (s['name'] ?? '').toLowerCase().contains(q) || (s['nisn'] ?? '').contains(q)).toList();
  }

  Future<void> _addSelected() async {
    if (_selectedRombelId == null) return;
    final rombel = _rombelList.firstWhere((r) => r['id'] == _selectedRombelId);
    final capacity = rombel['ruangKelasCapacity'] as int;
    final ids = _leftSelected.toList();

    if (_assignedStudents.length + ids.length > capacity) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kapasitas Ruang ${rombel['ruangKelasCode']} tidak mencukupi (Max: $capacity). Anda mencoba memasukkan ${ids.length} siswa, sisa kursi: ${capacity - _assignedStudents.length}.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      await ApiService.assignSiswa(_selectedRombelId!, ids);
      _loadStudentsForRombel(_selectedRombelId!);
      setState(() {
        _successMessage = '${ids.length} siswa berhasil ditambahkan';
        _showSuccessToast = true;
      });
    } catch (_) {}
  }

  Future<void> _addAll() async {
    if (_selectedRombelId == null) return;
    final rombel = _rombelList.firstWhere((r) => r['id'] == _selectedRombelId);
    final capacity = rombel['ruangKelasCapacity'] as int;
    final ids = _filteredAvailable.map<String>((s) => s['id'] as String).toList();

    if (_assignedStudents.length + ids.length > capacity) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kapasitas Ruang ${rombel['ruangKelasCode']} tidak mencukupi (Max: $capacity) untuk memasukkan keseluruhan bagian ini.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      await ApiService.assignSiswa(_selectedRombelId!, ids);
      _loadStudentsForRombel(_selectedRombelId!);
      setState(() {
        _successMessage = 'Semua siswa berhasil ditambahkan';
        _showSuccessToast = true;
      });
    } catch (_) {}
  }

  Future<void> _removeStudent(String id) async {
    if (_selectedRombelId == null) return;
    try {
      await ApiService.removeSiswaFromRombel(_selectedRombelId!, id);
      _loadStudentsForRombel(_selectedRombelId!);
    } catch (_) {}
  }

  void _removeAll() {
    setState(() {
      _assignedStudents.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Title ──
            const Text(
              'Manajemen Rombongan Belajar',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola pemetaan siswa ke dalam rombongan belajar',
              style: TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 32),

            // ── Rombel Selector ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedRombelId,
                            items: _rombelList.map((r) => DropdownMenuItem(
                              value: r['id'] as String,
                              child: Text('${r['name']} • ${r['tahunAjaran']}', style: const TextStyle(fontSize: 14)),
                            )).toList(),
                            onChanged: (v) {
                              setState(() => _selectedRombelId = v);
                              if (v != null) _loadStudentsForRombel(v);
                            },
                            decoration: InputDecoration(
                              labelText: 'Pilih Rombel',
                              labelStyle: const TextStyle(fontSize: 14, color: AppColors.gray600),
                              filled: true, fillColor: AppColors.gray50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedRombelId != null) ...[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                            tooltip: 'Edit Rombel',
                            onPressed: () {
                              final data = _rombelList.firstWhere((x) => x['id'] == _selectedRombelId);
                              _showRombelModal(isEdit: true, data: data);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Hapus Rombel',
                            onPressed: _deleteRombel,
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () => _showRombelModal(),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Tambah Rombel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_selectedRombelId != null) ...[
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('${_assignedStudents.length} siswa', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Dual-Pane Transfer List ──
            if (_selectedRombelId == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.class_outlined, size: 64, color: AppColors.gray300),
                      const SizedBox(height: 16),
                      const Text('Pilih rombel terlebih dahulu', style: TextStyle(color: AppColors.gray500, fontSize: 16)),
                    ],
                  ),
                ),
              )
            else if (_loadingStudents)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: Row(
                  children: [
                    // Left — Available Students
                    Expanded(child: _buildAvailablePane()),

                    // Center — Transfer Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Builder(
                            builder: (context) {
                              final r = _rombelList.firstWhere((x) => x['id'] == _selectedRombelId);
                              final maxCap = r['ruangKelasCapacity'] as int;
                              final isFull = _assignedStudents.length >= maxCap;
                              // Tombol panah Kanan otomatis mati (abu-abu) jika Rombel penuh
                              return Column(
                                children: [
                                  _TransferButton(
                                    icon: Icons.keyboard_double_arrow_right,
                                    tooltip: 'Tambahkan semua',
                                    onPressed: (!isFull && _filteredAvailable.isNotEmpty) ? _addAll : null,
                                  ),
                                  const SizedBox(height: 8),
                                  _TransferButton(
                                    icon: Icons.chevron_right,
                                    tooltip: 'Tambahkan terpilih',
                                    onPressed: (!isFull && _leftSelected.isNotEmpty) ? _addSelected : null,
                                  ),
                                  const SizedBox(height: 8),
                                  _TransferButton(
                                    icon: Icons.keyboard_double_arrow_left,
                                    tooltip: 'Keluarkan semua (Bisa juga klik item X di kanan)',
                                    onPressed: _assignedStudents.isNotEmpty ? _removeAll : null,
                                  ),
                                ],
                              );
                            }
                          ),
                        ],
                      ),
                    ),

                    // Right — Assigned Students
                    Expanded(child: _buildAssignedPane()),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Capacity Info ──
            if (_selectedRombelId != null)
              Builder(
                builder: (context) {
                  final r = _rombelList.firstWhere((x) => x['id'] == _selectedRombelId);
                  final capacity = r['ruangKelasCapacity'] as int;
                  final current = _assignedStudents.length;
                  final ratio = capacity > 0 ? (current / capacity) : 1.0;
                  final color = ratio >= 1.0 ? const Color(0xFFB91C1C) : (ratio > 0.8 ? const Color(0xFFD97706) : const Color(0xFF16A34A));

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Kapasitas Ruang ${r['ruangKelasCode']}: $current / $capacity Siswa',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 8,
                              backgroundColor: AppColors.gray200,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
          ],
        ),

        if (_showSuccessToast)
          Positioned(
            top: 16, right: 16,
            child: SuccessToast(
              isVisible: true,
              message: _successMessage,
              onClose: () => setState(() => _showSuccessToast = false),
            ),
          ),
      ],
    );
  }

  // ── Available Students Pane ──
  Widget _buildAvailablePane() {
    final list = _filteredAvailable;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text('Daftar Siswa Tersedia (${list.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _leftSearch = v),
                  decoration: InputDecoration(
                    hintText: 'Cari siswa...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.gray400),
                    isDense: true,
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
              ? const Center(child: Text('Tidak ada siswa tersedia', style: TextStyle(color: AppColors.gray500)))
              : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final s = list[i];
                  final id = s['id'] as String;
                  final selected = _leftSelected.contains(id);
                  return ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: selected,
                      onChanged: (v) => setState(() {
                        if (v == true) { _leftSelected.add(id); } else { _leftSelected.remove(id); }
                      }),
                      activeColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    title: Text(s['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text('NISN: ${s['nisn'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                    trailing: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.gray200,
                      child: Text((s['name'] ?? '?')[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600)),
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }

  // ── Assigned Students Pane ──
  Widget _buildAssignedPane() {
    final list = _filteredAssigned;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text('Siswa di Rombel Ini (${_assignedStudents.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _rightSearch = v),
                  decoration: InputDecoration(
                    hintText: 'Cari siswa...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.gray400),
                    isDense: true,
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: AppColors.gray300),
                        SizedBox(height: 8),
                        Text('Belum ada siswa dipetakan', style: TextStyle(color: AppColors.gray500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final s = list[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text((s['name'] ?? '?')[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                        title: Text(s['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text('NISN: ${s['nisn'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.gray400),
                          onPressed: () => _removeStudent(s['id'] as String),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// TRANSFER BUTTON
// ═══════════════════════════════════════════════
class _TransferButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _TransferButton({required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onPressed != null ? AppColors.primary : AppColors.gray200,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: onPressed != null ? Colors.white : AppColors.gray400,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ROMBEL FORM MODAL
// ═══════════════════════════════════════════════
class _RombelFormModal extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  const _RombelFormModal({this.isEdit = false, this.initialData});

  @override
  State<_RombelFormModal> createState() => _RombelFormModalState();
}

class _RombelFormModalState extends State<_RombelFormModal> {
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _masterKelasList = [];
  List<Map<String, dynamic>> _ruangKelasList = [];
  List<Map<String, dynamic>> _guruList = [];

  String? _selectedMasterKelasId;
  String? _selectedRuangKelasId;
  String? _selectedWaliKelasId;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final resKelas = await ApiService.getMasterKelas();
      final resRuang = await ApiService.getRuangKelas();
      final currentRId = widget.initialData != null ? widget.initialData!['id'] : null;
      final resGuru = await ApiService.getAvailableWali(currentRombelId: currentRId); 

      if (mounted) {
        setState(() {
          _masterKelasList = (resKelas['data'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
          _ruangKelasList = (resRuang['data'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
          _guruList = (resGuru['data'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

          if (widget.isEdit && widget.initialData != null) {
            _selectedMasterKelasId = widget.initialData!['masterKelasId'];
            _selectedRuangKelasId = widget.initialData!['ruangKelasId'];
            _selectedWaliKelasId = widget.initialData!['waliKelasId'];
            // Since we receive '-' from backend if null
            if (_selectedWaliKelasId == '-' || _selectedWaliKelasId == '') _selectedWaliKelasId = null;
            if (_selectedRuangKelasId == '-' || _selectedRuangKelasId == '') _selectedRuangKelasId = null;
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!widget.isEdit && (_selectedMasterKelasId == null || _selectedRuangKelasId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelas dan Ruangan wajib diisi!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _saving = true);
    final payload = {
      if (!widget.isEdit) 'masterKelasId': _selectedMasterKelasId,
      if (!widget.isEdit) 'ruangKelasId': _selectedRuangKelasId,
      if (widget.isEdit && _selectedRuangKelasId != null) 'ruangKelasId': _selectedRuangKelasId, // We allow changing Ruangan in edit just in case, but backend currently supports it
      'waliKelasId': _selectedWaliKelasId,
    };

    try {
      if (widget.isEdit && widget.initialData != null) {
        await ApiService.updateRombel(widget.initialData!['id'], payload);
      } else {
        await ApiService.createRombel(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        String msg = 'Terjadi kesalahan saat menyimpan data.';
        if (e is DioException && e.response?.data != null) {
          msg = e.response!.data['message'] ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    }
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
              Text(
                widget.isEdit ? 'Edit Rombel' : 'Tambah Rombel Baru',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_loading)
            const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          else ...[
            _buildLabel('Pilih Kelas (Master)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedMasterKelasId,
              items: _masterKelasList.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] ?? e['nama'] ?? ''))).toList(),
              onChanged: widget.isEdit ? null : (v) => setState(() => _selectedMasterKelasId = v),
              decoration: _inputDeco('Pilih Kelas', isReadOnly: widget.isEdit),
              style: TextStyle(color: widget.isEdit ? AppColors.gray500 : AppColors.foreground),
            ),
            const SizedBox(height: 16),

            _buildLabel('Pilih Ruangan (Untuk Menentukan Kapasitas)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedRuangKelasId,
              items: _ruangKelasList.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text('${e['kode'] ?? ''} (Kapasitas: ${e['kapasitas']})'))).toList(),
              onChanged: (v) => setState(() => _selectedRuangKelasId = v),
              decoration: _inputDeco('Pilih Ruangan', isReadOnly: false),
            ),
            const SizedBox(height: 16),

            _buildLabel('Pilih Wali Kelas (Hanya Guru yg Tersedia)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedWaliKelasId,
              items: [
                const DropdownMenuItem(value: null, child: Text('Belum ada wali kelas', style: TextStyle(color: AppColors.gray500))),
                ..._guruList.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] ?? ''))),
              ],
              onChanged: (v) => setState(() => _selectedWaliKelasId = v),
              decoration: _inputDeco('Pilih Wali Kelas', isReadOnly: false),
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
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.isEdit ? 'Simpan Perubahan' : 'Buat Rombel'),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground));

  InputDecoration _inputDeco(String hint, {bool isReadOnly = false}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray400),
        filled: true, fillColor: isReadOnly ? AppColors.gray100 : AppColors.gray50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
}
