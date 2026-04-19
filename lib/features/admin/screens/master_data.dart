// File: lib/features/admin/screens/master_data.dart
// ===========================================
// MASTER DATA SCREEN
// Translated from MasterData.tsx
// Tabbed: Academic Year, Semesters, Classrooms, Classes, Students, Teachers
// With Toggle Switches, Form Modals, Import/Export
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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

  void _showFormModal({String? mode, int? tabIndex, String? entityId}) {
    final tab = tabIndex ?? _tabController.index;
    final isEdit = mode == 'edit';
    final isView = mode == 'view';
    Widget modalContent;

    switch (tab) {
      case 0:
        modalContent = _StudentTeacherFormModal(isEdit: isEdit, isView: isView, isTeacher: false, entityId: entityId);
        break;
      case 1:
        modalContent = _StudentTeacherFormModal(isEdit: isEdit, isView: isView, isTeacher: true, entityId: entityId);
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
      case 0: return 'Tambah Data Siswa';
      case 1: return 'Tambah Data Guru';
      default: return 'Tambah Data';
    }
  }

  bool get _showImportExport => true;

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
                    _UsersTable(onDelete: (name) => _handleDelete('Data Siswa', name), onEdit: (id) => _showFormModal(mode: 'edit', tabIndex: 0, entityId: id), onView: (id) => _showFormModal(mode: 'view', tabIndex: 0, entityId: id), itemName: 'siswa', roleFilter: 'Siswa', columns: const ['NISN', 'Nama Lengkap', 'Email', 'Status', 'Aksi']),
                    _UsersTable(onDelete: (name) => _handleDelete('Data Guru', name), onEdit: (id) => _showFormModal(mode: 'edit', tabIndex: 1, entityId: id), onView: (id) => _showFormModal(mode: 'view', tabIndex: 1, entityId: id), itemName: 'guru', roleFilter: 'Guru Mapel', columns: const ['NIP', 'Nama Lengkap', 'Email', 'Status', 'Aksi']),
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
          _data = items.map<Map<String, dynamic>>((item) => {
            'id': item['id'] ?? '',
            'idNumber': item['idNumber'] ?? '-',
            'name': item['name'] ?? '',
            'email': item['email'] ?? '',
            'status': item['status'] ?? 'Aktif',
          }).toList();
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
// FORM MODALS — Student / Teacher Profile
// ═══════════════════════════════════════════════
class _StudentTeacherFormModal extends StatefulWidget {
  final bool isEdit;
  final bool isView;
  final bool isTeacher;
  final String? entityId;
  const _StudentTeacherFormModal({this.isEdit = false, this.isView = false, required this.isTeacher, this.entityId});

  @override
  State<_StudentTeacherFormModal> createState() => _StudentTeacherFormModalState();
}

class _StudentTeacherFormModalState extends State<_StudentTeacherFormModal> {
  bool _loading = false;
  final _idController = TextEditingController();
  final _nikController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _ibuController = TextEditingController(); // for Siswa
  final _alamatController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _kodePosController = TextEditingController();

  String? _statusPegawai = 'ASN/PNS';
  String? _golongan = 'III/a';
  String? _angkatan = '2026';
  String? _jk = 'Laki-laki';
  String? _agama = 'Islam';
  String? _statusPerkawinan = 'Belum Menikah';
  String? _provinsi = 'Jawa Barat';
  String? _kota = 'Kab. Cianjur';
  String? _kecamatan = 'Cikalong';
  String? _kelurahan = 'Sukamaju';

  @override
  void initState() {
    super.initState();
    if ((widget.isEdit || widget.isView) && widget.entityId != null) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getUserById(widget.entityId!);
      if (res['data'] != null) {
        final d = res['data'];
        final p = d['profile'] ?? {};
        setState(() {
          _idController.text = d['idNumber'] ?? '';
          _nameController.text = d['name'] ?? '';
          _emailController.text = d['email'] ?? '';
          _jk = p['jenis_kelamin'] == 'P' ? 'Perempuan' : 'Laki-laki';
          _agama = p['agama'] ?? 'Islam';
          _tempatLahirController.text = p['tempat_lahir'] ?? '';
          _tanggalLahirController.text = p['tanggal_lahir'] ?? '';
          _nikController.text = p['nik'] ?? '';
          _alamatController.text = p['detail_alamat'] ?? '';
          _rtController.text = p['rt'] ?? '';
          _rwController.text = p['rw'] ?? '';
          _kodePosController.text = p['kode_pos'] ?? '';
          _provinsi = p['provinsi'] ?? 'Jawa Barat';
          _kota = p['kota_kabupaten'] ?? 'Kab. Cianjur';
          _kecamatan = p['kecamatan'] ?? 'Cikalong';
          _kelurahan = p['kelurahan'] ?? 'Sukamaju';
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    // Collect data to send
    final payload = {
      'name': _nameController.text,
      'email': _emailController.text,
      'idNumber': _idController.text,
      'role': widget.isTeacher ? 'Guru Mapel' : 'Siswa',
      'password': 'password123', // default password for creation
      'status': 'Aktif',
      'profile': {
        'nik': _nikController.text,
        'jenis_kelamin': _jk == 'Perempuan' ? 'P' : 'L',
        'agama': _agama,
        'tempat_lahir': _tempatLahirController.text,
        'tanggal_lahir': _tanggalLahirController.text,
        'detail_alamat': _alamatController.text,
        'rt': _rtController.text,
        'rw': _rwController.text,
        'kode_pos': _kodePosController.text,
        'provinsi': _provinsi,
        'kota_kabupaten': _kota,
        'kecamatan': _kecamatan,
        'kelurahan': _kelurahan,
      }
    };
    
    setState(() => _loading = true);
    try {
      if (widget.isEdit && widget.entityId != null) {
        await ApiService.updateUser(widget.entityId!, payload);
      } else {
        await ApiService.createUser(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && widget.isView) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
    
    final type = widget.isTeacher ? 'Guru' : 'Siswa';
    final idLabel = widget.isTeacher ? 'NIP/ID Staf' : 'NISN';
    final title = widget.isView ? 'Detail Data $type' : (widget.isEdit ? 'Edit Data $type' : 'Tambah Data $type');

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
                      if (!widget.isView)
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
                    Expanded(child: _buildField(idLabel, 'Masukkan $idLabel', isReadOnly: widget.isView, styleAsMono: true, controller: _idController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('NIK (16 Digit)', 'KTP / KK', isReadOnly: widget.isView, styleAsMono: true, maxLength: 16, controller: _nikController)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('Nama Lengkap', 'Beserta gelar jika ada', isReadOnly: widget.isView, controller: _nameController),
                const SizedBox(height: 16),
                
                // Fields that differ by Role
                if (widget.isTeacher) ...[
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField('Status Pegawai', ['ASN/PNS', 'PPPK', 'Honorer', 'GTY'], isReadOnly: widget.isView, value: _statusPegawai, onChanged: (v) => setState(() => _statusPegawai = v))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdownField('Golongan', ['-', 'III/a', 'III/b', 'IV/a', 'Non-Golongan'], isReadOnly: widget.isView, value: _golongan, onChanged: (v) => setState(() => _golongan = v))),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField('Angkatan', ['2024', '2025', '2026'], isReadOnly: widget.isView, value: _angkatan, onChanged: (v) => setState(() => _angkatan = v))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Nama Ibu Kandung', 'Wajib diisi', isReadOnly: widget.isView, controller: _ibuController)),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Section: Data Personal
                const Text('Informasi Personal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Jenis Kelamin', ['Laki-laki', 'Perempuan'], isReadOnly: widget.isView, value: _jk, onChanged: (v) => setState(() => _jk = v))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Agama', ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'], isReadOnly: widget.isView, value: _agama, onChanged: (v) => setState(() => _agama = v))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField('Tempat Lahir', 'Kota kelahiran', isReadOnly: widget.isView, controller: _tempatLahirController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Tanggal Lahir', 'DD/MM/YYYY', isReadOnly: widget.isView, controller: _tanggalLahirController)),
                  ],
                ),
                if (widget.isTeacher) ...[
                   const SizedBox(height: 16),
                   Row(
                    children: [
                      Expanded(child: _buildDropdownField('Status Perkawinan', ['Belum Menikah', 'Menikah', 'Cerai Hidup', 'Cerai Mati'], isReadOnly: widget.isView, value: _statusPerkawinan, onChanged: (v) => setState(() => _statusPerkawinan = v))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Email', 'Alamat email aktif', isReadOnly: widget.isView, controller: _emailController)),
                    ],
                  ),
                ] else ...[
                   const SizedBox(height: 16),
                   _buildField('Email', 'Alamat email aktif', isReadOnly: widget.isView, controller: _emailController),
                ],
                const SizedBox(height: 24),

                // Section: Informasi Domisili
                const Text('Informasi Domisili (Sesuai User Profile)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Provinsi', ['DKI Jakarta', 'Jawa Barat', 'Jawa Tengah'], isReadOnly: widget.isView, value: _provinsi, onChanged: (v) => setState(() => _provinsi = v))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Kota/Kabupaten', ['Jakarta Selatan', 'Jakarta Utara', 'Kab. Cianjur', 'Kota Padang'], isReadOnly: widget.isView, value: _kota, onChanged: (v) => setState(() => _kota = v))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Kecamatan', ['Kebayoran Baru', 'Kebayoran Lama', 'Cikalong'], isReadOnly: widget.isView, value: _kecamatan, onChanged: (v) => setState(() => _kecamatan = v))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Kelurahan', ['Senayan', 'Melawai', 'Sukamaju'], isReadOnly: widget.isView, value: _kelurahan, onChanged: (v) => setState(() => _kelurahan = v))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('Alamat Lengkap', 'Jl. Nama Jalan, Nama Gedung/Komplek', maxLines: 2, isReadOnly: widget.isView, controller: _alamatController),
                const SizedBox(height: 16),
                Row(
                  children: [
                     Expanded(child: _buildField('RT', '001', isNumber: true, maxLength: 3, isReadOnly: widget.isView, controller: _rtController)),
                     const SizedBox(width: 16),
                     Expanded(child: _buildField('RW', '002', isNumber: true, maxLength: 3, isReadOnly: widget.isView, controller: _rwController)),
                     const SizedBox(width: 16),
                     Expanded(child: _buildField('Kode Pos', '10270', isNumber: true, maxLength: 5, isReadOnly: widget.isView, controller: _kodePosController)),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Footer (Only if not viewing)
        if (!widget.isView) ...[
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
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
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
                ),
              ],
            ),
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

