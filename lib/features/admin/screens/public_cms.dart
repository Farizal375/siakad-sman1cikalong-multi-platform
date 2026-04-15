// File: lib/features/admin/screens/public_cms.dart
// ===========================================
// PUBLIC CMS SCREEN
// Translated from PublicCMS.tsx
// Tabbed interface: News, Achievements, Videos tables
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
                // Search
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari konten...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
                        filled: true,
                        fillColor: Colors.white,
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
                      NewsFormModal.show(context);
                    } else if (index == 1) {
                      AchievementFormModal.show(context);
                    } else if (index == 2) {
                      VideoFormModal.show(context);
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
                    _NewsTab(onDelete: (name) => _handleDelete('Berita', name)),
                    _AchievementsTab(onDelete: (name) => _handleDelete('Prestasi', name)),
                    _VideosTab(onDelete: (name) => _handleDelete('Video', name)),
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

  void _handleDelete(String type, String name) {
    DeleteConfirmationModal.show(
      context,
      title: 'Konfirmasi Penghapusan Konten',
      message: 'Apakah Anda yakin ingin menghapus konten ini? Konten yang dihapus tidak dapat dipulihkan.',
      itemName: name,
      onConfirm: () {
        setState(() {
          _successMessage = '$type "$name" berhasil dihapus';
          _showSuccessToast = true;
        });
      },
    );
  }
}

// ═══════════════════════════════════════════════
// NEWS TAB
// ═══════════════════════════════════════════════
class _NewsTab extends StatefulWidget {
  final void Function(String name) onDelete;
  const _NewsTab({required this.onDelete});

  @override
  State<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<_NewsTab> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final totalItems = _newsData.length;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, totalItems);
    final pageData = _newsData.sublist(start, end);

    return Column(
      children: [
        // Header row
        Container(
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: const Row(
            children: [
              SizedBox(width: 80, child: Text('Thumbnail', style: _hdrStyle)),
              Expanded(flex: 3, child: Text('Judul Berita', style: _hdrStyle)),
              Expanded(flex: 1, child: Text('Kategori', style: _hdrStyle)),
              Expanded(flex: 1, child: Text('Tanggal', style: _hdrStyle)),
              Expanded(flex: 1, child: Text('Status', style: _hdrStyle)),
              SizedBox(width: 100, child: Text('Aksi', style: _hdrStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: ListView.separated(
            itemCount: pageData.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
            itemBuilder: (_, i) {
              final n = pageData[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, color: AppColors.gray400),
                    ),
                    const SizedBox(width: 16),
                    // Title + Excerpt
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.foreground)),
                          const SizedBox(height: 4),
                          Text(n['excerpt']!, style: const TextStyle(fontSize: 13, color: AppColors.gray500), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Category
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(999)),
                        child: Text(n['category']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1D4ED8))),
                      ),
                    ),
                    // Date
                    Expanded(flex: 1, child: Text(n['date']!, style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                    // Status
                    Expanded(
                      flex: 1,
                      child: _StatusBadge(
                        label: n['status'] == 'Published' ? 'Terpublikasi' : 'Draft',
                        isActive: n['status'] == 'Published',
                      ),
                    ),
                    // Actions
                    SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.gray600), onPressed: () {}, splashRadius: 18, tooltip: 'Lihat'),
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () => NewsFormModal.show(context, initialData: n), splashRadius: 18, tooltip: 'Edit'),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600), onPressed: () => widget.onDelete(n['title']!), splashRadius: 18, tooltip: 'Hapus'),
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
          itemName: 'berita',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// ACHIEVEMENTS TAB (simplified)
// ═══════════════════════════════════════════════
class _AchievementsTab extends StatefulWidget {
  final void Function(String name) onDelete;
  const _AchievementsTab({required this.onDelete});

  @override
  State<_AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<_AchievementsTab> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Container(
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: const Row(
            children: [
              SizedBox(width: 60, child: Text('Ikon', style: _hdrStyle)),
              Expanded(flex: 3, child: Text('Nama Prestasi', style: _hdrStyle)),
              Expanded(flex: 2, child: Text('Penerima', style: _hdrStyle)),
              Expanded(flex: 1, child: Text('Tahun', style: _hdrStyle)),
              Expanded(flex: 1, child: Text('Status', style: _hdrStyle)),
              SizedBox(width: 100, child: Text('Aksi', style: _hdrStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: ListView.separated(
            itemCount: _achievementsData.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
            itemBuilder: (_, i) {
              final a = _achievementsData[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentHover]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a['title']!, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.foreground)),
                      Text(a['description']!, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                    ])),
                    Expanded(flex: 2, child: Text(a['recipient']!, style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                    Expanded(flex: 1, child: Text(a['year']!, style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                    const Expanded(flex: 1, child: _StatusBadge(label: 'Terpublikasi', isActive: true)),
                    SizedBox(
                      width: 100,
                      child: Row(children: [
                        IconButton(icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.gray600), onPressed: () {}, splashRadius: 18),
                        IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () => AchievementFormModal.show(context, initialData: a), splashRadius: 18),
                        IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600), onPressed: () => widget.onDelete(a['title']!), splashRadius: 18),
                      ]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        TablePagination(currentPage: _currentPage, totalItems: _achievementsData.length, itemsPerPage: _itemsPerPage, onPageChange: (p) => setState(() => _currentPage = p), onItemsPerPageChange: (n) => setState(() { _itemsPerPage = n; _currentPage = 1; }), itemName: 'prestasi'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// VIDEOS TAB (simplified)
// ═══════════════════════════════════════════════
class _VideosTab extends StatefulWidget {
  final void Function(String name) onDelete;
  const _VideosTab({required this.onDelete});

  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> with AutomaticKeepAliveClientMixin {
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Container(
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: const Row(
            children: [
              SizedBox(width: 110, child: Text('Thumbnail', style: _hdrStyle)),
              Expanded(flex: 2, child: Text('Judul Video', style: _hdrStyle)),
              Expanded(flex: 2, child: Text('YouTube URL', style: _hdrStyle)),
              Expanded(flex: 1, child: Text('Tanggal', style: _hdrStyle)),
              Expanded(flex: 1, child: Text('Status', style: _hdrStyle)),
              SizedBox(width: 100, child: Text('Aksi', style: _hdrStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: ListView.separated(
            itemCount: _videosData.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
            itemBuilder: (_, i) {
              final v = _videosData[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 96, height: 64,
                      decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.play_circle_fill_rounded, size: 32, color: AppColors.gray400),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v['title']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(v['duration']!, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                    ])),
                    Expanded(flex: 2, child: Text(v['url']!, style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: AppColors.primary))),
                    Expanded(flex: 1, child: Text(v['date']!, style: const TextStyle(fontSize: 14, color: AppColors.foreground))),
                    const Expanded(flex: 1, child: _StatusBadge(label: 'Terpublikasi', isActive: true)),
                    SizedBox(
                      width: 100,
                      child: Row(children: [
                        IconButton(icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.gray600), onPressed: () {}, splashRadius: 18),
                        IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600), onPressed: () => VideoFormModal.show(context, initialData: v), splashRadius: 18),
                        IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray600), onPressed: () => widget.onDelete(v['title']!), splashRadius: 18),
                      ]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        TablePagination(currentPage: _currentPage, totalItems: _videosData.length, itemsPerPage: _itemsPerPage, onPageChange: (p) => setState(() => _currentPage = p), onItemsPerPageChange: (n) => setState(() { _itemsPerPage = n; _currentPage = 1; }), itemName: 'video'),
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
// STATIC DATA
// ═══════════════════════════════════════════════
const List<Map<String, String>> _newsData = [
  {'title': 'Pemenang Pameran Sains Tahunan Diumumkan', 'excerpt': 'Selamat kepada siswa-siswa berbakat kami yang menampilkan proyek-proyek inovatif...', 'category': 'Prestasi', 'date': '28 Mar 2026', 'status': 'Published'},
  {'title': 'Laboratorium STEM Baru Dibuka', 'excerpt': 'Laboratorium STEM berteknologi canggih kini terbuka untuk siswa...', 'category': 'Fasilitas', 'date': '15 Mar 2026', 'status': 'Published'},
  {'title': 'Hasil Kejuaraan Olahraga Musim Semi', 'excerpt': 'Tim atletik kami telah membawa pulang berbagai kejuaraan musim ini...', 'category': 'Olahraga', 'date': '5 Mar 2026', 'status': 'Published'},
];

const List<Map<String, String>> _achievementsData = [
  {'title': 'Olimpiade Sains Nasional', 'description': 'Juara pertama dalam kompetisi Olimpiade Sains Nasional', 'recipient': 'Ahmad Fauzi (Kelas 12A)', 'year': '2026'},
  {'title': 'Penghargaan Keunggulan Akademik', 'description': 'Sekolah berprestasi terbaik di wilayah', 'recipient': 'SMA Negeri 1 Cikalong', 'year': '2025-2026'},
  {'title': 'Kejuaraan Robotika', 'description': 'Juara regional dalam kompetisi robotika tahunan', 'recipient': 'Tim Robotika', 'year': '2026'},
  {'title': 'Sertifikasi Sekolah Hijau', 'description': 'Penghargaan keunggulan praktik keberlanjutan', 'recipient': 'SMA Negeri 1 Cikalong', 'year': '2025'},
];

const List<Map<String, String>> _videosData = [
  {'title': 'Sorotan Hari Olahraga Tahunan', 'url': 'https://youtube.com/watch?v=example1', 'duration': '5:32', 'date': '20 Mar 2026'},
  {'title': 'Pameran Sains 2026 - Inovasi Siswa', 'url': 'https://youtube.com/watch?v=example2', 'duration': '8:15', 'date': '15 Mar 2026'},
  {'title': 'Tur Kampus - Panduan Virtual', 'url': 'https://youtube.com/watch?v=example3', 'duration': '12:40', 'date': '10 Mar 2026'},
];

// ═══════════════════════════════════════════════
// MODAL COMPONENTS
// ═══════════════════════════════════════════════

class NewsFormModal extends StatefulWidget {
  final Map<String, String>? initialData;
  const NewsFormModal({super.key, this.initialData});

  static void show(BuildContext context, {Map<String, String>? initialData}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
          child: NewsFormModal(initialData: initialData),
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
  String _category = '';
  String _status = 'draft';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData?['title']);
    _contentCtrl = TextEditingController(text: widget.initialData?['excerpt'] ?? '');
    _category = widget.initialData?['category'] ?? '';
    _status = widget.initialData?['status']?.toLowerCase() == 'published' ? 'published' : 'draft';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              Text(widget.initialData == null ? 'Tambah Pengumuman Baru' : 'Edit Pengumuman',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        const Divider(height: 1),
        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Judul Berita'),
                TextField(
                  controller: _titleCtrl,
                  decoration: _inputDecoration('Masukkan judul berita...'),
                ),
                const SizedBox(height: 20),
                _buildLabel('Kategori'),
                DropdownButtonFormField<String>(
                  initialValue: _category.isEmpty ? null : _category,
                  hint: const Text('Pilih kategori...'),
                  decoration: _inputDecoration(''),
                  items: const [
                    DropdownMenuItem(value: 'Berita', child: Text('Berita')),
                    DropdownMenuItem(value: 'Prestasi', child: Text('Prestasi')),
                    DropdownMenuItem(value: 'Pengumuman', child: Text('Pengumuman')),
                    DropdownMenuItem(value: 'Fasilitas', child: Text('Fasilitas')),
                    DropdownMenuItem(value: 'Olahraga', child: Text('Olahraga')),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? ''),
                ),
                const SizedBox(height: 20),
                _buildLabel('Konten Berita'),
                TextField(
                  controller: _contentCtrl,
                  maxLines: 6,
                  decoration: _inputDecoration('Tulis konten berita...'),
                ),
                const SizedBox(height: 20),
                _buildLabel('Status Publikasi'),
                Row(
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'draft', label: Text('Draft')),
                        ButtonSegment(value: 'published', label: Text('Terpublikasi')),
                      ],
                      selected: {_status},
                      onSelectionChanged: (v) => setState(() => _status = v.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        selectedForegroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Footer
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
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan & Publikasikan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AchievementFormModal extends StatefulWidget {
  final Map<String, String>? initialData;
  const AchievementFormModal({super.key, this.initialData});

  static void show(BuildContext context, {Map<String, String>? initialData}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AchievementFormModal(initialData: initialData),
        ),
      ),
    );
  }

  @override
  State<AchievementFormModal> createState() => _AchievementFormModalState();
}

class _AchievementFormModalState extends State<AchievementFormModal> {
  late TextEditingController _titleCtrl;
  late TextEditingController _recipientCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData?['title']);
    _recipientCtrl = TextEditingController(text: widget.initialData?['recipient']);
    _yearCtrl = TextEditingController(text: widget.initialData?['year']);
    _descCtrl = TextEditingController(text: widget.initialData?['description']);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _recipientCtrl.dispose();
    _yearCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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
                _buildLabel('Penerima / Individu Terkait'),
                TextField(controller: _recipientCtrl, decoration: _inputDecoration('Contoh: Ahmad Fauzi (Kelas 12A)')),
                const SizedBox(height: 20),
                _buildLabel('Tahun Prestasi'),
                TextField(controller: _yearCtrl, decoration: _inputDecoration('Contoh: 2026')),
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
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Simpan Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  final Map<String, String>? initialData;
  const VideoFormModal({super.key, this.initialData});

  static void show(BuildContext context, {Map<String, String>? initialData}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: VideoFormModal(initialData: initialData),
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

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData?['title']);
    _urlCtrl = TextEditingController(text: widget.initialData?['url']);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
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
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Simpan Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
