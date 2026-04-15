// File: lib/features/kurikulum/screens/master_mapel.dart
// ===========================================
// MASTER MAPEL (Subject Management)
// Translated from MasterMapel.tsx + SubjectFormModal.tsx
// CRUD table with search, pagination, modal forms
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/table_pagination.dart';
import '../../../shared_widgets/delete_confirmation_modal.dart';
import '../../../shared_widgets/success_toast.dart';

class MasterMapel extends StatefulWidget {
  const MasterMapel({super.key});

  @override
  State<MasterMapel> createState() => _MasterMapelState();
}

class _MasterMapelState extends State<MasterMapel> {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  String _searchQuery = '';
  bool _showSuccessToast = false;
  String _successMessage = '';

  List<Map<String, String>> get _filteredData {
    if (_searchQuery.isEmpty) return _subjectsData;
    final q = _searchQuery.toLowerCase();
    return _subjectsData
        .where((s) =>
            s['code']!.toLowerCase().contains(q) ||
            s['name']!.toLowerCase().contains(q) ||
            s['category']!.toLowerCase().contains(q))
        .toList();
  }

  void _showSubjectModal({bool isEdit = false, Map<String, String>? data}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _SubjectFormModal(isEdit: isEdit, initialData: data),
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          _successMessage = isEdit
              ? 'Mata pelajaran berhasil diperbarui'
              : 'Mata pelajaran baru berhasil ditambahkan';
          _showSuccessToast = true;
        });
      }
    });
  }

  void _handleDelete(String name) {
    DeleteConfirmationModal.show(
      context,
      title: 'Konfirmasi Penghapusan',
      message: 'Apakah Anda yakin ingin menghapus mata pelajaran ini? Tindakan ini tidak dapat dibatalkan.',
      itemName: name,
      onConfirm: () {
        setState(() {
          _successMessage = 'Mata pelajaran "$name" berhasil dihapus';
          _showSuccessToast = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredData;
    final total = filtered.length;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, total);
    final pageData = filtered.sublist(start, end);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Title ──
            const Text(
              'Master Mata Pelajaran',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola daftar mata pelajaran yang tersedia di kurikulum sekolah',
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
                        hintText: 'Cari mapel...',
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
                  onPressed: () => _showSubjectModal(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Mapel Baru'),
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

            // ── Data Table ──
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
                    // Header
                    Container(
                      color: AppColors.gray50,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('Kode Mapel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                          Expanded(flex: 3, child: Text('Nama Mapel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                          Expanded(flex: 2, child: Text('Kategori', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                          Expanded(flex: 1, child: Text('KKM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground))),
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
                          final s = pageData[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(s['code']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: AppColors.foreground))),
                                Expanded(flex: 3, child: Text(s['name']!, style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _categoryColor(s['category']!),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        s['category']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _categoryTextColor(s['category']!),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(flex: 1, child: Text(s['kkm']!, style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                                SizedBox(
                                  width: 80,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600),
                                        onPressed: () => _showSubjectModal(isEdit: true, data: s),

                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600),
                                        onPressed: () => _handleDelete(s['name']!),

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
                    TablePagination(
                      currentPage: _currentPage,
                      totalItems: total,
                      itemsPerPage: _itemsPerPage,
                      onPageChange: (p) => setState(() => _currentPage = p),
                      onItemsPerPageChange: (n) => setState(() { _itemsPerPage = n; _currentPage = 1; }),
                      itemName: 'mata pelajaran',
                    ),
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
// SUBJECT FORM MODAL — from SubjectFormModal.tsx
// ═══════════════════════════════════════════════
class _SubjectFormModal extends StatefulWidget {
  final bool isEdit;
  final Map<String, String>? initialData;
  const _SubjectFormModal({this.isEdit = false, this.initialData});

  @override
  State<_SubjectFormModal> createState() => _SubjectFormModalState();
}

class _SubjectFormModalState extends State<_SubjectFormModal> {
  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _kkmCtrl;
  late TextEditingController _descCtrl;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initialData?['code'] ?? '');
    _nameCtrl = TextEditingController(text: widget.initialData?['name'] ?? '');
    _kkmCtrl = TextEditingController(text: widget.initialData?['kkm'] ?? '75');
    _descCtrl = TextEditingController(text: widget.initialData?['description'] ?? '');
    _selectedCategory = widget.initialData?['category'];
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _kkmCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isEdit ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran Baru',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),

          // Code
          _buildLabel('Kode Mapel'),
          const SizedBox(height: 8),
          TextField(
            controller: _codeCtrl,
            decoration: _inputDeco('Contoh: MTK-01'),
          ),
          const SizedBox(height: 16),

          // Name
          _buildLabel('Nama Mata Pelajaran'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: _inputDeco('Contoh: Matematika Wajib'),
          ),
          const SizedBox(height: 16),

          // Category
          _buildLabel('Kategori'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            items: const [
              DropdownMenuItem(value: 'Wajib', child: Text('Wajib')),
              DropdownMenuItem(value: 'Peminatan', child: Text('Peminatan')),
              DropdownMenuItem(value: 'Muatan Lokal', child: Text('Muatan Lokal')),
              DropdownMenuItem(value: 'Ekstrakurikuler', child: Text('Ekstrakurikuler')),
            ],
            onChanged: (v) => setState(() => _selectedCategory = v),
            decoration: _inputDeco('Pilih kategori'),
          ),
          const SizedBox(height: 16),

          // KKM
          _buildLabel('KKM (Kriteria Ketuntasan Minimal)'),
          const SizedBox(height: 8),
          TextField(
            controller: _kkmCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDeco('Contoh: 75'),
          ),
          const SizedBox(height: 16),

          // Description
          _buildLabel('Deskripsi'),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: _inputDeco('Deskripsi singkat mata pelajaran'),
          ),
          const SizedBox(height: 24),

          // Buttons
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
                child: Text(widget.isEdit ? 'Simpan Perubahan' : 'Tambah Mapel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground));

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray400),
        filled: true, fillColor: AppColors.gray50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
}

// ═══════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════
Color _categoryColor(String category) {
  switch (category) {
    case 'Wajib': return const Color(0xFFDBEAFE);
    case 'Peminatan': return const Color(0xFFF3E8FF);
    case 'Muatan Lokal': return const Color(0xFFDCFCE7);
    case 'Ekstrakurikuler': return const Color(0xFFFFEDD5);
    default: return AppColors.gray100;
  }
}

Color _categoryTextColor(String category) {
  switch (category) {
    case 'Wajib': return const Color(0xFF1D4ED8);
    case 'Peminatan': return const Color(0xFF7C3AED);
    case 'Muatan Lokal': return const Color(0xFF16A34A);
    case 'Ekstrakurikuler': return const Color(0xFFEA580C);
    default: return AppColors.gray700;
  }
}

// ═══════════════════════════════════════════════
// STATIC DATA
// ═══════════════════════════════════════════════
final List<Map<String, String>> _subjectsData = [
  {'code': 'MTK-01', 'name': 'Matematika Wajib', 'category': 'Wajib', 'kkm': '75', 'description': 'Matematika dasar untuk semua jurusan'},
  {'code': 'MTK-02', 'name': 'Matematika Peminatan', 'category': 'Peminatan', 'kkm': '78', 'description': 'Matematika lanjutan untuk IPA'},
  {'code': 'FIS-01', 'name': 'Fisika', 'category': 'Peminatan', 'kkm': '75', 'description': 'Ilmu fisika untuk jurusan IPA'},
  {'code': 'KIM-01', 'name': 'Kimia', 'category': 'Peminatan', 'kkm': '75', 'description': 'Ilmu kimia untuk jurusan IPA'},
  {'code': 'BIO-01', 'name': 'Biologi', 'category': 'Peminatan', 'kkm': '75', 'description': 'Ilmu biologi untuk jurusan IPA'},
  {'code': 'BIN-01', 'name': 'Bahasa Indonesia', 'category': 'Wajib', 'kkm': '78', 'description': 'Bahasa Indonesia wajib'},
  {'code': 'BIG-01', 'name': 'Bahasa Inggris', 'category': 'Wajib', 'kkm': '75', 'description': 'Bahasa Inggris wajib'},
  {'code': 'SEJ-01', 'name': 'Sejarah Indonesia', 'category': 'Wajib', 'kkm': '75', 'description': 'Sejarah Indonesia wajib'},
  {'code': 'PKN-01', 'name': 'Pendidikan Kewarganegaraan', 'category': 'Wajib', 'kkm': '78', 'description': 'PKN wajib'},
  {'code': 'PAI-01', 'name': 'Pendidikan Agama Islam', 'category': 'Wajib', 'kkm': '78', 'description': 'Pendidikan agama'},
  {'code': 'MUL-01', 'name': 'Bahasa Sunda', 'category': 'Muatan Lokal', 'kkm': '70', 'description': 'Bahasa daerah'},
  {'code': 'EKS-01', 'name': 'Robotika', 'category': 'Ekstrakurikuler', 'kkm': '70', 'description': 'Kegiatan robotika'},
];
