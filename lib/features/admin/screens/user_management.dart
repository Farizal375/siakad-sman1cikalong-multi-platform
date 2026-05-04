// File: lib/features/admin/screens/user_management.dart
// ===========================================
// USER MANAGEMENT SCREEN
// Translated from UserManagement.tsx
// Data table with search, pagination, CRUD modals
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/file_transfer.dart';
import '../../../shared_widgets/table_pagination.dart';
import '../../../shared_widgets/delete_confirmation_modal.dart';
import '../../../shared_widgets/success_toast.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  int _currentPage = 1;
  int _itemsPerPage = 10;
  String _searchQuery = '';
  bool _showSuccessToast = false;
  String _successMessage = '';
  bool _loading = true;
  bool _importing = false;
  bool _exporting = false;
  List<Map<String, dynamic>> _userData = [];
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getUsers(
        page: _currentPage,
        limit: _itemsPerPage,
        search: _searchQuery,
      );
      final data = response['data'] as List? ?? [];
      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
      setState(() {
        _userData = data
            .map<Map<String, dynamic>>(
              (u) => {
                'id': u['id'] ?? '',
                'name': u['name'] ?? '',
                'email': u['email'] ?? '',
                'username': u['username'] ?? '',
                'idNumber': u['idNumber'] ?? '-',
                'role': u['role'] ?? 'Siswa',
                'status': u['status'] ?? 'Aktif',
              },
            )
            .toList();
        _totalItems = pagination['total'] ?? _userData.length;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _paginatedData => _userData;

  Future<void> _handleImport() async {
    try {
      final picked = await pickDataFile(
        accept:
            '.csv,.xls,.xlsx,text/csv,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (picked == null) return;

      setState(() => _importing = true);
      final response = await ApiService.importUsersFile(
        picked.bytes,
        picked.name,
      );
      final message =
          response['message'] ?? 'Import data pengguna berhasil diproses.';

      if (!mounted) return;
      setState(() {
        _currentPage = 1;
        _successMessage = '$message Profile pengguna otomatis disiapkan.';
        _showSuccessToast = true;
        _importing = false;
      });
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Import gagal. Pastikan format file CSV/Excel sesuai template.',
          ),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  Future<void> _handleExport(String format) async {
    try {
      setState(() => _exporting = true);
      final bytes = await ApiService.exportUsers(format: format);
      final date = DateTime.now();
      final dateLabel =
          '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      final filename =
          'export_pengguna_$dateLabel.${format == 'xlsx' ? 'xlsx' : 'csv'}';
      final mimeType = format == 'xlsx'
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'text/csv;charset=utf-8';

      downloadBytesFile(filename, bytes, mimeType: mimeType);

      if (!mounted) return;
      setState(() {
        _successMessage =
            'Data pengguna berhasil diexport ke ${format.toUpperCase()}.';
        _showSuccessToast = true;
        _exporting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export gagal. Silakan coba lagi.'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Action Bar ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manajemen Pengguna',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kelola akses siswa, guru mata pelajaran, wali kelas, dan kurikulum',
                        style: TextStyle(color: AppColors.gray600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Import CSV
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _importing ? null : _handleImport,
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: Text(
                      _importing ? 'Mengimport...' : 'Import CSV/Excel',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: PopupMenuButton<String>(
                    enabled: !_exporting,
                    onSelected: _handleExport,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                      PopupMenuItem(value: 'xlsx', child: Text('Export Excel')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _exporting
                            ? AppColors.primaryHover
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.download_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _exporting ? 'Mengexport...' : 'Export',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Add User
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      UserFormModal.show(
                        context,
                        onSave: (data) {
                          setState(() {
                            _successMessage = 'Pengguna berhasil ditambahkan.';
                            _showSuccessToast = true;
                          });
                          _loadUsers();
                        },
                      );
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Tambah Pengguna'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Search Bar ──
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: TextField(
                onChanged: (v) {
                  _searchQuery = v;
                  _currentPage = 1;
                  _loadUsers();
                },
                decoration: InputDecoration(
                  hintText: 'Cari pengguna berdasarkan nama, ID, atau NIP...',
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
              ),
            ),
            const SizedBox(height: 24),

            // ── Data Table Card ──
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
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      color: AppColors.gray50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text('Nama', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('ID / NIP', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Peran', style: _headerStyle),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('Status', style: _headerStyle),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text('Aksi', style: _headerStyle),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.gray200),

                    // Table Body
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              itemCount: _paginatedData.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.gray200,
                              ),
                              itemBuilder: (context, index) {
                                final user = _paginatedData[index];
                                return _UserRow(
                                  user: user,
                                  onEdit: () {
                                    UserFormModal.show(
                                      context,
                                      initialData: user.map(
                                        (key, value) =>
                                            MapEntry(key, value.toString()),
                                      ),
                                      onSave: (data) {
                                        setState(() {
                                          _successMessage =
                                              'Pengguna berhasil diperbarui.';
                                          _showSuccessToast = true;
                                        });
                                        _loadUsers();
                                      },
                                    );
                                  },
                                  onResetPassword: () {
                                    UserFormModal.show(
                                      context,
                                      initialData: user.map(
                                        (key, value) =>
                                            MapEntry(key, value.toString()),
                                      ),
                                      forcePasswordReset: true,
                                      onSave: (data) {
                                        setState(() {
                                          _successMessage =
                                              'Kata sandi pengguna berhasil di-reset.';
                                          _showSuccessToast = true;
                                        });
                                        _loadUsers();
                                      },
                                    );
                                  },
                                  onDelete: () {
                                    DeleteConfirmationModal.show(
                                      context,
                                      title: 'Konfirmasi Penghapusan Pengguna',
                                      message:
                                          'Apakah Anda yakin ingin menghapus pengguna ini? Semua data terkait akan dihapus secara permanen dan tidak dapat dipulihkan.',
                                      itemName: user['name'],
                                      onConfirm: () async {
                                        try {
                                          await ApiService.deleteUser(
                                            user['id'],
                                          );
                                          _loadUsers();
                                          setState(() {
                                            _successMessage =
                                                'Pengguna "${user['name']}" berhasil dihapus';
                                            _showSuccessToast = true;
                                          });
                                        } catch (_) {}
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                    ),

                    // Pagination
                    TablePagination(
                      currentPage: _currentPage,
                      totalItems: _totalItems,
                      itemsPerPage: _itemsPerPage,
                      onPageChange: (p) {
                        setState(() => _currentPage = p);
                        _loadUsers();
                      },
                      onItemsPerPageChange: (n) {
                        setState(() {
                          _itemsPerPage = n;
                          _currentPage = 1;
                        });
                        _loadUsers();
                      },
                      itemName: 'pengguna',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Success Toast
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
}

// ── User Row Widget ──
class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;

  const _UserRow({
    required this.user,
    required this.onEdit,
    required this.onResetPassword,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = (user['name'] as String)
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    final isActive = user['status'] == 'Aktif';

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Name + Avatar
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.foreground,
                          ),
                        ),
                        Text(
                          user['email'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ID Number
            Expanded(
              flex: 2,
              child: Text(
                user['idNumber'],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.foreground,
                ),
              ),
            ),

            // Role Badge
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleBadgeColor(user['role']),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user['role'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getRoleBadgeTextColor(user['role']),
                    ),
                  ),
                ),
              ),
            ),

            // Status
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.green500 : AppColors.gray500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user['status'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? AppColors.green700 : AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.gray600,
                    ),
                    tooltip: 'Edit',
                    splashRadius: 20,
                  ),
                  IconButton(
                    onPressed: onResetPassword,
                    icon: const Icon(
                      Icons.vpn_key_outlined,
                      size: 18,
                      color: AppColors.gray600,
                    ),
                    tooltip: 'Reset Password',
                    splashRadius: 20,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.gray600,
                    ),
                    tooltip: 'Hapus',
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleBadgeColor(String role) {
    switch (role) {
      case 'Siswa':
        return const Color(0xFFDBEAFE);
      case 'Guru Mata Pelajaran':
        return const Color(0xFFDCFCE7);
      case 'Wali Kelas':
        return const Color(0xFFF3E8FF);
      case 'Kurikulum':
        return const Color(0xFFFFF7ED);
      default:
        return AppColors.gray100;
    }
  }

  Color _getRoleBadgeTextColor(String role) {
    switch (role) {
      case 'Siswa':
        return const Color(0xFF1D4ED8);
      case 'Guru Mata Pelajaran':
        return const Color(0xFF15803D);
      case 'Wali Kelas':
        return const Color(0xFF7E22CE);
      case 'Kurikulum':
        return const Color(0xFFC2410C);
      default:
        return AppColors.gray700;
    }
  }
}

const _headerStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: AppColors.foreground,
);

// Mock data removed — using real API data from _loadUsers()

// ═══════════════════════════════════════════════
// USER FORM MODAL
// ═══════════════════════════════════════════════
class UserFormModal extends StatefulWidget {
  final Map<String, String>? initialData;
  final bool forcePasswordReset;
  final Function(Map<String, String>) onSave;

  const UserFormModal({
    super.key,
    this.initialData,
    this.forcePasswordReset = false,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    Map<String, String>? initialData,
    bool forcePasswordReset = false,
    required Function(Map<String, String>) onSave,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
          child: UserFormModal(
            initialData: initialData,
            forcePasswordReset: forcePasswordReset,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  @override
  State<UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<UserFormModal> {
  late TextEditingController _nameCtrl;
  late TextEditingController _idNumberCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  String _role = '';
  bool _isActive = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialData?['name']);
    _idNumberCtrl = TextEditingController(
      text: widget.initialData?['idNumber'],
    );
    _usernameCtrl = TextEditingController(
      text: widget.initialData?['username'],
    );
    _emailCtrl = TextEditingController(text: widget.initialData?['email']);
    _passwordCtrl = TextEditingController();
    _role = widget.initialData?['role'] ?? '';
    _isActive = widget.initialData?['status'] != 'Tidak Aktif';

    if (widget.forcePasswordReset) {
      _generatePassword();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idNumberCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _generatePassword() {
    setState(() {
      _passwordCtrl.text = _idNumberCtrl.text.isNotEmpty
          ? '${_idNumberCtrl.text}@Siakad2026!'
          : 'User@Siakad2026!';
    });
  }

  Future<void> _saveData() async {
    // ── Validation ──
    if (!widget.forcePasswordReset) {
      if (_nameCtrl.text.trim().isEmpty ||
          _emailCtrl.text.trim().isEmpty ||
          _role.isEmpty) {
        setState(() => _errorMessage = 'Nama, email, dan peran wajib diisi.');
        return;
      }
    }
    if (_passwordCtrl.text.isEmpty && widget.initialData == null) {
      setState(
        () => _errorMessage = 'Password wajib diisi untuk pengguna baru.',
      );
      return;
    }
    if (widget.forcePasswordReset && _passwordCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'Password baru wajib diisi.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'idNumber': _idNumberCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': _role,
        'password': _passwordCtrl.text,
        'status': _isActive ? 'Aktif' : 'Tidak Aktif',
      };

      if (widget.forcePasswordReset && widget.initialData != null) {
        // ── Reset Password mode ──
        await ApiService.resetPassword(
          widget.initialData!['id']!,
          _passwordCtrl.text,
        );
      } else if (widget.initialData != null) {
        // ── Edit mode ──
        await ApiService.updateUser(widget.initialData!['id']!, payload);
      } else {
        // ── Create mode ──
        await ApiService.createUser(payload);
      }

      if (mounted) {
        widget.onSave(payload);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal menyimpan data. Silakan coba lagi.';
          _loading = false;
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
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.forcePasswordReset
                    ? 'Reset Kata Sandi'
                    : (widget.initialData == null
                          ? 'Tambah Pengguna Baru'
                          : 'Edit Pengguna'),
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
        const Divider(height: 1),
        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Nama Lengkap (Siswa/Guru)'),
                          TextField(
                            controller: _nameCtrl,
                            decoration: _inputDecoration('contoh: Ahmad Fauzi'),
                            enabled: !widget.forcePasswordReset,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Nomor ID (NISN / NIP)'),
                          TextField(
                            controller: _idNumberCtrl,
                            decoration: _inputDecoration(
                              'Masukkan nomor ID terkait...',
                            ),
                            enabled: !widget.forcePasswordReset,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Alamat Email'),
                          TextField(
                            controller: _emailCtrl,
                            decoration: _inputDecoration('user@sekolah.edu'),
                            enabled: !widget.forcePasswordReset,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Username'),
                          TextField(
                            controller: _usernameCtrl,
                            decoration: _inputDecoration('contoh: ahmad.siswa'),
                            enabled: !widget.forcePasswordReset,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Peran Pengguna'),
                          DropdownButtonFormField<String>(
                            initialValue: _role.isEmpty ? null : _role,
                            hint: const Text('Pilih Peran...'),
                            decoration: _inputDecoration(''),
                            items: const [
                              DropdownMenuItem(
                                value: 'Siswa',
                                child: Text('Siswa'),
                              ),
                              DropdownMenuItem(
                                value: 'Guru Mapel',
                                child: Text('Guru Mapel'),
                              ),
                              DropdownMenuItem(
                                value: 'Wali Kelas',
                                child: Text('Wali Kelas'),
                              ),
                              DropdownMenuItem(
                                value: 'Kurikulum',
                                child: Text('Kurikulum'),
                              ),
                            ],
                            onChanged: widget.forcePasswordReset
                                ? null
                                : (v) => setState(() => _role = v ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLabel('Kata Sandi Akun'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _passwordCtrl,
                        decoration: _inputDecoration(
                          'Masukkan kata sandi atau klik tombol...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _generatePassword,
                      icon: const Icon(Icons.key, size: 20),
                      label: const Text('Opsional: Buat berdasarkan NIP/NISN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gray100,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                // ── Error Message ──
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!widget.forcePasswordReset) ...[
                  const SizedBox(height: 24),
                  _buildLabel('Status Akun'),
                  Row(
                    children: [
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeThumbColor: AppColors.green500,
                      ),
                      Text(
                        _isActive ? 'Akun Aktif' : 'Akun Tidak Aktif',
                        style: TextStyle(
                          color: _isActive
                              ? AppColors.green700
                              : AppColors.gray600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
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
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.forcePasswordReset
                      ? Colors.red
                      : AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.forcePasswordReset
                            ? 'Simpan & Reset Sandi'
                            : 'Simpan Pengguna',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
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
