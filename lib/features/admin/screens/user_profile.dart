// File: lib/features/admin/screens/user_profile.dart
// ===========================================
// USER PROFILE SCREEN
// Translated from UserProfile.tsx
// Profile photo, credentials, personal info, address form
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Read-only fields
  final _email = 'admin@school.sch.id';
  final _systemId = 'NIP198501012020011001';

  // Form fields
  String _fullName = 'Dr. Siti Nurhaliza, S.Pd';
  String _nik = '3275010185010001';
  String _motherName = '';
  String _gender = 'Perempuan';
  String _birthPlace = 'Jakarta';
  String _birthDate = '1985-01-01';
  String _religion = 'Islam';
  String _maritalStatus = 'Menikah';
  String _province = 'DKI Jakarta';
  String _city = 'Jakarta Selatan';
  String _district = 'Kebayoran Baru';
  String _subdistrict = 'Senayan';
  String _address = 'Jl. Asia Afrika No. 8';
  String _rt = '001';
  String _rw = '002';
  String _postalCode = '10270';

  String? _nikError;

  void _validateNIK(String value) {
    setState(() {
      _nikError = value.length != 16 ? 'NIK harus 16 digit' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960), // max-w-5xl
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page Header ──
              const Text(
                'Profil Pengguna',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kelola informasi akun dan data pribadi Anda',
                style: TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 32),

              // ── Profile Picture ──
              _buildCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 128, height: 128,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2563EB)]),
                        borderRadius: BorderRadius.circular(64),
                      ),
                      child: const Icon(Icons.person, size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    // Upload button
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('Ubah Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Maks 2MB (JPG, JPEG, PNG)', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Account Credentials (Read Only) ──
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kredensial Akun', style: _sectionTitle),
                    const SizedBox(height: 20),
                    _FieldRow(children: [
                      _ReadOnlyField(label: 'Email', value: _email, hint: 'Email tidak dapat diubah'),
                      _ReadOnlyField(label: 'ID Sistem / NIP / NISN', value: _systemId, hint: 'ID unik sistem terkunci', mono: true),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Personal Information ──
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Pribadi', style: _sectionTitle),
                    const SizedBox(height: 20),
                    // Full Name (full width)
                    _FormField(
                      label: 'Nama Lengkap',
                      required: true,
                      child: TextFormField(
                        initialValue: _fullName,
                        onChanged: (v) => _fullName = v,
                        decoration: _inputDecor(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FieldRow(children: [
                      _FormField(
                        label: 'NIK (16 Digit)',
                        required: true,
                        error: _nikError,
                        child: TextFormField(
                          initialValue: _nik,
                          onChanged: (v) { _nik = v; _validateNIK(v); },
                          decoration: _inputDecor().copyWith(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _nikError != null ? const Color(0xFFEF4444) : _nik.length == 16 ? AppColors.green500 : AppColors.gray300),
                            ),
                          ),
                          maxLength: 16,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      _FormField(
                        label: 'Nama Ibu Kandung',
                        child: TextFormField(
                          initialValue: _motherName,
                          onChanged: (v) => _motherName = v,
                          decoration: _inputDecor(hint: 'Untuk siswa'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _FieldRow(children: [
                      _FormField(
                        label: 'Jenis Kelamin',
                        required: true,
                        child: Row(
                          children: [
                            _RadioOption(label: 'Laki-laki', value: 'Laki-laki', groupValue: _gender, onChanged: (v) => setState(() => _gender = v!)),
                            const SizedBox(width: 12),
                            _RadioOption(label: 'Perempuan', value: 'Perempuan', groupValue: _gender, onChanged: (v) => setState(() => _gender = v!)),
                          ],
                        ),
                      ),
                      _FormField(
                        label: 'Tempat Lahir',
                        required: true,
                        child: TextFormField(initialValue: _birthPlace, onChanged: (v) => _birthPlace = v, decoration: _inputDecor()),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _FieldRow(children: [
                      _FormField(
                        label: 'Tanggal Lahir',
                        required: true,
                        child: TextFormField(initialValue: _birthDate, onChanged: (v) => _birthDate = v, decoration: _inputDecor(), keyboardType: TextInputType.datetime),
                      ),
                      _FormField(
                        label: 'Agama',
                        required: true,
                        child: DropdownButtonFormField<String>(
                          initialValue: _religion,
                          decoration: _inputDecor(),
                          items: ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (v) => setState(() => _religion = v!),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _FieldRow(children: [
                      _FormField(
                        label: 'Status Perkawinan',
                        child: DropdownButtonFormField<String>(
                          initialValue: _maritalStatus,
                          decoration: _inputDecor(),
                          items: ['Belum Menikah', 'Menikah', 'Cerai Hidup', 'Cerai Mati'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _maritalStatus = v!),
                        ),
                      ),
                      const SizedBox(), // empty slot
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Address Information ──
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alamat Tempat Tinggal', style: _sectionTitle),
                    const SizedBox(height: 20),
                    // 4-col cascading dropdowns
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 768) {
                          return Row(
                            children: [
                              Expanded(child: _FormField(label: 'Provinsi', required: true, child: DropdownButtonFormField<String>(initialValue: _province, decoration: _inputDecor(), items: ['DKI Jakarta', 'Jawa Barat', 'Jawa Tengah', 'Jawa Timur'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setState(() => _province = v!)))),
                              const SizedBox(width: 20),
                              Expanded(child: _FormField(label: 'Kota/Kabupaten', required: true, child: DropdownButtonFormField<String>(initialValue: _city, decoration: _inputDecor(), items: ['Jakarta Selatan', 'Jakarta Pusat', 'Jakarta Utara'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _city = v!)))),
                              const SizedBox(width: 20),
                              Expanded(child: _FormField(label: 'Kecamatan', required: true, child: DropdownButtonFormField<String>(initialValue: _district, decoration: _inputDecor(), items: ['Kebayoran Baru', 'Kebayoran Lama', 'Tebet'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _district = v!)))),
                              const SizedBox(width: 20),
                              Expanded(child: _FormField(label: 'Kelurahan', required: true, child: DropdownButtonFormField<String>(initialValue: _subdistrict, decoration: _inputDecor(), items: ['Senayan', 'Melawai', 'Gunung'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _subdistrict = v!)))),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _FormField(label: 'Provinsi', required: true, child: DropdownButtonFormField<String>(initialValue: _province, decoration: _inputDecor(), items: ['DKI Jakarta', 'Jawa Barat'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setState(() => _province = v!))),
                            const SizedBox(height: 16),
                            _FormField(label: 'Kota/Kabupaten', required: true, child: DropdownButtonFormField<String>(initialValue: _city, decoration: _inputDecor(), items: ['Jakarta Selatan'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _city = v!))),
                            const SizedBox(height: 16),
                            _FormField(label: 'Kecamatan', required: true, child: DropdownButtonFormField<String>(initialValue: _district, decoration: _inputDecor(), items: ['Kebayoran Baru'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _district = v!))),
                            const SizedBox(height: 16),
                            _FormField(label: 'Kelurahan', required: true, child: DropdownButtonFormField<String>(initialValue: _subdistrict, decoration: _inputDecor(), items: ['Senayan'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _subdistrict = v!))),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Full Address
                    _FormField(
                      label: 'Alamat Lengkap / Nomor Rumah',
                      required: true,
                      child: TextFormField(
                        initialValue: _address,
                        onChanged: (v) => _address = v,
                        maxLines: 3,
                        decoration: _inputDecor(hint: 'Jl. Nama Jalan, No. Rumah, Nama Gedung/Komplek'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FieldRow(children: [
                      _FormField(label: 'RT', required: true, child: TextFormField(initialValue: _rt, onChanged: (v) => _rt = v, decoration: _inputDecor(hint: '001'), maxLength: 3, keyboardType: TextInputType.number, style: const TextStyle(fontFamily: 'monospace'))),
                      _FormField(label: 'RW', required: true, child: TextFormField(initialValue: _rw, onChanged: (v) => _rw = v, decoration: _inputDecor(hint: '002'), maxLength: 3, keyboardType: TextInputType.number, style: const TextStyle(fontFamily: 'monospace'))),
                    ]),
                    const SizedBox(height: 16),
                    _FormField(label: 'Kode Pos', required: true, child: TextFormField(initialValue: _postalCode, onChanged: (v) => _postalCode = v, decoration: _inputDecor(hint: '10270'), maxLength: 5, keyboardType: TextInputType.number, style: const TextStyle(fontFamily: 'monospace'))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Action Buttons ──
              _buildCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.foreground,
                        side: const BorderSide(color: AppColors.gray300, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(24)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecor({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

const _sectionTitle = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary);

// Helper widgets
class _FieldRow extends StatelessWidget {
  final List<Widget> children;
  const _FieldRow({required this.children});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: c))).toList(),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final bool required;
  final String? error;
  final Widget child;
  const _FormField({required this.label, this.required = false, this.error, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
              if (required) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(error!, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)))),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final bool mono;
  const _ReadOnlyField({required this.label, required this.value, required this.hint, this.mono = false});
  @override
  Widget build(BuildContext context) {
    return _FormField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              border: Border.all(color: AppColors.gray300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value, style: TextStyle(color: AppColors.gray500, fontFamily: mono ? 'monospace' : null)),
          ),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final void Function(String?) onChanged;
  const _RadioOption({required this.label, required this.value, required this.groupValue, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: value == groupValue ? AppColors.primary : AppColors.gray400, width: 2),
                ),
                child: value == groupValue
                    ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary)))
                    : null,
              ),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: AppColors.foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
