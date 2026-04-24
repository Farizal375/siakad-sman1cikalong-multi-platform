// File: lib/features/siswa/screens/mobile/mobile_profile.dart
// ===========================================
// MOBILE STUDENT PROFILE (FR-07)
// Single-column profile with logout
// Connected to /profile API
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../providers/student_providers.dart';

class MobileProfile extends ConsumerStatefulWidget {
  const MobileProfile({super.key});
  @override
  ConsumerState<MobileProfile> createState() => _MobileProfileState();
}

class _MobileProfileState extends ConsumerState<MobileProfile> {
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;

  final _fullNameCtrl = TextEditingController();
  final _motherCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = 'Laki-laki';
  String _religion = 'Islam';
  String _email = '';
  String _nisn = '';
  String _kelas = '-';
  String _initials = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService.getProfile();
      final data = response['data'] ?? {};
      if (mounted) {
        setState(() {
          _email = data['email'] ?? '';
          _nisn = data['nomorInduk'] ?? '';
          _kelas = data['kelas'] ?? '-';
          _fullNameCtrl.text = data['namaLengkap'] ?? '';
          _motherCtrl.text = data['namaIbuKandung'] ?? '';
          _birthPlaceCtrl.text = data['tempatLahir'] ?? '';
          _gender = data['jenisKelamin'] ?? 'Laki-laki';
          _religion = data['agama'] ?? 'Islam';
          _addressCtrl.text = data['alamat'] ?? '';
          final names = (data['namaLengkap'] ?? '').toString().split(' ');
          _initials = names.length >= 2
              ? '${names[0][0]}${names[1][0]}'.toUpperCase()
              : (names.isNotEmpty && names[0].isNotEmpty ? names[0][0].toUpperCase() : '?');
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateProfile({
        'namaLengkap': _fullNameCtrl.text,
        'namaIbuKandung': _motherCtrl.text,
        'tempatLahir': _birthPlaceCtrl.text,
        'jenisKelamin': _gender,
        'agama': _religion,
        'alamat': _addressCtrl.text,
      });
      if (mounted) {
        setState(() { _saving = false; _editing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Profil berhasil diperbarui'),
            ]),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal menyimpan profil'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _motherCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // ── Avatar Header ──
        Center(child: Column(children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentHover]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 32))),
          ),
          const SizedBox(height: 12),
          Text(_fullNameCtrl.text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fgColor)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('Kelas $_kelas', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ])),
        const SizedBox(height: 24),

        // ── Account Info ──
        _sectionCard('Informasi Akun', Icons.person_outline, [
          _infoRow('Email', _email, Icons.email_outlined),
          _infoRow('NISN', _nisn, Icons.badge_outlined),
          _infoRow('Kelas', _kelas, Icons.class_outlined),
        ]),
        const SizedBox(height: 16),

        // ── Personal Info ──
        _sectionCard(
          'Data Pribadi',
          Icons.edit_note,
          [
            if (!_editing)
              ...[
                _infoRow('Nama Lengkap', _fullNameCtrl.text, Icons.person),
                _infoRow('Jenis Kelamin', _gender, Icons.wc),
                _infoRow('Tempat Lahir', _birthPlaceCtrl.text, Icons.location_city),
                _infoRow('Agama', _religion, Icons.mosque_outlined),
                _infoRow('Nama Ibu', _motherCtrl.text, Icons.family_restroom),
                _infoRow('Alamat', _addressCtrl.text, Icons.home_outlined),
              ]
            else
              ...[
                _editField('Nama Lengkap', _fullNameCtrl),
                _editField('Tempat Lahir', _birthPlaceCtrl),
                _editField('Nama Ibu Kandung', _motherCtrl),
                _editField('Alamat', _addressCtrl, maxLines: 2),
                const SizedBox(height: 8),
                _dropdownField('Jenis Kelamin', ['Laki-laki', 'Perempuan'], _gender, (v) => setState(() => _gender = v!)),
                const SizedBox(height: 8),
                _dropdownField('Agama', ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'], _religion, (v) => setState(() => _religion = v!)),
              ],
          ],
          trailing: !_editing
              ? TextButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600)),
                )
              : null,
        ),

        if (_editing) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () { _loadProfile(); setState(() => _editing = false); },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gray600,
                  side: const BorderSide(color: AppColors.gray300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 24),

        // ── Pengaturan ──
        _sectionCard('Pengaturan', Icons.settings_outlined, [
          Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 18, color: AppColors.gray400),
              const SizedBox(width: 10),
              Text('Mode Gelap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: fgColor)),
              const Spacer(),
              Switch(
                value: isDark,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).toggleTheme(val);
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ]),
        const SizedBox(height: 24),

        // ── Logout ──
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.destructive,
              side: const BorderSide(color: AppColors.destructive),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> children, {Widget? trailing}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground))),
          if (trailing != null) trailing,
        ]),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.gray400),
        const SizedBox(width: 10),
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.gray500))),
        Expanded(child: Text(value.isEmpty ? '-' : value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.foreground))),
      ]),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: AppColors.gray500),
          filled: true,
          fillColor: AppColors.gray50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _dropdownField(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: AppColors.gray500),
        filled: true,
        fillColor: AppColors.gray50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
