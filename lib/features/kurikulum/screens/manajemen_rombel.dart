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
  int _assignedCurrentPage = 1;
  int _assignedItemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadRombelList();
  }

  // ── Helper: Show error SnackBar ──
  void _showAlert(String message, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isWarning ? const Color(0xFFD97706) : AppColors.destructive,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Helper: Show success SnackBar ──
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.green600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
      if (mounted) {
        setState(() => _loading = false);
        _showAlert('Gagal memuat daftar rombel. Periksa koneksi internet Anda.');
      }
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
          if (mounted) {
            setState(() {
              _selectedRombelId = null;
              _assignedStudents.clear();
              _availableStudents.clear();
              _originalAssignedIds = {};
              _leftSelected.clear();
            });
            _loadRombelList();
            _showSuccess('Rombel "${r['name']}" berhasil dihapus.');
          }
        } catch (e) {
          String msg = 'Gagal menghapus rombel.';
          if (e is DioException && e.response?.data != null) {
            msg = e.response!.data['message']?.toString() ?? msg;
          }
          _showAlert(msg);
        }
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
          _assignedCurrentPage = 1;
          _loadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStudents = false);
        _showAlert('Gagal memuat data siswa untuk rombel ini. Coba pilih rombel kembali.');
      }
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
    if (_leftSelected.isEmpty) {
      _showAlert('Pilih minimal satu siswa terlebih dahulu.', isWarning: true);
      return;
    }
    final rombel = _rombelList.firstWhere((r) => r['id'] == _selectedRombelId);
    final capacity = rombel['ruangKelasCapacity'] as int;
    final ids = _leftSelected.toList();
    final sisaKursi = capacity > 0 ? capacity - _assignedStudents.length : null;

    if (capacity > 0 && _assignedStudents.length >= capacity) {
      _showAlert('Rombel sudah penuh! Kapasitas ruang ${rombel['ruangKelasCode']} (${capacity} siswa) sudah tercapai.');
      return;
    }

    if (capacity > 0 && _assignedStudents.length + ids.length > capacity) {
      _showAlert(
        'Tidak dapat menambahkan ${ids.length} siswa sekaligus.\n'
        'Ruang ${rombel['ruangKelasCode']} hanya tersisa $sisaKursi kursi dari kapasitas $capacity.',
      );
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

    // Warn if now full
    if (capacity > 0 && _assignedStudents.length >= capacity) {
      _showAlert('Rombel sekarang penuh (${capacity}/${capacity}). Tidak bisa menambahkan siswa lagi.', isWarning: true);
    }
  }

  void _addAll() {
    if (_selectedRombelId == null) return;
    if (_filteredAvailable.isEmpty) {
      _showAlert('Tidak ada siswa tersedia untuk ditambahkan.', isWarning: true);
      return;
    }
    final rombel = _rombelList.firstWhere((r) => r['id'] == _selectedRombelId);
    final capacity = rombel['ruangKelasCapacity'] as int;
    final studentsToAdd = _filteredAvailable.toList();
    final ids = studentsToAdd.map<String>((s) => s['id'] as String).toList();
    final sisaKursi = capacity > 0 ? capacity - _assignedStudents.length : null;

    if (capacity > 0 && _assignedStudents.length >= capacity) {
      _showAlert('Rombel sudah penuh! Kapasitas ruang ${rombel['ruangKelasCode']} ($capacity siswa) sudah tercapai.');
      return;
    }

    if (capacity > 0 && _assignedStudents.length + ids.length > capacity) {
      _showAlert(
        'Tidak bisa menambahkan semua ${ids.length} siswa sekaligus.\n'
        'Ruang ${rombel['ruangKelasCode']} hanya tersisa $sisaKursi kursi.\n'
        'Gunakan tombol ">" untuk memilih siswa secara manual.',
        isWarning: true,
      );
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
    if (_assignedStudents.isEmpty) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 12),
            Text('Keluarkan Semua Siswa?'),
          ],
        ),
        content: Text(
          'Anda akan mengeluarkan ${_assignedStudents.length} siswa dari rombel ini.\n'
          'Perubahan ini belum tersimpan ke database.\n\n'
          'Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Keluarkan Semua'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _availableStudents.addAll(_assignedStudents);
          _availableStudents.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
          _assignedStudents.clear();
        });
        _showAlert(
          '${_originalAssignedIds.length} siswa dikeluarkan sementara. Klik "Simpan Perubahan" untuk menyimpan.',
          isWarning: true,
        );
      }
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
        final addedCount = studentsToAdd.length;
        final removedCount = studentsToRemove.length;
        setState(() {
          _successMessage = 'Perubahan disimpan! (+$addedCount masuk, -$removedCount keluar)';
          _showSuccessToast = true;
          _savingChanges = false;
        });
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showSuccessToast = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingChanges = false);
        String errMsg = 'Gagal menyimpan perubahan rombel.';
        if (e is DioException && e.response?.data != null) {
          errMsg = e.response!.data['message']?.toString() ?? errMsg;
        }
        _showAlert(errMsg);
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
                          _TransferButton(
                            icon: Icons.keyboard_double_arrow_right,
                            tooltip: 'Tambahkan semua siswa tersedia',
                            onPressed: _filteredAvailable.isNotEmpty ? _addAll : null,
                          ),
                          const SizedBox(height: 8),
                          _TransferButton(
                            icon: Icons.chevron_right,
                            tooltip: 'Tambahkan siswa yang dipilih',
                            onPressed: _leftSelected.isNotEmpty ? _addSelected : null,
                          ),
                          const SizedBox(height: 8),
                          _TransferButton(
                            icon: Icons.keyboard_double_arrow_left,
                            tooltip: 'Keluarkan semua siswa dari rombel',
                            onPressed: _assignedStudents.isNotEmpty ? _removeAll : null,
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
    // Clamp start so it never exceeds total (prevents RangeError when data shrinks)
    final start = total > 0
        ? ((_availableCurrentPage - 1) * _availableItemsPerPage).clamp(0, total - 1)
        : 0;
    final end = (start + _availableItemsPerPage).clamp(0, total);
    final pageData = total > 0 ? allFiltered.sublist(start, end) : <Map<String, dynamic>>[];

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
    final allFiltered = _filteredAssigned;
    final total = allFiltered.length;
    // Clamp start so it never exceeds total (prevents RangeError when data shrinks)
    final start = total > 0
        ? ((_assignedCurrentPage - 1) * _assignedItemsPerPage).clamp(0, total - 1)
        : 0;
    final end = (start + _assignedItemsPerPage).clamp(0, total);
    final pageData = total > 0 ? allFiltered.sublist(start, end) : <Map<String, dynamic>>[];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _assignedStudents.isNotEmpty ? AppColors.primary : AppColors.gray300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Siswa di Rombel Ini (${_assignedStudents.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() {
                    _rightSearch = v;
                    _assignedCurrentPage = 1;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Cari siswa di rombel...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.gray400),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── List ──
          pageData.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(_assignedStudents.isEmpty ? 48 : 24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _rightSearch.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
                          size: 48,
                          color: AppColors.gray300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _rightSearch.isNotEmpty
                              ? 'Siswa tidak ditemukan'
                              : 'Belum ada siswa dipetakan',
                          style: const TextStyle(color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pageData.length,
                  itemBuilder: (_, i) {
                    final s = pageData[i];
                    final nomor = start + i + 1;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          (s['name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        '$nomor. ${s['name'] ?? ''}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'NISN: ${s['nisn'] ?? '-'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                      ),
                      trailing: Tooltip(
                        message: 'Keluarkan dari rombel',
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.gray400),
                          hoverColor: AppColors.red50,
                          onPressed: () => _removeStudent(s),
                        ),
                      ),
                    );
                  },
                ),

          // ── Pagination ──
          TablePagination(
            currentPage: _assignedCurrentPage,
            totalItems: total,
            itemsPerPage: _assignedItemsPerPage,
            onPageChange: (p) => setState(() => _assignedCurrentPage = p),
            onItemsPerPageChange: (n) => setState(() {
              _assignedItemsPerPage = n;
              _assignedCurrentPage = 1;
            }),
            itemName: 'siswa',
          ),
        ],
      ),
    );
  }
} // end _ManajemenRombelState

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
  String? _loadError;

  List<Map<String, dynamic>> _masterKelasList = [];
  List<Map<String, dynamic>> _ruangKelasList = [];

  String? _selectedMasterKelasId;
  String? _selectedRuangKelasId;

  // Wali kelas info (read-only, derived from master kelas)
  String _derivedWaliName = 'Belum ditambahkan';
  bool _hasWali = false;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final results = await Future.wait([
        ApiService.getMasterKelas(),
        ApiService.getRuangKelas(),
      ]);

      if (!mounted) return;
      setState(() {
        _masterKelasList = (results[0]['data'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        _ruangKelasList = (results[1]['data'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];

        if (widget.isEdit && widget.initialData != null) {
          _selectedMasterKelasId = widget.initialData!['masterKelasId'];
          _selectedRuangKelasId = widget.initialData!['ruangKelasId'];

          if (_selectedRuangKelasId == '-' || _selectedRuangKelasId == '') {
            _selectedRuangKelasId = null;
          }

          // Derive wali info from selected master kelas
          _updateDerivedWali(_selectedMasterKelasId);
        }

        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Gagal memuat data form. Silakan coba lagi.';
        });
      }
    }
  }

  void _updateDerivedWali(String? masterKelasId) {
    if (masterKelasId == null) {
      _derivedWaliName = 'Belum ditambahkan';
      _hasWali = false;
      return;
    }
    final kelas = _masterKelasList.firstWhere(
      (k) => k['id'] == masterKelasId,
      orElse: () => {},
    );
    final waliId = kelas['homeroomTeacherId'];
    _hasWali = waliId != null;
    _derivedWaliName = _hasWali ? (kelas['homeroomTeacher'] ?? '-') : 'Belum ditambahkan';
  }

  Future<void> _save() async {
    // Validation
    if (_selectedMasterKelasId == null) {
      _showError('Pilih kelas terlebih dahulu!');
      return;
    }
    if (!widget.isEdit && _selectedRuangKelasId == null) {
      _showError('Pilih ruangan terlebih dahulu!');
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      if (!widget.isEdit) 'masterKelasId': _selectedMasterKelasId,
      'ruangKelasId': _selectedRuangKelasId,
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
          msg = e.response!.data['message']?.toString() ?? msg;
        }
        _showError(msg);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: AppColors.destructive,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isEdit ? 'Edit Rombel' : 'Tambah Rombel Baru',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.isEdit
                ? 'Ubah ruangan kelas rombel ini. Wali kelas dikelola di Master Akademik.'
                : 'Buat rombongan belajar baru. Wali kelas diambil dari data Master Kelas.',
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
          const Divider(height: 32),

          if (_loading)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.destructive),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_loadError!, style: const TextStyle(color: AppColors.destructive)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() { _loading = true; _loadError = null; });
                      _loadFormData();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else ...[
            // ── 1. Master Kelas Dropdown ──
            _buildLabel('Kelas (Master Kelas)', required: !widget.isEdit),
            const SizedBox(height: 8),
            if (widget.isEdit)
              // In edit mode: read-only display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.class_outlined, size: 18, color: AppColors.gray500),
                        const SizedBox(width: 10),
                        Text(
                          _masterKelasList
                              .where((k) => k['id'] == _selectedMasterKelasId)
                              .map((k) => '${k['grade']} — ${k['name']}')
                              .firstOrNull ?? 'Tidak ditemukan',
                          style: const TextStyle(color: AppColors.gray600, fontSize: 15),
                        ),
                      ],
                    ),
                    const Tooltip(
                      message: 'Kelas tidak dapat diubah setelah rombel dibuat',
                      child: Icon(Icons.lock_outline, size: 16, color: AppColors.gray400),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedMasterKelasId,
                isExpanded: true,
                items: _masterKelasList.isEmpty
                    ? [const DropdownMenuItem(value: '', child: Text('Belum ada data master kelas'))]
                    : _masterKelasList.map((e) => DropdownMenuItem<String>(
                        value: e['id'] as String,
                        child: Text(
                          '${e['grade'] ?? ''} — ${e['name'] ?? ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                onChanged: _masterKelasList.isEmpty
                    ? null
                    : (v) {
                        setState(() {
                          _selectedMasterKelasId = v;
                          _updateDerivedWali(v);
                        });
                      },
                decoration: _inputDeco('Pilih Kelas'),
              ),
            const SizedBox(height: 16),

            // ── 2. Info Wali Kelas (read-only dari Master Kelas) ──
            if (_selectedMasterKelasId != null) ...[
              _buildLabel('Wali Kelas'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _hasWali ? AppColors.blue50 : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasWali
                        ? AppColors.blue600.withValues(alpha: 0.4)
                        : AppColors.amber500.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _hasWali ? Icons.person_pin_circle_outlined : Icons.person_off_outlined,
                      color: _hasWali ? AppColors.blue600 : AppColors.amber600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _derivedWaliName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _hasWali ? AppColors.blue600 : AppColors.amber600,
                            ),
                          ),
                          if (!_hasWali)
                            const Text(
                              'Wali kelas belum diisi pada Master Kelas ini. '
                              'Tambahkan melalui menu Master Akademik.',
                              style: TextStyle(fontSize: 11, color: AppColors.gray600),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Tooltip(
                      message: 'Ubah wali kelas melalui menu Master Akademik',
                      child: Icon(Icons.info_outline, size: 16, color: AppColors.gray400),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Spacer between section 2 and Ruangan


            // ── 4. Ruang Kelas ──
            _buildLabel('Ruangan', required: !widget.isEdit),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRuangKelasId,
              isExpanded: true,
              items: _ruangKelasList.isEmpty
                  ? [const DropdownMenuItem(value: '', child: Text('Belum ada data ruangan'))]
                  : _ruangKelasList.map((e) => DropdownMenuItem<String>(
                      value: e['id'] as String,
                      child: Text(
                        '${e['code'] ?? e['kode'] ?? ''}  •  Kapasitas: ${e['capacity'] ?? e['kapasitas'] ?? 0} siswa',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
              onChanged: _ruangKelasList.isEmpty
                  ? null
                  : (v) => setState(() => _selectedRuangKelasId = v),
              decoration: _inputDeco('Pilih Ruangan'),
            ),
            const SizedBox(height: 24),

            // ── Action Buttons ──
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
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(widget.isEdit ? Icons.save_outlined : Icons.add, size: 18),
                  label: Text(widget.isEdit ? 'Simpan Perubahan' : 'Buat Rombel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground,
            ),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.destructive),
                    )
                  ]
                : [],
          ),
        ),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
        filled: true,
        fillColor: AppColors.gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
}
