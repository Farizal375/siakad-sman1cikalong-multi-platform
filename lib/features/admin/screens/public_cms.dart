// File: lib/features/admin/screens/public_cms.dart
// ===========================================
// PUBLIC CMS SCREEN
// Connected to /cms API endpoints
// Tabbed interface: News, Achievements, Videos tables
// ===========================================

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:image_picker/image_picker.dart';
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

class _PublicCMSState extends State<PublicCMS>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSuccessToast = false;
  String _successMessage = '';
  int _reloadTick = 0;

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
    final isNarrow = MediaQuery.sizeOf(context).width < 720;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header ──
            const Text(
              'Manajemen Konten Publik',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                isScrollable: isNarrow,
                tabAlignment: isNarrow ? TabAlignment.start : null,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.gray600,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final search = TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari konten...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.gray400,
                    ),
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
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                );
                final button = ElevatedButton.icon(
                  onPressed: _openCreateModal,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Konten Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );

                if (constraints.maxWidth < 620) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [search, const SizedBox(height: 12), button],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: search,
                      ),
                    ),
                    const SizedBox(width: 16),
                    button,
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Tab Content (Data Tables) ──
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x15000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CmsContentTab(
                      key: ValueKey('BERITA-$_reloadTick'),
                      type: 'BERITA',
                      onDelete: (id, name) => _handleDelete(id, 'Berita', name),
                      onEditSaved: (msg) => _handleSaved(msg),
                    ),
                    _CmsContentTab(
                      key: ValueKey('PRESTASI-$_reloadTick'),
                      type: 'PRESTASI',
                      onDelete: (id, name) =>
                          _handleDelete(id, 'Prestasi', name),
                      onEditSaved: (msg) => _handleSaved(msg),
                    ),
                    _CmsContentTab(
                      key: ValueKey('VIDEO-$_reloadTick'),
                      type: 'VIDEO',
                      onDelete: (id, name) => _handleDelete(id, 'Video', name),
                      onEditSaved: (msg) => _handleSaved(msg),
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

  void _openCreateModal() {
    final index = _tabController.index;
    if (index == 0) {
      NewsFormModal.show(
        context,
        onSaved: () => _handleSaved('Berita berhasil disimpan'),
      );
    } else if (index == 1) {
      AchievementFormModal.show(
        context,
        onSaved: () => _handleSaved('Prestasi berhasil disimpan'),
      );
    } else if (index == 2) {
      VideoFormModal.show(
        context,
        onSaved: () => _handleSaved('Video berhasil disimpan'),
      );
    }
  }

  void _handleSaved(String message) {
    setState(() {
      _reloadTick++;
      _successMessage = message;
      _showSuccessToast = true;
    });
  }

  void _handleDelete(String id, String type, String name) {
    DeleteConfirmationModal.show(
      context,
      title: 'Konfirmasi Penghapusan Konten',
      message:
          'Apakah Anda yakin ingin menghapus konten ini? Konten yang dihapus tidak dapat dipulihkan.',
      itemName: name,
      onConfirm: () async {
        try {
          await ApiService.deleteContent(id);
          setState(() {
            _reloadTick++;
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
  final void Function(String message)? onEditSaved;
  const _CmsContentTab({
    super.key,
    required this.type,
    required this.onDelete,
    this.onEditSaved,
  });

  @override
  State<_CmsContentTab> createState() => _CmsContentTabState();
}

class _CmsContentTabState extends State<_CmsContentTab>
    with AutomaticKeepAliveClientMixin {
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
          _data = items
              .map<Map<String, dynamic>>(
                (item) => {
                  'id': item['id'] ?? '',
                  'title': item['title'] ?? '-',
                  'content': item['content'] ?? '',
                  'imageUrl': item['imageUrl'] ?? '',
                  'videoUrl': item['videoUrl'] ?? '',
                  'order': item['order'] ?? 0,
                  'isActive': item['isActive'] ?? false,
                  'createdAt': item['createdAt'] ?? '',
                  'type': item['type'] ?? widget.type,
                },
              )
              .toList();
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
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 720;

    if (_loading) return const Center(child: CircularProgressIndicator());

    final totalItems = _data.length;
    final start = ((_currentPage - 1) * _itemsPerPage).clamp(0, totalItems);
    final end = (start + _itemsPerPage).clamp(0, totalItems);
    final pageData = _data.sublist(start, end);

    return Column(
      children: [
        // Header row
        if (!isNarrow)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                const SizedBox(
                  width: 64 + 32,
                  child: Text('Thumbnail', style: _hdrStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.type == 'PRESTASI'
                        ? 'Nama Prestasi'
                        : (widget.type == 'VIDEO'
                              ? 'Judul Video'
                              : 'Judul Berita'),
                    style: _hdrStyle,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    widget.type == 'PRESTASI'
                        ? 'Penerima'
                        : (widget.type == 'VIDEO'
                              ? 'YouTube URL / Link'
                              : 'Kategori'),
                    style: _hdrStyle,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text('Tanggal Posting', style: _hdrStyle),
                ),
                const Expanded(
                  flex: 1,
                  child: Text('Status', style: _hdrStyle),
                ),
                const SizedBox(
                  width: 120,
                  child: Text('Aksi', style: _hdrStyle),
                ),
              ],
            ),
          ),
        if (!isNarrow) const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: pageData.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada konten',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                )
              : ListView.separated(
                  itemCount: pageData.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.gray200),
                  itemBuilder: (_, i) {
                    final item = pageData[i];
                    final isActive = item['isActive'] == true;
                    final imageUrl = ApiService.resolveFileUrl(
                      item['imageUrl']?.toString() ?? '',
                    );
                    final cat = widget.type == 'PRESTASI'
                        ? 'Prestasi'
                        : (widget.type == 'VIDEO' ? 'Video' : 'Berita');

                    return isNarrow
                        ? _CompactCmsCard(
                            item: item,
                            type: widget.type,
                            imageUrl: imageUrl,
                            onPreview: () => _showPreview(item),
                            onEdit: () => _openForm(item),
                            onDelete: () {
                              widget.onDelete(item['id'], item['title'] ?? '-');
                              Future.delayed(
                                const Duration(seconds: 1),
                                () => _loadData(),
                              );
                            },
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.gray200,
                                    borderRadius: BorderRadius.circular(8),
                                    image: imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: imageUrl.isNotEmpty
                                      ? null
                                      : Icon(
                                          widget.type == 'VIDEO'
                                              ? Icons.play_circle_fill_rounded
                                              : widget.type == 'PRESTASI'
                                              ? Icons.emoji_events
                                              : Icons.image_outlined,
                                          color: AppColors.gray400,
                                          size: 28,
                                        ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item['title'] ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.foreground,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.type == 'PRESTASI'
                                            ? (item['videoUrl'] ?? '-')
                                            : _stripHtml(
                                                item['content']?.toString() ??
                                                    '-',
                                              ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.gray500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: widget.type == 'VIDEO'
                                        ? Text(
                                            item['videoUrl'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : widget.type == 'PRESTASI'
                                        ? Text(
                                            item['videoUrl'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.foreground,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : _CategoryBadge(category: cat),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    _formatDate(item['createdAt'] ?? ''),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.foreground,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _StatusBadge(
                                      label: isActive
                                          ? 'Terpublikasi'
                                          : 'Draft',
                                      isActive: isActive,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 20,
                                          color: AppColors.gray500,
                                        ),
                                        onPressed: () => _showPreview(item),
                                        splashRadius: 20,
                                        tooltip: 'Lihat',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: AppColors.gray500,
                                        ),
                                        onPressed: () => _openForm(item),
                                        splashRadius: 20,
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: AppColors.gray500,
                                        ),
                                        onPressed: () {
                                          widget.onDelete(
                                            item['id'],
                                            item['title'] ?? '-',
                                          );
                                          Future.delayed(
                                            const Duration(seconds: 1),
                                            () => _loadData(),
                                          );
                                        },
                                        splashRadius: 20,
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
          onItemsPerPageChange: (n) => setState(() {
            _itemsPerPage = n;
            _currentPage = 1;
          }),
          itemName: widget.type == 'VIDEO'
              ? 'video'
              : widget.type == 'PRESTASI'
              ? 'prestasi'
              : 'berita',
        ),
      ],
    );
  }

  String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    final unescaped =
        html_parser.parse(htmlString).documentElement?.text ?? htmlString;
    final text =
        html_parser.parse(unescaped).documentElement?.text ?? unescaped;
    return text.replaceAll('\n', ' ').trim();
  }

  void _openForm(Map<String, dynamic> item) {
    void onSaved() {
      _loadData();
      final msg = widget.type == 'PRESTASI'
          ? 'Prestasi berhasil diperbarui'
          : (widget.type == 'VIDEO'
                ? 'Video berhasil diperbarui'
                : 'Berita berhasil diperbarui');
      if (widget.onEditSaved != null) {
        widget.onEditSaved!(msg);
      }
    }

    if (widget.type == 'BERITA') {
      NewsFormModal.show(context, initialData: item, onSaved: onSaved);
    } else if (widget.type == 'PRESTASI') {
      AchievementFormModal.show(context, initialData: item, onSaved: onSaved);
    } else {
      VideoFormModal.show(context, initialData: item, onSaved: onSaved);
    }
  }

  void _showPreview(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if ((item['imageUrl']?.toString() ?? '').isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        ApiService.resolveFileUrl(item['imageUrl'].toString()),
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: AppColors.gray100,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.gray400,
                          ),
                        ),
                      ),
                    ),
                  if ((item['videoUrl']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SelectableText(
                      item['videoUrl'].toString(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    item['content']?.toString().isNotEmpty == true
                        ? item['content'].toString()
                        : 'Tidak ada isi konten.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : AppColors.gray100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.green500 : AppColors.gray500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.green700 : AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}

const _hdrStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: AppColors.foreground,
);

String _cmsErrorMessage(Object error) {
  if (error is DioException) {
    final responseData = error.response?.data;
    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }
    if (error.response?.statusCode == 401) {
      return 'Sesi login berakhir. Silakan login kembali.';
    }
    if (error.response?.statusCode == 403) {
      return 'Anda tidak memiliki akses untuk menyimpan konten.';
    }
  }
  return 'Gagal menyimpan konten. Silakan coba lagi.';
}

class _CmsErrorBanner extends StatelessWidget {
  final String message;

  const _CmsErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CmsRichTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;

  const _CmsRichTextEditor({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines = 8,
  });

  @override
  State<_CmsRichTextEditor> createState() => _CmsRichTextEditorState();
}

class _CmsRichTextEditorState extends State<_CmsRichTextEditor> {
  late quill.QuillController _quillCtrl;
  final FocusNode _focusNode = FocusNode();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _initQuill();
    _quillCtrl.addListener(_syncToController);
  }

  void _initQuill() {
    final html = widget.controller.text.trim();
    quill.Document doc;
    if (html.isEmpty) {
      doc = quill.Document();
    } else {
      try {
        final delta = HtmlToDelta().convert(html);
        doc = quill.Document.fromDelta(delta);
      } catch (_) {
        doc = quill.Document();
      }
    }
    _quillCtrl = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _syncToController() {
    if (_syncing) return;
    _syncing = true;
    widget.controller.text = _deltaToHtml(_quillCtrl.document);
    _syncing = false;
  }

  void syncNow() => _syncToController();

  String _deltaToHtml(quill.Document document) {
    final ops = document.toDelta().toList();
    final htmlBuf = StringBuffer();
    final lineBuf = StringBuffer();
    Map<String, dynamic> lineAttrs = {};

    void flushLine() {
      final content = lineBuf.toString();
      lineBuf.clear();
      final a = lineAttrs['align'];
      final lst = lineAttrs['list'];
      lineAttrs = {};
      final style = (a != null && a != 'left') ? ' style="text-align:$a"' : '';
      if (lst == 'ordered') {
        htmlBuf.write('<ol><li$style>$content</li></ol>');
      } else if (lst == 'bullet') {
        htmlBuf.write('<ul><li$style>$content</li></ul>');
      } else if (content.isNotEmpty) {
        htmlBuf.write('<p$style>$content</p>');
      }
    }

    for (final op in ops) {
      if (!op.isInsert) continue;
      final data = op.data;
      final attrs = op.attributes ?? {};
      if (data is String) {
        final parts = data.split('\n');
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) {
            String seg = parts[i]
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;');
            if (attrs['bold'] == true) seg = '<strong>$seg</strong>';
            if (attrs['italic'] == true) seg = '<em>$seg</em>';
            if (attrs['underline'] == true) seg = '<u>$seg</u>';
            if (attrs['link'] != null) {
              seg = '<a href="${attrs['link']}">$seg</a>';
            }
            lineBuf.write(seg);
          }
          if (i < parts.length - 1) {
            if (attrs.containsKey('align')) lineAttrs['align'] = attrs['align'];
            if (attrs.containsKey('list')) lineAttrs['list'] = attrs['list'];
            flushLine();
          }
        }
      }
    }
    if (lineBuf.isNotEmpty) flushLine();
    return htmlBuf.toString();
  }

  @override
  void dispose() {
    _quillCtrl.removeListener(_syncToController);
    _quillCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.gray200)),
              color: AppColors.gray50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: quill.QuillSimpleToolbar(
              controller: _quillCtrl,
              config: const quill.QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showAlignmentButtons: true,
                showListBullets: true,
                showListNumbers: true,
                showLink: true,
                showHeaderStyle: false,
                showFontFamily: false,
                showFontSize: false,
                showBackgroundColorButton: false,
                showColorButton: false,
                showStrikeThrough: false,
                showInlineCode: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                showUndo: true,
                showRedo: true,
                showDividers: true,
              ),
            ),
          ),
          SizedBox(
            height: widget.maxLines * 26.0,
            child: quill.QuillEditor(
              controller: _quillCtrl,
              focusNode: _focusNode,
              scrollController: ScrollController(),
              config: quill.QuillEditorConfig(
                placeholder: widget.hintText,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CmsImagePickerField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;

  const _CmsImagePickerField({
    required this.controller,
    required this.label,
    required this.hintText,
  });

  @override
  State<_CmsImagePickerField> createState() => _CmsImagePickerFieldState();
}

class _CmsImagePickerFieldState extends State<_CmsImagePickerField> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refreshPreview);
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  Future<void> _pickAndUploadImage() async {
    if (_uploading) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1200,
      imageQuality: 88,
    );
    if (image == null) return;

    setState(() {
      _uploading = true;
      _message = null;
      _isError = false;
    });

    try {
      final response = kIsWeb
          ? await ApiService.uploadCmsImageBytes(
              await image.readAsBytes(),
              image.name,
            )
          : await ApiService.uploadCmsImage(image.path);
      final data = response['data'];
      final imageUrl = data is Map ? data['imageUrl']?.toString() ?? '' : '';
      if (imageUrl.isEmpty) {
        throw Exception('Image URL kosong');
      }

      widget.controller.text = imageUrl;
      if (mounted) {
        setState(() {
          _message =
              response['message']?.toString() ?? 'Gambar berhasil diunggah';
          _isError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Gagal mengunggah gambar. Pastikan file JPG, PNG, atau WEBP maksimal 5MB.';
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = widget.controller.text.trim();
    final previewUrl = ApiService.resolveFileUrl(rawUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(widget.label),
        Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.gray50,
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (previewUrl.isNotEmpty)
                Image.network(
                  previewUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.gray400,
                      size: 42,
                    ),
                  ),
                )
              else
                const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.gray400,
                    size: 48,
                  ),
                ),
              Container(
                color: Colors.black.withValues(
                  alpha: previewUrl.isNotEmpty ? 0.18 : 0,
                ),
              ),
              if (_uploading)
                Container(
                  color: Colors.white.withValues(alpha: 0.7),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Row(
                  children: [
                    if (rawUrl.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: _uploading
                            ? null
                            : () => setState(() {
                                widget.controller.clear();
                                _message = null;
                              }),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    ElevatedButton.icon(
                      onPressed: _uploading ? null : _pickAndUploadImage,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _uploading ? 'Mengunggah...' : 'Tambah Gambar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.controller,
          decoration: _inputDecoration(widget.hintText).copyWith(
            prefixIcon: const Icon(Icons.link, color: AppColors.gray400),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(
            _message!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isError ? const Color(0xFFB91C1C) : AppColors.green700,
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactCmsCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String type;
  final String imageUrl;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompactCmsCard({
    required this.item,
    required this.type,
    required this.imageUrl,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = item['isActive'] == true;
    final subtitle = type == 'PRESTASI'
        ? (item['videoUrl'] ?? '-')
        : (type == 'VIDEO'
              ? (item['videoUrl'] ?? '-')
              : item['content']?.toString() ?? '-');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(10),
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl.isNotEmpty
                      ? null
                      : Icon(
                          type == 'VIDEO'
                              ? Icons.play_circle_fill_rounded
                              : type == 'PRESTASI'
                              ? Icons.emoji_events
                              : Icons.image_outlined,
                          color: AppColors.gray400,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']?.toString() ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusBadge(
                  label: isActive ? 'Terpublikasi' : 'Draft',
                  isActive: isActive,
                ),
                _CategoryBadge(
                  category: type == 'PRESTASI'
                      ? 'Prestasi'
                      : type == 'VIDEO'
                      ? 'Video'
                      : 'Berita',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatMobileDate(item['createdAt']?.toString() ?? ''),
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.gray500,
                  ),
                  onPressed: onPreview,
                  splashRadius: 20,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.gray500,
                  ),
                  onPressed: onEdit,
                  splashRadius: 20,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.gray500,
                  ),
                  onPressed: onDelete,
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMobileDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ═══════════════════════════════════════════════
// MODAL COMPONENTS — connected to API
// ═══════════════════════════════════════════════

class NewsFormModal extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback? onSaved;
  const NewsFormModal({super.key, this.initialData, this.onSaved});

  static void show(
    BuildContext context, {
    Map<String, dynamic>? initialData,
    VoidCallback? onSaved,
  }) {
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
  final _contentEditorKey = GlobalKey<_CmsRichTextEditorState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _orderCtrl;
  bool _isPublished = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData?['title']);
    _contentCtrl = TextEditingController(
      text: widget.initialData?['content'] ?? '',
    );
    _imageCtrl = TextEditingController(
      text: widget.initialData?['imageUrl'] ?? '',
    );
    _orderCtrl = TextEditingController(
      text: '${widget.initialData?['order'] ?? 0}',
    );
    _isPublished = widget.initialData?['isActive'] ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _contentEditorKey.currentState?.syncNow();
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final data = {
        'type': 'BERITA',
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text,
        'imageUrl': _imageCtrl.text.trim(),
        'order': int.tryParse(_orderCtrl.text) ?? 0,
        'isActive': _isPublished,
      };
      if (widget.initialData != null) {
        await ApiService.updateContent(widget.initialData!['id'], data);
      } else {
        await ApiService.createContent(data);
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _cmsErrorMessage(e);
          _saving = false;
        });
      }
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
              Text(
                widget.initialData == null
                    ? 'Tambah Pengumuman Baru'
                    : 'Edit Pengumuman',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CmsImagePickerField(
                  controller: _imageCtrl,
                  label: 'Gambar Thumbnail',
                  hintText: 'https://.../thumbnail.jpg',
                ),
                const SizedBox(height: 24),

                _buildLabel('Judul Berita'),
                TextField(
                  controller: _titleCtrl,
                  decoration: _inputDecoration('Masukkan judul berita...'),
                ),
                const SizedBox(height: 24),

                _buildLabel('Urutan Tampil'),
                TextField(
                  controller: _orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('0'),
                ),
                const SizedBox(height: 24),

                _buildLabel('Konten Berita'),
                _CmsRichTextEditor(
                  key: _contentEditorKey,
                  controller: _contentCtrl,
                  hintText: 'Tulis konten berita di sini...',
                ),
                const SizedBox(height: 24),

                _buildLabel('Status Publikasi'),
                Row(
                  children: [
                    _buildStatusRadio('Draft', false),
                    const SizedBox(width: 32),
                    _buildStatusRadio('Terpublikasi', true),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                _CmsErrorBanner(message: _errorMessage!),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      side: const BorderSide(color: AppColors.gray300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _saving ? 'Menyimpan...' : 'Simpan & Publikasikan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRadio(String label, bool value) {
    final isSelected = _isPublished == value;
    final color = value ? AppColors.green500 : AppColors.gray400;

    return InkWell(
      onTap: () => setState(() => _isPublished = value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : AppColors.gray300,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementFormModal extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback? onSaved;
  const AchievementFormModal({super.key, this.initialData, this.onSaved});

  static void show(
    BuildContext context, {
    Map<String, dynamic>? initialData,
    VoidCallback? onSaved,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
          child: AchievementFormModal(
            initialData: initialData,
            onSaved: onSaved,
          ),
        ),
      ),
    );
  }

  @override
  State<AchievementFormModal> createState() => _AchievementFormModalState();
}

class _AchievementFormModalState extends State<AchievementFormModal> {
  final _descEditorKey = GlobalKey<_CmsRichTextEditorState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _penerimaCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _orderCtrl;
  bool _isPublished = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData?['title']);
    _penerimaCtrl = TextEditingController(
      text: widget.initialData?['videoUrl'] ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.initialData?['content'] ?? '',
    );
    _imageCtrl = TextEditingController(
      text: widget.initialData?['imageUrl'] ?? '',
    );
    _orderCtrl = TextEditingController(
      text: '${widget.initialData?['order'] ?? 0}',
    );
    _isPublished = widget.initialData?['isActive'] ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _penerimaCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _descEditorKey.currentState?.syncNow();
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final data = {
        'type': 'PRESTASI',
        'title': _titleCtrl.text.trim(),
        'content': _descCtrl.text,
        'videoUrl': _penerimaCtrl.text.trim(),
        'imageUrl': _imageCtrl.text.trim(),
        'order': int.tryParse(_orderCtrl.text) ?? 0,
        'isActive': _isPublished,
      };
      if (widget.initialData != null) {
        await ApiService.updateContent(widget.initialData!['id'], data);
      } else {
        await ApiService.createContent(data);
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _cmsErrorMessage(e);
          _saving = false;
        });
      }
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
              Text(
                widget.initialData == null
                    ? 'Tambah Prestasi Baru'
                    : 'Edit Prestasi',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CmsImagePickerField(
                  controller: _imageCtrl,
                  label: 'Gambar Thumbnail',
                  hintText: 'https://.../prestasi.jpg',
                ),
                const SizedBox(height: 24),

                _buildLabel('Nama Prestasi'),
                TextField(
                  controller: _titleCtrl,
                  decoration: _inputDecoration(
                    'Contoh: Olimpiade Sains Nasional',
                  ),
                ),
                const SizedBox(height: 24),

                _buildLabel('Penerima / Siswa'),
                TextField(
                  controller: _penerimaCtrl,
                  decoration: _inputDecoration(
                    'Contoh: Budi Santoso, XI IPA 1',
                  ),
                ),
                const SizedBox(height: 24),

                _buildLabel('Urutan Tampil'),
                TextField(
                  controller: _orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('0'),
                ),
                const SizedBox(height: 24),

                _buildLabel('Deskripsi Singkat'),
                _CmsRichTextEditor(
                  key: _descEditorKey,
                  controller: _descCtrl,
                  hintText: 'Keterangan singkat...',
                  maxLines: 5,
                ),
                const SizedBox(height: 24),

                _buildLabel('Status Publikasi'),
                Row(
                  children: [
                    _buildStatusRadio('Draft', false),
                    const SizedBox(width: 32),
                    _buildStatusRadio('Terpublikasi', true),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                _CmsErrorBanner(message: _errorMessage!),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      side: const BorderSide(color: AppColors.gray300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _saving ? 'Menyimpan...' : 'Simpan Prestasi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRadio(String label, bool value) {
    final isSelected = _isPublished == value;
    final color = value ? AppColors.green500 : AppColors.gray400;

    return InkWell(
      onTap: () => setState(() => _isPublished = value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : AppColors.gray300,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
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

  static void show(
    BuildContext context, {
    Map<String, dynamic>? initialData,
    VoidCallback? onSaved,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
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
  late TextEditingController _durationCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _orderCtrl;
  bool _isPublished = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData?['title']);
    _urlCtrl = TextEditingController(
      text: widget.initialData?['videoUrl'] ?? '',
    );
    _durationCtrl = TextEditingController(
      text: widget.initialData?['content'] ?? '',
    );
    _imageCtrl = TextEditingController(
      text: widget.initialData?['imageUrl'] ?? '',
    );
    _orderCtrl = TextEditingController(
      text: '${widget.initialData?['order'] ?? 0}',
    );
    _isPublished = widget.initialData?['isActive'] ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _durationCtrl.dispose();
    _imageCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final data = {
        'type': 'VIDEO',
        'title': _titleCtrl.text.trim(),
        'videoUrl': _urlCtrl.text.trim(),
        'content': _durationCtrl.text.trim(),
        'imageUrl': _imageCtrl.text.trim(),
        'order': int.tryParse(_orderCtrl.text) ?? 0,
        'isActive': _isPublished,
      };
      if (widget.initialData != null) {
        await ApiService.updateContent(widget.initialData!['id'], data);
      } else {
        await ApiService.createContent(data);
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _cmsErrorMessage(e);
          _saving = false;
        });
      }
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
              Text(
                widget.initialData == null ? 'Tambah Video Baru' : 'Edit Video',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CmsImagePickerField(
                  controller: _imageCtrl,
                  label: 'Gambar Thumbnail',
                  hintText: 'https://.../video.jpg',
                ),
                const SizedBox(height: 24),

                _buildLabel('Judul Video'),
                TextField(
                  controller: _titleCtrl,
                  decoration: _inputDecoration(
                    'Contoh: Highlight Acara Kelulusan 2026',
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('YouTube URL / Link'),
                          TextField(
                            controller: _urlCtrl,
                            decoration: _inputDecoration(
                              'Contoh: https://youtube.com/watch?v=...',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Durasi'),
                          TextField(
                            controller: _durationCtrl,
                            decoration: _inputDecoration('Contoh: 5:32'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildLabel('Urutan Tampil'),
                TextField(
                  controller: _orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('0'),
                ),
                const SizedBox(height: 24),

                _buildLabel('Status Publikasi'),
                Row(
                  children: [
                    _buildStatusRadio('Draft', false),
                    const SizedBox(width: 32),
                    _buildStatusRadio('Terpublikasi', true),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.gray200),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                _CmsErrorBanner(message: _errorMessage!),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      side: const BorderSide(color: AppColors.gray300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _saving ? 'Menyimpan...' : 'Simpan Video',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRadio(String label, bool value) {
    final isSelected = _isPublished == value;
    final color = value ? AppColors.green500 : AppColors.gray400;

    return InkWell(
      onTap: () => setState(() => _isPublished = value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : AppColors.gray300,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      color: AppColors.foreground,
    ),
  ),
);

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.gray300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
