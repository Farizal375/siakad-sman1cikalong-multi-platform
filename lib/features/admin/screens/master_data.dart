// File: lib/features/admin/screens/master_data.dart
// ===========================================
// MASTER DATA SCREEN
// Translated from MasterData.tsx
// Tabbed: Academic Year, Semesters, Classrooms, Classes, Students, Teachers
// With Toggle Switches, Form Modals, Import/Export
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/table_pagination.dart';
import '../../../shared_widgets/delete_confirmation_modal.dart';
import '../../../shared_widgets/success_toast.dart';

class MasterData extends StatefulWidget {
  const MasterData({super.key});

  @override
  State<MasterData> createState() => _MasterDataState();
}

class _MasterDataState extends State<MasterData> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSuccessToast = false;
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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

  void _showFormModal({String? mode, int? tabIndex}) {
    final tab = tabIndex ?? _tabController.index;
    final isEdit = mode == 'edit';
    final isView = mode == 'view';
    Widget modalContent;

    switch (tab) {
      case 0:
        modalContent = _AcademicYearFormModal(isEdit: isEdit);
        break;
      case 1:
        modalContent = _SemesterFormModal(isEdit: isEdit);
        break;
      case 2:
        modalContent = _ClassroomFormModal(isEdit: isEdit);
        break;
      case 3:
        modalContent = _MasterClassFormModal(isEdit: isEdit);
        break;
      case 4:
        modalContent = _StudentTeacherFormModal(isEdit: isEdit, isView: isView, isTeacher: false);
        break;
      case 5:
        modalContent = _StudentTeacherFormModal(isEdit: isEdit, isView: isView, isTeacher: true);
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
          _successMessage = isEdit ? 'Data berhasil diperbarui' : 'Data berhasil ditambahkan';
          _showSuccessToast = true;
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
      case 4: return 'Tambah Data Siswa';
      case 5: return 'Tambah Data Guru';
      default: return 'Tambah Data';
    }
  }

  bool get _showImportExport => _tabController.index == 4 || _tabController.index == 5;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Title ──
            const Text(
              'Manajemen Master Data',
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
                  Tab(text: 'Data Siswa'),
                  Tab(text: 'Data Guru'),
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
                    _AcademicYearTable(onDelete: (name) => _handleDelete('Tahun Ajaran', name), onEdit: () => _showFormModal(mode: 'edit', tabIndex: 0)),
                    _SemesterTable(onDelete: (name) => _handleDelete('Semester', name), onEdit: () => _showFormModal(mode: 'edit', tabIndex: 1)),
                    _GenericTable(columns: const ['Kode Ruang', 'Gedung', 'Kapasitas', 'Status', 'Aksi'], data: _classroomsData, onDelete: (name) => _handleDelete('Ruang Kelas', name), onEdit: () => _showFormModal(mode: 'edit', tabIndex: 2), itemName: 'ruang kelas'),
                    _GenericTable(columns: const ['Nama Kelas', 'Tingkat', 'Wali Kelas', 'Ruangan', 'Aksi'], data: _masterClassesData, onDelete: (name) => _handleDelete('Master Kelas', name), onEdit: () => _showFormModal(mode: 'edit', tabIndex: 3), itemName: 'master kelas'),
                    _GenericTable(columns: const ['NISN', 'Nama Lengkap', 'Jenis Kelamin', 'Email', 'Aksi'], data: _studentsData, onDelete: (name) => _handleDelete('Data Siswa', name), onEdit: () => _showFormModal(mode: 'edit', tabIndex: 4), onView: () => _showFormModal(mode: 'view', tabIndex: 4), itemName: 'siswa'),
                    _GenericTable(columns: const ['NIP', 'Nama Lengkap', 'Jenis Kelamin', 'Email', 'Aksi'], data: _teachersData, onDelete: (name) => _handleDelete('Data Guru', name), onEdit: () => _showFormModal(mode: 'edit', tabIndex: 5), onView: () => _showFormModal(mode: 'view', tabIndex: 5), itemName: 'guru'),
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
  final VoidCallback onEdit;
  const _AcademicYearTable({required this.onDelete, required this.onEdit});

  @override
  State<_AcademicYearTable> createState() => _AcademicYearTableState();
}

class _AcademicYearTableState extends State<_AcademicYearTable> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final List<Map<String, dynamic>> _data = [
    {'code': '2026/2027', 'description': 'Tahun Ajaran 2026/2027', 'isActive': true},
    {'code': '2025/2026', 'description': 'Tahun Ajaran 2025/2026', 'isActive': false},
    {'code': '2024/2025', 'description': 'Tahun Ajaran 2024/2025', 'isActive': false},
    {'code': '2023/2024', 'description': 'Tahun Ajaran 2023/2024', 'isActive': false},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                            onChanged: (val) => setState(() => row['isActive'] = val),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: widget.onEdit, splashRadius: 18, tooltip: 'Edit'),
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
  final VoidCallback onEdit;
  const _SemesterTable({required this.onDelete, required this.onEdit});

  @override
  State<_SemesterTable> createState() => _SemesterTableState();
}

class _SemesterTableState extends State<_SemesterTable> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final List<Map<String, dynamic>> _data = [
    {'name': 'Semester Ganjil', 'academicYear': '2026/2027', 'isActive': true},
    {'name': 'Semester Genap', 'academicYear': '2025/2026', 'isActive': false},
    {'name': 'Semester Ganjil', 'academicYear': '2025/2026', 'isActive': false},
    {'name': 'Semester Genap', 'academicYear': '2024/2025', 'isActive': false},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                            onChanged: (val) => setState(() => row['isActive'] = val),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: widget.onEdit, splashRadius: 18, tooltip: 'Edit'),
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
// GENERIC TABLE WIDGET — for tabs without toggle
// ═══════════════════════════════════════════════
class _GenericTable extends StatefulWidget {
  final List<String> columns;
  final List<List<String>> data;
  final void Function(String name) onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onView;
  final String itemName;

  const _GenericTable({
    required this.columns,
    required this.data,
    required this.onDelete,
    required this.onEdit,
    this.onView,
    required this.itemName,
  });

  @override
  State<_GenericTable> createState() => _GenericTableState();
}

class _GenericTableState extends State<_GenericTable> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final total = widget.data.length;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, total);
    final pageData = widget.data.sublist(start, end);

    final hasActions = widget.columns.last == 'Aksi';
    final dataCols = hasActions ? widget.columns.sublist(0, widget.columns.length - 1) : widget.columns;

    return Column(
      children: [
        // Header
        Container(
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              ...dataCols.map((c) => Expanded(child: Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground)))),
              if (hasActions) SizedBox(width: widget.onView != null ? 120 : 80, child: const Text('Aksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),

        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: pageData.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
            itemBuilder: (_, i) {
              final row = pageData[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    ...List.generate(dataCols.length, (ci) {
                      if (ci < row.length) {
                        // Check if it's a status column
                        if (dataCols[ci] == 'Status') {
                          final isActive = row[ci] == 'Aktif';
                          return Expanded(
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? AppColors.green500 : AppColors.gray500, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(row[ci], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? AppColors.green700 : AppColors.gray700)),
                              ],
                            ),
                          );
                        }
                        return Expanded(
                          child: Text(
                            row[ci],
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.foreground,
                              fontWeight: ci == 0 ? FontWeight.w600 : FontWeight.w400,
                              fontFamily: (dataCols[ci].contains('NIP') || dataCols[ci].contains('NISN')) ? 'monospace' : null,
                            ),
                          ),
                        );
                      }
                      return const Expanded(child: SizedBox());
                    }),
                    if (hasActions)
                      SizedBox(
                        width: widget.onView != null ? 120 : 80,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.onView != null) IconButton(icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.gray600), onPressed: widget.onView, splashRadius: 18, tooltip: 'Lihat Detail'),
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: widget.onEdit, splashRadius: 18, tooltip: 'Edit'),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600), onPressed: () => widget.onDelete(row[0]), splashRadius: 18, tooltip: 'Hapus'),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Pagination
        TablePagination(
          currentPage: _currentPage,
          totalItems: total,
          itemsPerPage: _itemsPerPage,
          onPageChange: (p) => setState(() => _currentPage = p),
          onItemsPerPageChange: (n) => setState(() { _itemsPerPage = n; _currentPage = 1; }),
          itemName: widget.itemName,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// FORM MODALS — Academic Year
// ═══════════════════════════════════════════════
class _AcademicYearFormModal extends StatelessWidget {
  final bool isEdit;
  const _AcademicYearFormModal({this.isEdit = false});

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
              Text(isEdit ? 'Edit Tahun Ajaran' : 'Tambah Tahun Ajaran', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('Nama Tahun Ajaran', 'Contoh: 2026/2027'),
          const SizedBox(height: 16),
          _buildField('Deskripsi', 'Deskripsi tahun ajaran'),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Status Aktif', style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch(value: !isEdit, onChanged: (_) {}, activeThumbColor: AppColors.green500),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormButtons(context),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FORM MODALS — Semester
// ═══════════════════════════════════════════════
class _SemesterFormModal extends StatelessWidget {
  final bool isEdit;
  const _SemesterFormModal({this.isEdit = false});

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
              Text(isEdit ? 'Edit Semester' : 'Tambah Semester', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          _buildDropdownField('Tipe Semester', ['Semester Ganjil', 'Semester Genap']),
          const SizedBox(height: 16),
          _buildDropdownField('Tahun Ajaran', ['2026/2027', '2025/2026', '2024/2025']),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Status Aktif', style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch(value: !isEdit, onChanged: (_) {}, activeThumbColor: AppColors.green500),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormButtons(context),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FORM MODALS — Classroom
// ═══════════════════════════════════════════════
class _ClassroomFormModal extends StatelessWidget {
  final bool isEdit;
  const _ClassroomFormModal({this.isEdit = false});

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
              Text(isEdit ? 'Edit Ruang Kelas' : 'Tambah Ruang Kelas', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('Kode Ruang', 'Contoh: R-101'),
          const SizedBox(height: 16),
          _buildField('Gedung', 'Contoh: Gedung A'),
          const SizedBox(height: 16),
          _buildField('Kapasitas', 'Contoh: 40', isNumber: true),
          const SizedBox(height: 24),
          _buildFormButtons(context),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FORM MODALS — Master Class
// ═══════════════════════════════════════════════
class _MasterClassFormModal extends StatelessWidget {
  final bool isEdit;
  const _MasterClassFormModal({this.isEdit = false});

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
              Text(isEdit ? 'Edit Master Kelas' : 'Tambah Master Kelas', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('Nama Kelas', 'Contoh: X IPA 1'),
          const SizedBox(height: 16),
          _buildDropdownField('Tingkat', ['10', '11', '12']),
          const SizedBox(height: 16),
          _buildDropdownField('Wali Kelas', ['Dr. Siti Nurhaliza', 'Budi Santoso, M.Pd', 'Ahmad Hidayat, S.Pd', 'Rina Kartika, S.Pd']),
          const SizedBox(height: 16),
          _buildDropdownField('Ruangan', ['R-101', 'R-102', 'R-201', 'R-202', 'LAB-01']),
          const SizedBox(height: 24),
          _buildFormButtons(context),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FORM MODALS — Student / Teacher Profile
// ═══════════════════════════════════════════════
class _StudentTeacherFormModal extends StatelessWidget {
  final bool isEdit;
  final bool isView;
  final bool isTeacher;
  const _StudentTeacherFormModal({this.isEdit = false, this.isView = false, required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    final type = isTeacher ? 'Guru' : 'Siswa';
    final idLabel = isTeacher ? 'NIP/ID Staf' : 'NISN';
    final title = isView ? 'Detail Data $type' : (isEdit ? 'Edit Data $type' : 'Tambah Data $type');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        // Body (Scrollable)
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar placeholder
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.gray200,
                        child: Icon(Icons.person, size: 40, color: AppColors.gray400),
                      ),
                      if (!isView)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Section: Identitas Utama
                const Text('Identitas Utama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField(idLabel, 'Masukkan $idLabel', isReadOnly: isView, styleAsMono: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('NIK (16 Digit)', 'KTP / KK', isReadOnly: isView, styleAsMono: true, maxLength: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('Nama Lengkap', 'Beserta gelar jika ada', isReadOnly: isView),
                const SizedBox(height: 16),
                
                // Fields that differ by Role
                if (isTeacher) ...[
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField('Status Pegawai', ['ASN/PNS', 'PPPK', 'Honorer', 'GTY'], isReadOnly: isView)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdownField('Golongan', ['-', 'III/a', 'III/b', 'IV/a', 'Non-Golongan'], isReadOnly: isView)),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField('Angkatan', ['2024', '2025', '2026'], isReadOnly: isView)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Nama Ibu Kandung', 'Wajib diisi', isReadOnly: isView)),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Section: Data Personal
                const Text('Informasi Personal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Jenis Kelamin', ['Laki-laki', 'Perempuan'], isReadOnly: isView)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Agama', ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'], isReadOnly: isView)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField('Tempat Lahir', 'Kota kelahiran', isReadOnly: isView)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Tanggal Lahir', 'DD/MM/YYYY', isReadOnly: isView)),
                  ],
                ),
                if (isTeacher) ...[
                   const SizedBox(height: 16),
                   Row(
                    children: [
                      Expanded(child: _buildDropdownField('Status Perkawinan', ['Belum Menikah', 'Menikah', 'Cerai Hidup', 'Cerai Mati'], isReadOnly: isView)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Email', 'Alamat email aktif', isReadOnly: isView)),
                    ],
                  ),
                ] else ...[
                   const SizedBox(height: 16),
                   _buildField('Email', 'Alamat email aktif', isReadOnly: isView),
                ],
                const SizedBox(height: 24),

                // Section: Informasi Domisili
                const Text('Informasi Domisili (Sesuai User Profile)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Provinsi', ['DKI Jakarta', 'Jawa Barat', 'Jawa Tengah'], isReadOnly: isView)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Kota/Kabupaten', ['Jakarta Selatan', 'Jakarta Utara'], isReadOnly: isView)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Kecamatan', ['Kebayoran Baru', 'Kebayoran Lama'], isReadOnly: isView)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Kelurahan', ['Senayan', 'Melawai'], isReadOnly: isView)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('Alamat Lengkap', 'Jl. Nama Jalan, Nama Gedung/Komplek', maxLines: 2, isReadOnly: isView),
                const SizedBox(height: 16),
                Row(
                  children: [
                     Expanded(child: _buildField('RT', '001', isNumber: true, maxLength: 3, isReadOnly: isView)),
                     const SizedBox(width: 16),
                     Expanded(child: _buildField('RW', '002', isNumber: true, maxLength: 3, isReadOnly: isView)),
                     const SizedBox(width: 16),
                     Expanded(child: _buildField('Kode Pos', '10270', isNumber: true, maxLength: 5, isReadOnly: isView)),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Footer (Only if not viewing)
        if (!isView) ...[
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildFormButtons(context),
          ),
        ] else ...[
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray200,
                    foregroundColor: AppColors.foreground,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// SHARED FORM HELPERS
// ═══════════════════════════════════════════════
Widget _buildField(String label, String hint, {bool isNumber = false, int maxLines = 1, bool isReadOnly = false, bool styleAsMono = false, int? maxLength}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
      const SizedBox(height: 8),
      TextField(
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

Widget _buildDropdownField(String label, List<String> items, {bool isReadOnly = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: isReadOnly ? null : (_) {},
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

Widget _buildFormButtons(BuildContext context) {
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
  );
}

// ═══════════════════════════════════════════════
// STATIC DATA — From React source
// ═══════════════════════════════════════════════
final List<List<String>> _classroomsData = [
  ['R-101', 'Gedung A', '40', 'Aktif'],
  ['R-102', 'Gedung A', '35', 'Aktif'],
  ['R-201', 'Gedung B', '40', 'Aktif'],
  ['R-202', 'Gedung B', '35', 'Aktif'],
  ['LAB-01', 'Gedung C', '30', 'Aktif'],
];

final List<List<String>> _masterClassesData = [
  ['X IPA 1', '10', 'Dr. Siti Nurhaliza', 'R-101'],
  ['X IPA 2', '10', 'Budi Santoso', 'R-102'],
  ['XI IPA 1', '11', 'Ahmad Hidayat', 'R-201'],
  ['XI IPS 1', '11', 'Rina Kartika', 'R-202'],
  ['XII IPA 1', '12', 'Prof. Dr. Ani', 'LAB-01'],
];

final List<List<String>> _studentsData = [
  ['2026001001', 'Ahmad Fauzi', 'L', 'ahmad@student.sch.id'],
  ['2026001002', 'Siti Aisyah', 'P', 'siti@student.sch.id'],
  ['2026001003', 'Budi Pratama', 'L', 'budi@student.sch.id'],
  ['2026001004', 'Dewi Lestari', 'P', 'dewi@student.sch.id'],
  ['2026001005', 'Rizki Hidayat', 'L', 'rizki@student.sch.id'],
];

final List<List<String>> _teachersData = [
  ['NIP198501012020', 'Dr. Siti Nurhaliza, S.Pd', 'P', 'siti@sch.id'],
  ['NIP198601022021', 'Budi Santoso, M.Pd', 'L', 'budi@sch.id'],
  ['NIP197801032019', 'Prof. Dr. Ani Widiastuti', 'P', 'ani@sch.id'],
  ['NIP199001042022', 'Ahmad Hidayat, S.Pd', 'L', 'ahmad@sch.id'],
  ['NIP199201052023', 'Rina Kartika, S.Pd', 'P', 'rina@sch.id'],
];
