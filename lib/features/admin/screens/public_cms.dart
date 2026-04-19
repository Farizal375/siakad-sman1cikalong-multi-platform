// File: lib/features/admin/screens/public_cms.dart
// ===========================================
// PUBLIC CMS SCREEN
// Connected to /cms API endpoints
// Tabbed interface: News, Achievements, Videos tables
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../shared_widgets/table_pagination.dart';
import '../../../shared_widgets/delete_confirmation_modal.dart';
import '../../../shared_widgets/success_toast.dart';

class PublicCMS extends StatefulWidget {
  const PublicCMS({super.key});

  @override
  State<PublicCMS> createState() => _PublicCMSState();
}

class _PublicCMSState extends State<PublicCMS> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSuccessToast = false;
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header ──
            const Text(
              'Manajemen Konten Publik',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola informasi yang ditampilkan pada halaman landing tamu',
              style: TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 32),

            // ── Tabs ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.gray600,
                labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Berita & Pengumuman'),
                  Tab(text: 'Prestasi Siswa'),
                  Tab(text: 'Video Aktivitas'),
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
                        hintText: 'Cari konten...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
                        filled: true,
                        fillColor: Colors.white,
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
                  onPressed: () {
                    final index = _tabController.index;
                    if (index == 0) {
                      NewsFormModal.show(context, onSaved: () => setState(() {}));
                    } else if (index == 1) {
                      AchievementFormModal.show(context, onSaved: () => setState(() {}));
                    } else if (index == 2) {
                      VideoFormModal.show(context, onSaved: () => setState(() {}));
                    }
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Konten Baru'),
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

            // ── Tab Content (Data Tables) ──
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CmsContentTab(type: 'BERITA', onDelete: (id, name) => _handleDelete(id, 'Berita', name)),
                    _CmsContentTab(type: 'PRESTASI', onDelete: (id, name) => _handleDelete(id, 'Prestasi', name)),
                    _CmsContentTab(type: 'VIDEO', onDelete: (id, name) => _handleDelete(id, 'Video', name)),
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

  void _handleDelete(String id, String type, String name) {
    DeleteConfirmationModal.show(
      context,
      title: 'Konfirmasi Penghapusan Konten',
      message: 'Apakah Anda yakin ingin menghapus konten ini? Konten yang dihapus tidak dapat dipulihkan.',
      itemName: name,
      onConfirm: () async {
        try {
          await ApiService.deleteContent(id);
          setState(() {
            _successMessage = '$type "$name" berhasil dihapus';
            _showSuccessToast = true;
          });
        } catch (_) {}
      },
    );
  }
}

// ═══════════════════════════════════════════════
// UNIFIED CMS CONTENT TAB — connected to API
// ═══════════════════════════════════════════════
class _CmsContentTab extends StatefulWidget {
  final String type;
  final void Function(String id, String name) onDelete;
  const _CmsContentTab({required this.type, required this.onDelete});

  @override
  State<_CmsContentTab> createState() => _CmsContentTabState();
}

class _CmsContentTabState extends State<_CmsContentTab> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  bool _loading = true;
  List<Map<String, dynamic>> _data = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService.getAllContent(tipe: widget.type);
      final items = response['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _data = items.map<Map<String, dynamic>>((item) => {
            'id': item['id'] ?? '',
            'title': item['title'] ?? '-',
            'content': item['content'] ?? '',
            'imageUrl': item['imageUrl'] ?? '',
            'videoUrl': item['videoUrl'] ?? '',
            'isActive': item['isActive'] ?? false,
            'createdAt': item['createdAt'] ?? '',
            'type': item['type'] ?? widget.type,
          }).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    final totalItems = _data.length;
    final start = ((_currentPage - 1) * _itemsPerPage).clamp(0, totalItems);
    final end = (start + _itemsPerPage).clamp(0, totalItems);
    final pageData = _data.sublist(start, end);

    return Column(
      children: [
        // Header row
        Container(
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              const SizedBox(width: 80, child: Text('Media', style: _hdrStyle)),
              const Expanded(flex: 3, child: Text('Judul', style: _hdrStyle)),
              const Expanded(flex: 2, child: Text('Konten', style: _hdrStyle)),
              const Expanded(flex: 1, child: Text('Tanggal', style: _hdrStyle)),
              const Expanded(flex: 1, child: Text('Status', style: _hdrStyle)),
              const SizedBox(width: 120, child: Text('Aksi', style: _hdrStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: pageData.isEmpty
            ? const Center(child: Text('Belum ada konten', style: TextStyle(color: AppColors.gray500)))
            : ListView.separated(
              itemCount: pageData.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
              itemBuilder: (_, i) {
                final item = pageData[i];
                final isActive = item['isActive'] == true;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      // Media icon
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.gray200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.type == 'VIDEO' ? Icons.play_circle_fill_rounded :
                          widget.type == 'PRESTASI' ? Icons.emoji_events :
                          Icons.article,
                          color: AppColors.gray400, size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        flex: 3,
                        child: Text(item['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.foreground)),
                      ),
                      // Content excerpt
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['content'] ?? '-',
                          style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Date
                      Expanded(flex: 1, child: Text(_formatDate(item['createdAt'] ?? ''), style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                      // Status
                      Expanded(
                        flex: 1,
                        child: _StatusBadge(
                          label: isActive ? 'Terpublikasi' : 'Draft',
                          isActive: isActive,
                        ),
                      ),
                      // Actions
                      SizedBox(
                        width: 120,
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.gray600),
                              onPressed: () async {
                                try {
                                  await ApiService.toggleContent(item['id']);
                                  _loadData();
                                } catch (_) {}
                              },
                              splashRadius: 18,
                              tooltip: isActive ? 'Nonaktifkan' : 'Aktifkan',
                            ),
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () {}, splashRadius: 18, tooltip: 'Edit'),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600),
                              onPressed: () {
                                widget.onDelete(item['id'], item['title'] ?? '-');
                                Future.delayed(const Duration(seconds: 1), () => _loadData());
                              },
                              splashRadius: 18,
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
          totalItems: totalItems,
          itemsPerPage: _itemsPerPage,
          onPageChange: (p) => setState(() => _currentPage = p),
          onItemsPerPageChange: (n) => setState(() { _itemsPerPage = n; _currentPage = 1; }),
          itemName: 'konten',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;
  const _StatusBadge({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.green500 : AppColors.gray500,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? AppColors.green700 : AppColors.gray700,
        )),
      ],
    );
  }
}

const _hdrStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground);

// ═══════════════════════════════════════════════
// MODAL COMPONENTS — connected to API
// ═══════════════════════════════════════════════

class NewsFormModal extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback? onSaved;
  const NewsFormModal({super.key, this.initialData, this.onSaved});

  static void show(BuildContext context, {Map<String, dynamic>? initialData, VoidCallback? onSaved}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
          child: NewsFormModal(initialData: initialData, onSaved: onSaved),
        ),
      ),
    );
  }

  @override
  State<NewsFormModal> createState() => _NewsFormModalState();
}

class _NewsFormModalState extends State<NewsFormModal> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData?['title']);
    _contentCtrl = TextEditingController(text: widget.initialData?['content'] ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = {
        'type': 'BERITA',
        'title': _titleCtrl.text,
        'content': _contentCtrl.text,
        'isActive': true,
      };
      if (widget.initialData != null) {
        await ApiService.updateContent(widget.initialData!['id'], data);
      } else {
        await ApiService.createContent(data);
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.initialData == null ? 'Tambah Pengumuman Baru' : 'Edit Pengumuman',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Judul Berita'),
                TextField(controller: _titleCtrl, decoration: _inputDecoration('Masukkan judul berita...')),
                const SizedBox(height: 20),
                _buildLabel('Konten Berita'),
                TextField(controller: _contentCtrl, maxLines: 6, decoration: _inputDecoration('Tulis konten berita...')),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                child: const Text('Batal', style: TextStyle(color: AppColors.gray600, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_saving ? 'Menyimpan...' : 'Simpan & Publikasikan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AchievementFormModal extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback? onSaved;
  const AchievementFormModal({super.key, this.initialData, this.onSaved});

  static void show(BuildContext context, {Map<String, dynamic>? initialData, VoidCallback? onSaved}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AchievementFormModal(initialData: initialData, onSaved: onSaved),
        ),
      ),
    );
  }

  @override
  State<AchievementFormModal> createState() => _AchievementFormModalState();
}

class _AchievementFormModalState extends State<AchievementFormModal> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData?['title']);
    _descCtrl = TextEditingController(text: widget.initialData?['content'] ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = {
        'type': 'PRESTASI',
        'title': _titleCtrl.text,
        'content': _descCtrl.text,
        'isActive': true,
      };
      if (widget.initialData != null) {
        await ApiService.updateContent(widget.initialData!['id'], data);
      } else {
        await ApiService.createContent(data);
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.initialData == null ? 'Tambah Prestasi Baru' : 'Edit Prestasi',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nama Prestasi'),
                TextField(controller: _titleCtrl, decoration: _inputDecoration('Contoh: Olimpiade Sains Nasional')),
                const SizedBox(height: 20),
                _buildLabel('Deskripsi Singkat'),
                TextField(controller: _descCtrl, maxLines: 3, decoration: _inputDecoration('Keterangan singkat...')),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppColors.gray600, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(_saving ? 'Menyimpan...' : 'Simpan Data', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoFormModal extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback? onSaved;
  const VideoFormModal({super.key, this.initialData, this.onSaved});

  static void show(BuildContext context, {Map<String, dynamic>? initialData, VoidCallback? onSaved}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: VideoFormModal(initialData: initialData, onSaved: onSaved),
        ),
      ),
    );
  }

  @override
  State<VideoFormModal> createState() => _VideoFormModalState();
}

class _VideoFormModalState extends State<VideoFormModal> {
  late TextEditingController _titleCtrl;
  late TextEditingController _urlCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData?['title']);
    _urlCtrl = TextEditingController(text: widget.initialData?['videoUrl'] ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = {
        'type': 'VIDEO',
        'title': _titleCtrl.text,
        'videoUrl': _urlCtrl.text,
        'isActive': true,
      };
      if (widget.initialData != null) {
        await ApiService.updateContent(widget.initialData!['id'], data);
      } else {
        await ApiService.createContent(data);
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.initialData == null ? 'Tambah Video Baru' : 'Edit Video',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Judul Video'),
                TextField(controller: _titleCtrl, decoration: _inputDecoration('Contoh: Highlight Acara Kelulusan 2026')),
                const SizedBox(height: 20),
                _buildLabel('URL Video (YouTube / Link Langsung)'),
                TextField(controller: _urlCtrl, decoration: _inputDecoration('Contoh: https://youtube.com/watch?v=...')),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppColors.gray600, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(_saving ? 'Menyimpan...' : 'Simpan Video', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
);

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
