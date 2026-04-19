// File: lib/features/admin/screens/master_data.dart
// ===========================================
// MASTER DATA SCREEN
// Translated from MasterAkademik.tsx
// Tabbed: Academic Year, Semesters, Classrooms, Classes, Students, Teachers
// With Toggle Switches, Form Modals, Import/Export
// ===========================================

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../shared_widgets/table_pagination.dart';
import '../../../shared_widgets/delete_confirmation_modal.dart';
import '../../../shared_widgets/success_toast.dart';

class MasterAkademik extends StatefulWidget {
  const MasterAkademik({super.key});

  @override
  State<MasterAkademik> createState() => _MasterAkademikState();
}

class _MasterAkademikState extends State<MasterAkademik> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSuccessToast = false;
  int _refreshKey = 0;
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleDelete(String type, String name) {
    DeleteConfirmationModal.show(
      context,
      title: 'Konfirmasi Penghapusan Data Master',
      message: 'Apakah Anda yakin ingin menghapus data master ini? Data yang dihapus tidak dapat dipulihkan.',
      itemName: name,
      onConfirm: () {
        setState(() {
          _successMessage = '$type "$name" berhasil dihapus';
          _showSuccessToast = true;
        });
      },
    );
  }

  void _showFormModal({String? mode, int? tabIndex, Map<String, dynamic>? initialData}) {
    final tab = tabIndex ?? _tabController.index;
    final isEdit = mode == 'edit';
    final isView = mode == 'view';
    Widget modalContent;

    switch (tab) {
      case 0:
        modalContent = _AcademicYearFormModal(isEdit: isEdit, initialData: initialData);
        break;
      case 1:
        modalContent = _SemesterFormModal(isEdit: isEdit, initialData: initialData);
        break;
      case 2:
        modalContent = _ClassroomFormModal(isEdit: isEdit, initialData: initialData);
        break;
      case 3:
        modalContent = _MasterClassFormModal(isEdit: isEdit, initialData: initialData);
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640), // Made slightly wider for 2 columns
          child: modalContent,
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          _refreshKey++;
          _successMessage = isEdit ? 'Data berhasil diperbarui' : 'Data berhasil ditambahkan';
          _showSuccessToast = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showSuccessToast = false);
        });
      }
    });
  }

  String get _addButtonLabel {
    switch (_tabController.index) {
      case 0: return 'Tambah Tahun Ajaran';
      case 1: return 'Tambah Semester';
      case 2: return 'Tambah Ruang Kelas';
      case 3: return 'Tambah Master Kelas';
      default: return 'Tambah Data';
    }
  }

  bool get _showImportExport => false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Title ──
            const Text(
              'Master Data Akademik',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola entitas akademik inti dan parameter sistem',
              style: TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 32),

            // ── 6-Tab Navigation ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(8),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.gray600,
                labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                onTap: (_) => setState(() {}), // rebuild for button label
                tabs: const [
                  Tab(text: 'Tahun Ajaran'),
                  Tab(text: 'Semester'),
                  Tab(text: 'Ruang Kelas'),
                  Tab(text: 'Master Kelas'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Action Bar ──
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari...',
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

                // Import/Export buttons for students/teachers
                if (_showImportExport) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _successMessage = 'Template berhasil diunduh';
                        _showSuccessToast = true;
                      });
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Template'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _successMessage = 'Data siap diimport';
                        _showSuccessToast = true;
                      });
                    },
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('Import'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFF16A34A), width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _successMessage = 'Data berhasil diekspor';
                        _showSuccessToast = true;
                      });
                    },
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Export'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB), width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                ElevatedButton.icon(
                  onPressed: () => _showFormModal(mode: 'create'),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(_addButtonLabel),
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

            // ── Tab Content ──
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
                clipBehavior: Clip.antiAlias,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AcademicYearTable(key: ValueKey('academic_$_refreshKey'), onDelete: (name) => _handleDelete('Tahun Ajaran', name), onEdit: (row) => _showFormModal(mode: 'edit', tabIndex: 0, initialData: row)),
                    _SemesterTable(key: ValueKey('semester_$_refreshKey'), onDelete: (name) => _handleDelete('Semester', name), onEdit: (row) => _showFormModal(mode: 'edit', tabIndex: 1, initialData: row)),
                    _RuangKelasTable(key: ValueKey('ruang_$_refreshKey'), onDelete: (name) => _handleDelete('Ruang Kelas', name), onEdit: (row) => _showFormModal(mode: 'edit', tabIndex: 2, initialData: row)),
                    _MasterKelasTable(key: ValueKey('master_$_refreshKey'), onDelete: (name) => _handleDelete('Master Kelas', name), onEdit: (row) => _showFormModal(mode: 'edit', tabIndex: 3, initialData: row)),
                  ],
                ),
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

// ═══════════════════════════════════════════════
// TOGGLE SWITCH — matches React ToggleSwitch
// ═══════════════════════════════════════════════
class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.green500 : AppColors.gray300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ACADEMIC YEAR TABLE — with Toggle Switch
// ═══════════════════════════════════════════════
class _AcademicYearTable extends StatefulWidget {
  final void Function(String name) onDelete;
  final void Function(Map<String, dynamic> row) onEdit;
  const _AcademicYearTable({super.key, required this.onDelete, required this.onEdit});

  @override
  State<_AcademicYearTable> createState() => _AcademicYearTableState();
}

class _AcademicYearTableState extends State<_AcademicYearTable> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService.getTahunAjaran();
      final items = response['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _data = items.map<Map<String, dynamic>>((item) => ({
            'id': item['id'] ?? '',
            'code': item['code'] ?? '',
            'description': item['description'] ?? '',
            'isActive': item['isActive'] ?? false,
          })).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> row) async {
    try {
      await ApiService.toggleTahunAjaran(row['id']);
      _loadData();
    } catch (_) {}
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final total = _data.length;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, total);
    final pageData = _data.sublist(start, end);

    return Column(
      children: [
        // Header
        Container(
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: const Row(
            children: [
              Expanded(child: Text('Kode Tahun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(child: Text('Deskripsi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(child: Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
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
              final row = pageData[i];
              final isActive = row['isActive'] as bool;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    Expanded(child: Text(row['code'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                    Expanded(child: Text(row['description'], style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.green100 : AppColors.gray100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? AppColors.green500 : AppColors.gray500, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(isActive ? 'Aktif' : 'Tidak Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? AppColors.green700 : AppColors.gray700)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _ToggleSwitch(
                            value: isActive,
                            onChanged: (val) => _toggleActive(row),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () => widget.onEdit(row), splashRadius: 18, tooltip: 'Edit'),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600), onPressed: () => widget.onDelete(row['code']), splashRadius: 18, tooltip: 'Hapus'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        TablePagination(currentPage: _currentPage, totalItems: total, itemsPerPage: _itemsPerPage, onPageChange: (p) => setState(() => _currentPage = p), onItemsPerPageChange: (n) => setState(() { _itemsPerPage = n; _currentPage = 1; }), itemName: 'tahun ajaran'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// SEMESTER TABLE — with Toggle Switch
// ═══════════════════════════════════════════════
class _SemesterTable extends StatefulWidget {
  final void Function(String name) onDelete;
  final void Function(Map<String, dynamic> row) onEdit;
  const _SemesterTable({super.key, required this.onDelete, required this.onEdit});

  @override
  State<_SemesterTable> createState() => _SemesterTableState();
}

class _SemesterTableState extends State<_SemesterTable> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService.getSemester();
      final items = response['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _data = items.map<Map<String, dynamic>>((item) => ({
            'id': item['id'] ?? '',
            'name': item['name'] ?? '',
            'academicYear': item['academicYear'] ?? '',
            'isActive': item['isActive'] ?? false,
          })).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> row) async {
    try {
      await ApiService.toggleSemester(row['id']);
      _loadData();
    } catch (_) {}
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final total = _data.length;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, total);
    final pageData = _data.sublist(start, end);

    return Column(
      children: [
        Container(
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: const Row(
            children: [
              Expanded(child: Text('Nama Semester', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(child: Text('Tahun Ajaran Terkait', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(child: Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
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
              final row = pageData[i];
              final isActive = row['isActive'] as bool;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    Expanded(child: Text(row['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                    Expanded(child: Text(row['academicYear'], style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.green100 : AppColors.gray100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? AppColors.green500 : AppColors.gray500, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(isActive ? 'Aktif' : 'Tidak Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? AppColors.green700 : AppColors.gray700)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _ToggleSwitch(
                            value: isActive,
                            onChanged: (val) => _toggleActive(row),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () => widget.onEdit(row), splashRadius: 18, tooltip: 'Edit'),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600), onPressed: () => widget.onDelete('${row['name']} ${row['academicYear']}'), splashRadius: 18, tooltip: 'Hapus'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        TablePagination(currentPage: _currentPage, totalItems: total, itemsPerPage: _itemsPerPage, onPageChange: (p) => setState(() => _currentPage = p), onItemsPerPageChange: (n) => setState(() { _itemsPerPage = n; _currentPage = 1; }), itemName: 'semester'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// RUANG KELAS TABLE — API Connected
// ═══════════════════════════════════════════════
class _RuangKelasTable extends StatefulWidget {
  final void Function(String name) onDelete;
  final void Function(Map<String, dynamic> row) onEdit;
  const _RuangKelasTable({super.key, required this.onDelete, required this.onEdit});

  @override
  State<_RuangKelasTable> createState() => _RuangKelasTableState();
}

class _RuangKelasTableState extends State<_RuangKelasTable> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService.getRuangKelas();
      final items = response['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _data = items.map<Map<String, dynamic>>((item) => ({
            'id': item['id'] ?? '',
            'code': item['code'] ?? '',
            'building': item['building'] ?? '',
            'capacity': (item['capacity'] ?? 0).toString(),
          })).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> row) async {
    try {
      await ApiService.deleteRuangKelas(row['id']);
      _loadData();
    } catch (_) {}
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final total = _data.length;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, total);
    final pageData = _data.sublist(start, end);

    return Column(
      children: [
        Container(
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: const Row(
            children: [
              Expanded(child: Text('Kode Ruang', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(child: Text('Gedung', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(child: Text('Kapasitas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              SizedBox(width: 80, child: Text('Aksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: pageData.isEmpty
              ? const Center(child: Text('Belum ada data ruang kelas', style: TextStyle(color: AppColors.gray500)))
              : ListView.separated(
                  itemCount: pageData.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
                  itemBuilder: (_, i) {
                    final row = pageData[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(child: Text(row['code'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                          Expanded(child: Text(row['building'], style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                          Expanded(child: Text(row['capacity'], style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                          SizedBox(
                            width: 80,
                            child: Row(
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () => widget.onEdit(row), splashRadius: 18, tooltip: 'Edit'),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600), onPressed: () {
                                  widget.onDelete(row['code']);
                                  _deleteItem(row);
                                }, splashRadius: 18, tooltip: 'Hapus'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        TablePagination(currentPage: _currentPage, totalItems: total, itemsPerPage: _itemsPerPage, onPageChange: (p) => setState(() => _currentPage = p), onItemsPerPageChange: (n) => setState(() { _itemsPerPage = n; _currentPage = 1; }), itemName: 'ruang kelas'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// MASTER KELAS TABLE — API Connected
// ═══════════════════════════════════════════════
class _MasterKelasTable extends StatefulWidget {
  final void Function(String name) onDelete;
  final void Function(Map<String, dynamic> row) onEdit;
  const _MasterKelasTable({super.key, required this.onDelete, required this.onEdit});

  @override
  State<_MasterKelasTable> createState() => _MasterKelasTableState();
}

class _MasterKelasTableState extends State<_MasterKelasTable> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService.getMasterKelas();
      final items = response['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _data = items.map<Map<String, dynamic>>((item) => ({
            'id': item['id'] ?? '',
            'name': item['name'] ?? '',
            'grade': item['grade'] ?? '',
            'homeroomTeacher': item['homeroomTeacher'] ?? '-',
            'classroom': item['classroom'] ?? '-',
          })).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> row) async {
    try {
      await ApiService.deleteMasterKelas(row['id']);
      _loadData();
    } catch (_) {}
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final total = _data.length;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, total);
    final pageData = _data.sublist(start, end);

    return Column(
      children: [
        Container(
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: const Row(
            children: [
              Expanded(child: Text('Nama Kelas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(child: Text('Tingkat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(child: Text('Wali Kelas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              Expanded(child: Text('Ruangan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
              SizedBox(width: 80, child: Text('Aksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: pageData.isEmpty
              ? const Center(child: Text('Belum ada data master kelas', style: TextStyle(color: AppColors.gray500)))
              : ListView.separated(
                  itemCount: pageData.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
                  itemBuilder: (_, i) {
                    final row = pageData[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(child: Text(row['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                          Expanded(child: Text(row['grade'], style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                          Expanded(child: Text(row['homeroomTeacher'], style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                          Expanded(child: Text(row['classroom'], style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                          SizedBox(
                            width: 80,
                            child: Row(
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () => widget.onEdit(row), splashRadius: 18, tooltip: 'Edit'),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600), onPressed: () {
                                  widget.onDelete(row['name']);
                                  _deleteItem(row);
                                }, splashRadius: 18, tooltip: 'Hapus'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        TablePagination(currentPage: _currentPage, totalItems: total, itemsPerPage: _itemsPerPage, onPageChange: (p) => setState(() => _currentPage = p), onItemsPerPageChange: (n) => setState(() { _itemsPerPage = n; _currentPage = 1; }), itemName: 'master kelas'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// USERS TABLE — API Connected (for Siswa & Guru tabs)
// ═══════════════════════════════════════════════
class _UsersTable extends StatefulWidget {
  final void Function(String name) onDelete;
  final void Function(String id) onEdit;
  final void Function(String id)? onView;
  final String itemName;
  final String roleFilter;
  final List<String> columns;

  const _UsersTable({
    required this.onDelete,
    required this.onEdit,
    this.onView,
    required this.itemName,
    required this.roleFilter,
    required this.columns,
  });

  @override
  State<_UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<_UsersTable> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  List<Map<String, dynamic>> _data = [];
  int _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService.getUsers(
        page: _currentPage,
        limit: _itemsPerPage,
        role: widget.roleFilter,
      );
      final items = response['data'] as List? ?? [];
      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          // Backend now filters by role
          _data = items.map<Map<String, dynamic>>((item) => ({
            'id': item['id'] ?? '',
            'idNumber': item['idNumber'] ?? '-',
            'name': item['name'] ?? '',
            'email': item['email'] ?? '',
            'status': item['status'] ?? 'Aktif',
          })).toList();
          _total = pagination['total'] ?? _data.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> row) async {
    try {
      await ApiService.deleteUser(row['id']);
      _loadData();
    } catch (_) {}
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final dataCols = widget.columns.sublist(0, widget.columns.length - 1); // exclude 'Aksi'

    return Column(
      children: [
        Container(
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              ...dataCols.map((c) => Expanded(child: Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground)))),
              SizedBox(width: widget.onView != null ? 120 : 80, child: const Text('Aksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: _data.isEmpty
              ? Center(child: Text('Belum ada data ${widget.itemName}', style: const TextStyle(color: AppColors.gray500)))
              : ListView.separated(
                  itemCount: _data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
                  itemBuilder: (_, i) {
                    final row = _data[i];
                    final cells = [row['idNumber'], row['name'], row['email'], row['status']];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        children: [
                          ...List.generate(dataCols.length, (ci) {
                            final val = ci < cells.length ? cells[ci] ?? '' : '';
                            if (dataCols[ci] == 'Status') {
                              final isActive = val == 'Aktif';
                              return Expanded(
                                child: Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? AppColors.green500 : AppColors.gray500, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? AppColors.green700 : AppColors.gray700)),
                                  ],
                                ),
                              );
                            }
                            return Expanded(
                              child: Text(
                                val,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.foreground,
                                  fontWeight: ci == 0 ? FontWeight.w600 : FontWeight.w400,
                                  fontFamily: ci == 0 ? 'monospace' : null,
                                ),
                              ),
                            );
                          }),
                          SizedBox(
                            width: widget.onView != null ? 120 : 80,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.onView != null) IconButton(icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.gray600), onPressed: () => widget.onView!(row['id']), splashRadius: 18, tooltip: 'Lihat Detail'),
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () => widget.onEdit(row['id']), splashRadius: 18, tooltip: 'Edit'),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600), onPressed: () {
                                  widget.onDelete(row['name']);
                                  _deleteItem(row);
                                }, splashRadius: 18, tooltip: 'Hapus'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        TablePagination(currentPage: _currentPage, totalItems: _total, itemsPerPage: _itemsPerPage, onPageChange: (p) { setState(() => _currentPage = p); _loadData(); }, onItemsPerPageChange: (n) { setState(() { _itemsPerPage = n; _currentPage = 1; }); _loadData(); }, itemName: widget.itemName),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// FORM MODALS — Academic Year
// ═══════════════════════════════════════════════
class _AcademicYearFormModal extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  const _AcademicYearFormModal({this.isEdit = false, this.initialData});

  @override
  State<_AcademicYearFormModal> createState() => _AcademicYearFormModalState();
}

class _AcademicYearFormModalState extends State<_AcademicYearFormModal> {
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialData != null) {
      _codeController.text = widget.initialData!['code'] ?? '';
      _descController.text = widget.initialData!['description'] ?? '';
      _isActive = widget.initialData!['isActive'] ?? true;
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final payload = {
      'code': _codeController.text,
      'description': _descController.text,
      'isActive': _isActive,
    };
    try {
      if (widget.isEdit && widget.initialData != null) {
        await ApiService.updateTahunAjaran(widget.initialData!['id'], payload);
      } else {
        await ApiService.createTahunAjaran(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        String msg = 'Terjadi kesalahan jaringan';
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
              Text(widget.isEdit ? 'Edit Tahun Ajaran' : 'Tambah Tahun Ajaran', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('Kode Tahun Ajaran', 'Contoh: 2026/2027', controller: _codeController, isReadOnly: widget.isEdit),
          const SizedBox(height: 16),
          _buildField('Deskripsi', 'Deskripsi tahun ajaran', controller: _descController),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Status Aktif', style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeThumbColor: AppColors.green500),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormButtons(context, _loading, _save),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FORM MODALS — Semester
// ═══════════════════════════════════════════════
class _SemesterFormModal extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  const _SemesterFormModal({this.isEdit = false, this.initialData});

  @override
  State<_SemesterFormModal> createState() => _SemesterFormModalState();
}

class _SemesterFormModalState extends State<_SemesterFormModal> {
  final _nameController = TextEditingController();
  String? _academicYearId;
  String? _academicYearFallback;
  List<Map<String, dynamic>> _tahunOptions = [];
  bool _isActive = true;
  bool _loading = false;
  bool _fetchingOptions = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _isActive = widget.initialData!['isActive'] ?? true;
      _academicYearFallback = widget.initialData!['academicYear'];
    }
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final res = await ApiService.getTahunAjaran();
      final items = res['data'] as List? ?? [];
      setState(() {
        _tahunOptions = List<Map<String, dynamic>>.from(items);
        if (widget.initialData != null && widget.initialData!['academicYear'] != null) {
          final found = _tahunOptions.firstWhere((e) => e['code'] == widget.initialData!['academicYear'], orElse: () => {});
          if (found.isNotEmpty) {
            _academicYearId = found['id'];
          }
        } else if (_tahunOptions.isNotEmpty) {
          _academicYearId = _tahunOptions.first['id'];
        }
        _fetchingOptions = false;
      });
    } catch (_) {
      setState(() => _fetchingOptions = false);
    }
  }

  Future<void> _save() async {
    if (_academicYearId == null) return;
    setState(() => _loading = true);
    final payload = {
      'name': _nameController.text,
      'academicYearId': _academicYearId,
      'isActive': _isActive,
    };
    try {
      if (widget.isEdit && widget.initialData != null) {
        await ApiService.updateSemester(widget.initialData!['id'], payload);
      } else {
        await ApiService.createSemester(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        String msg = 'Terjadi kesalahan jaringan';
        if (e is DioException && e.response?.data != null) {
          msg = e.response!.data['message'] ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate dropdown items
    final yearList = _tahunOptions.map((e) => e['id'] as String).toList();
    final yearMap = { for (var e in _tahunOptions) e['id'] as String : e['code'] as String };
    if (_academicYearFallback != null && !_tahunOptions.any((e) => e['code'] == _academicYearFallback)) {
      yearList.add('fallback');
      yearMap['fallback'] = _academicYearFallback!;
      if (_academicYearId == null) _academicYearId = 'fallback';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.isEdit ? 'Edit Semester' : 'Tambah Semester', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('Nama Semester', 'Contoh: Semester Ganjil', controller: _nameController),
          const SizedBox(height: 16),
          if (_fetchingOptions)
            const Text('Memuat Tahun Ajaran...', style: TextStyle(color: AppColors.gray500))
          else ...[
            const Text('Tahun Ajaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _academicYearId,
              items: yearList.map((e) => DropdownMenuItem(value: e, child: Text(yearMap[e]!))).toList(),
              onChanged: (v) => setState(() => _academicYearId = v),
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.gray50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Status Aktif', style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeThumbColor: AppColors.green500),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormButtons(context, _loading, _save),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FORM MODALS — Classroom
// ═══════════════════════════════════════════════
class _ClassroomFormModal extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  const _ClassroomFormModal({this.isEdit = false, this.initialData});

  @override
  State<_ClassroomFormModal> createState() => _ClassroomFormModalState();
}

class _ClassroomFormModalState extends State<_ClassroomFormModal> {
  final _codeController = TextEditingController();
  final _buildingController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialData != null) {
      _codeController.text = widget.initialData!['code'] ?? '';
      _buildingController.text = widget.initialData!['building'] ?? '';
      _capacityController.text = widget.initialData!['capacity'].toString();
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final payload = {
      'code': _codeController.text,
      'building': _buildingController.text,
      'capacity': int.tryParse(_capacityController.text) ?? 40,
    };
    try {
      if (widget.isEdit && widget.initialData != null) {
        await ApiService.updateRuangKelas(widget.initialData!['id'], payload);
      } else {
        await ApiService.createRuangKelas(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        String msg = 'Terjadi kesalahan jaringan';
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
              Text(widget.isEdit ? 'Edit Ruang Kelas' : 'Tambah Ruang Kelas', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('Kode Ruang', 'Contoh: R-101', controller: _codeController, isReadOnly: widget.isEdit),
          const SizedBox(height: 16),
          _buildField('Gedung', 'Contoh: Gedung A', controller: _buildingController),
          const SizedBox(height: 16),
          _buildField('Kapasitas', 'Contoh: 40', isNumber: true, controller: _capacityController),
          const SizedBox(height: 24),
          _buildFormButtons(context, _loading, _save),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FORM MODALS — Master Class
// ═══════════════════════════════════════════════
class _MasterClassFormModal extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  const _MasterClassFormModal({this.isEdit = false, this.initialData});

  @override
  State<_MasterClassFormModal> createState() => _MasterClassFormModalState();
}

class _MasterClassFormModalState extends State<_MasterClassFormModal> {
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  String? _homeroomTeacherId;
  String? _classroomId;
  List<Map<String, dynamic>> _guruOptions = [];
  List<Map<String, dynamic>> _ruangOptions = [];
  bool _loading = false;
  bool _fetchingOptions = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _gradeController.text = widget.initialData!['grade'] ?? '';
      // We will match the names after fetching options
    }
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final resTeacher = await ApiService.getUsers(page: 1, limit: 100, role: 'Guru Mapel');
      final resRuang = await ApiService.getRuangKelas();
      
      final teachers = resTeacher['data'] as List? ?? [];
      final ruangs = resRuang['data'] as List? ?? [];

      setState(() {
        _guruOptions = List<Map<String, dynamic>>.from(teachers);
        _ruangOptions = List<Map<String, dynamic>>.from(ruangs);

        if (widget.initialData != null) {
          final tName = widget.initialData!['homeroomTeacher'];
          final tFound = _guruOptions.firstWhere((e) => e['name'] == tName, orElse: () => {});
          if (tFound.isNotEmpty) _homeroomTeacherId = tFound['id'];

          final rCode = widget.initialData!['classroom'];
          final rFound = _ruangOptions.firstWhere((e) => e['code'] == rCode, orElse: () => {});
          if (rFound.isNotEmpty) _classroomId = rFound['id'];
        }
        _fetchingOptions = false;
      });
    } catch (_) {
      setState(() => _fetchingOptions = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final payload = {
      'name': _nameController.text,
      'grade': _gradeController.text,
      'homeroomTeacherId': _homeroomTeacherId,
      'classroomId': _classroomId,
    };
    try {
      if (widget.isEdit && widget.initialData != null) {
        await ApiService.updateMasterKelas(widget.initialData!['id'], payload);
      } else {
        await ApiService.createMasterKelas(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        String msg = 'Terjadi kesalahan jaringan';
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
              Text(widget.isEdit ? 'Edit Master Kelas' : 'Tambah Master Kelas', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('Nama Kelas', 'Contoh: X.1', controller: _nameController),
          const SizedBox(height: 16),
          _buildField('Tingkat', '10 / 11 / 12', controller: _gradeController),
          const SizedBox(height: 16),

          if (_fetchingOptions)
            const Text('Memuat Opsi...', style: TextStyle(color: AppColors.gray500))
          else ...[
            // Guru dropdown
            const Text('Wali Kelas (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _homeroomTeacherId,
              items: _guruOptions.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] as String))).toList(),
              onChanged: (v) => setState(() => _homeroomTeacherId = v),
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.gray50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Ruangan dropdown
            const Text('Ruangan (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _classroomId,
              items: _ruangOptions.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['code'] as String))).toList(),
              onChanged: (v) => setState(() => _classroomId = v),
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.gray50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          _buildFormButtons(context, _loading, _save),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// SHARED FORM HELPERS
// ═══════════════════════════════════════════════

// ═══════════════════════════════════════════════
Widget _buildField(String label, String hint, {bool isNumber = false, int maxLines = 1, bool isReadOnly = false, bool styleAsMono = false, int? maxLength, TextEditingController? controller, String? initialValue}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        readOnly: isReadOnly,
        style: TextStyle(fontFamily: styleAsMono ? 'monospace' : null, color: isReadOnly ? AppColors.gray600 : AppColors.foreground),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '', // Hide counter
          hintStyle: const TextStyle(color: AppColors.gray400),
          filled: true, fillColor: isReadOnly ? AppColors.gray100 : AppColors.gray50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ],
  );
}

Widget _buildDropdownField(String label, List<String> items, {bool isReadOnly = false, String? value, ValueChanged<String?>? onChanged}) {
  final safeItems = <String>{...items};
  if (value != null && value.isNotEmpty) safeItems.add(value);
  final itemList = safeItems.toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: (value != null && value.isNotEmpty) ? value : (itemList.isNotEmpty ? itemList.first : null),
        items: itemList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: isReadOnly ? null : (onChanged ?? (_) {}),
        icon: isReadOnly ? const SizedBox.shrink() : null, // Hide internal icon if readonly
        style: TextStyle(color: isReadOnly ? AppColors.gray600 : AppColors.foreground),
        decoration: InputDecoration(
          filled: true, fillColor: isReadOnly ? AppColors.gray100 : AppColors.gray50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ],
  );
}

Widget _buildFormButtons(BuildContext context, bool loading, VoidCallback onSave) {
  return Row(
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
        onPressed: loading ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Simpan'),
      ),
    ],
  );
}

