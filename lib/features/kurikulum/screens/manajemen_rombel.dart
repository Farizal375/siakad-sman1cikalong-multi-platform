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
import '../../../shared_widgets/table_pagination.dart';

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

  // For tracking changes and pagination
  Set<String> _originalAssignedIds = {};
  bool _savingChanges = false;
  int _availableCurrentPage = 1;
  int _availableItemsPerPage = 10;

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
            'masterKelasId': item['masterKelasId'] ?? '',
            'tahunAjaran': item['tahunAjaranCode'] ?? '',
            'ruangKelasId': item['ruangKelasId'] ?? '',
            'ruangKelasCode': item['ruangKelasCode'] ?? '-',
            'ruangKelasCapacity': item['ruangKelasCapacity'] ?? 0,
            'waliKelas': item['waliKelasName'] ?? '-',
            'waliKelasId': item['waliKelasId'],
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

          _originalAssignedIds = _assignedStudents.map((s) => s['id'] as String).toSet();
          _leftSelected.clear();
          _availableCurrentPage = 1;
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

  void _addSelected() {
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

    setState(() {
      final selectedStudents = _availableStudents.where((s) => _leftSelected.contains(s['id'])).toList();
      _assignedStudents.addAll(selectedStudents);
      _availableStudents.removeWhere((s) => _leftSelected.contains(s['id']));
      _leftSelected.clear();
      if (_availableCurrentPage > 1 && _filteredAvailable.isEmpty) {
        _availableCurrentPage--;
      }
    });
  }

  void _addAll() {
    if (_selectedRombelId == null) return;
    final rombel = _rombelList.firstWhere((r) => r['id'] == _selectedRombelId);
    final capacity = rombel['ruangKelasCapacity'] as int;
    final studentsToAdd = _filteredAvailable.toList();
    final ids = studentsToAdd.map<String>((s) => s['id'] as String).toList();

    if (_assignedStudents.length + ids.length > capacity) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kapasitas Ruang ${rombel['ruangKelasCode']} tidak mencukupi (Max: $capacity) untuk memasukkan keseluruhan bagian ini.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      _assignedStudents.addAll(studentsToAdd);
      _availableStudents.removeWhere((s) => ids.contains(s['id']));
      _leftSelected.clear();
      _availableCurrentPage = 1;
    });
  }

  void _removeStudent(Map<String, dynamic> student) {
    setState(() {
      _assignedStudents.removeWhere((s) => s['id'] == student['id']);
      _availableStudents.add(student);
      _availableStudents.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    });
  }

  void _removeAll() {
    setState(() {
      _availableStudents.addAll(_assignedStudents);
      _availableStudents.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      _assignedStudents.clear();
    });
  }

  bool get _hasChanges {
    final currentAssignedIds = _assignedStudents.map((s) => s['id'] as String).toSet();
    if (currentAssignedIds.length != _originalAssignedIds.length) return true;
    return currentAssignedIds.difference(_originalAssignedIds).isNotEmpty;
  }

  Future<void> _saveRombelChanges() async {
    if (_selectedRombelId == null) return;
    setState(() => _savingChanges = true);

    try {
      final currentAssignedIds = _assignedStudents.map((s) => s['id'] as String).toSet();
      
      final studentsToAdd = currentAssignedIds.difference(_originalAssignedIds).toList();
      final studentsToRemove = _originalAssignedIds.difference(currentAssignedIds).toList();

      for (String id in studentsToRemove) {
        await ApiService.removeSiswaFromRombel(_selectedRombelId!, id);
      }

      if (studentsToAdd.isNotEmpty) {
        await ApiService.assignSiswa(_selectedRombelId!, studentsToAdd);
      }

      await _loadStudentsForRombel(_selectedRombelId!);
      await _loadRombelList();

      if (mounted) {
        setState(() {
          _successMessage = 'Perubahan rombel berhasil disimpan';
          _showSuccessToast = true;
          _savingChanges = false;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showSuccessToast = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menyimpan perubahan rombel.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _discardRombelChanges() {
    if (_selectedRombelId != null) {
      _loadStudentsForRombel(_selectedRombelId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
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

            // ── Rombel Selector Cards ──
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _rombelList.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (ctx, i) {
                  if (i == _rombelList.length) {
                    return _buildAddRombelCard();
                  }
                  final r = _rombelList[i];
                  final isSelected = _selectedRombelId == r['id'];
                  return _buildRombelCard(r, isSelected);
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Capacity Info & Actions ──
            if (_selectedRombelId != null)
              Builder(builder: (context) {
                final r = _rombelList.firstWhere((x) => x['id'] == _selectedRombelId);
                final capacity = r['ruangKelasCapacity'] as int;
                final current = _assignedStudents.length;
                final ratio = capacity > 0 ? (current / capacity) : 1.0;
                final color = ratio >= 1.0 ? const Color(0xFFDC2626) : (ratio > 0.8 ? const Color(0xFFD97706) : AppColors.green600);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.people, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kapasitas Ruang ${r['ruangKelasCode']}', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: ratio, minHeight: 8,
                                      backgroundColor: AppColors.gray200,
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text('$current / $capacity Siswa', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showRombelModal(isEdit: true, data: r),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _deleteRombel,
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Hapus'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.destructive,
                              side: const BorderSide(color: AppColors.destructive),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            if (_selectedRombelId != null) const SizedBox(height: 24),

            // ── Dual-Pane Transfer List ──
            if (_selectedRombelId == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.class_outlined, size: 64, color: AppColors.gray300),
                      const SizedBox(height: 16),
                      const Text('Pilih rombel terlebih dahulu', style: TextStyle(color: AppColors.gray500, fontSize: 16)),
                    ],
                  ),
                ),
              )
            else if (_loadingStudents)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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

            // ── Save/Cancel Actions ──
            if (_selectedRombelId != null && !_loadingStudents)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_hasChanges)
                      const Text('Ada perubahan yang belum disimpan', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w500)),
                    if (_hasChanges) const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: _hasChanges && !_savingChanges ? _discardRombelChanges : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _hasChanges && !_savingChanges ? _saveRombelChanges : null,
                      icon: _savingChanges 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save, size: 18),
                      label: Text(_savingChanges ? 'Menyimpan...' : 'Simpan Perubahan'),
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
              ),
            ],
          ),
        ),
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

  Widget _buildRombelCard(Map<String, dynamic> r, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRombelId = r['id']);
        _loadStudentsForRombel(r['id']);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.gray200, width: 2),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))]
              : [const BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    r['name'] ?? '',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.foreground),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r['tahunAjaran'] ?? '',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.primary),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: isSelected ? Colors.white70 : AppColors.gray500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r['waliKelas'] ?? 'Belum ada wali',
                    style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : AppColors.gray600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sensor_door, size: 14, color: isSelected ? Colors.white70 : AppColors.gray500),
                const SizedBox(width: 6),
                Text(
                  '${r['totalSiswa']}/${r['ruangKelasCapacity']} Siswa',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.gray700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRombelCard() {
    return GestureDetector(
      onTap: () => _showRombelModal(),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray300, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 32, color: AppColors.gray500),
            SizedBox(height: 12),
            Text('Tambah\nRombel', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray600)),
          ],
        ),
      ),
    );
  }

  // ── Available Students Pane ──
  Widget _buildAvailablePane() {
    final allFiltered = _filteredAvailable;
    final total = allFiltered.length;
    final start = (_availableCurrentPage - 1) * _availableItemsPerPage;
    final end = (start + _availableItemsPerPage).clamp(0, total);
    final pageData = allFiltered.sublist(start, end);

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
                Text('Daftar Siswa Tersedia (${allFiltered.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() {
                    _leftSearch = v;
                    _availableCurrentPage = 1;
                  }),
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
          pageData.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Tidak ada siswa tersedia', style: TextStyle(color: AppColors.gray500))),
              )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pageData.length,
              itemBuilder: (_, i) {
                  final s = pageData[i];
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
          TablePagination(
            currentPage: _availableCurrentPage,
            totalItems: total,
            itemsPerPage: _availableItemsPerPage,
            onPageChange: (p) => setState(() => _availableCurrentPage = p),
            onItemsPerPageChange: (n) => setState(() {
              _availableItemsPerPage = n;
              _availableCurrentPage = 1;
            }),
            itemName: 'siswa',
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
          list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: AppColors.gray300),
                        SizedBox(height: 8),
                        Text('Belum ada siswa dipetakan', style: TextStyle(color: AppColors.gray500)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                          onPressed: () => _removeStudent(s),
                        ),
                      );
                    },
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
              items: _ruangKelasList.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text('${e['code'] ?? e['kode'] ?? ''} (Kapasitas: ${e['capacity'] ?? e['kapasitas'] ?? 0})'))).toList(),
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
