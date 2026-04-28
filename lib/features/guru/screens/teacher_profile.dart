// File: lib/features/guru/screens/teacher_profile.dart
// ===========================================
// TEACHER PROFILE
// Translated from TeacherProfile.tsx
// Connected to /profile API
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared_widgets/success_toast.dart';

class TeacherProfile extends ConsumerStatefulWidget {
  const TeacherProfile({super.key});

  @override
  ConsumerState<TeacherProfile> createState() => _TeacherProfileState();
}

class _TeacherProfileState extends ConsumerState<TeacherProfile> {
  bool _showSuccessToast = false;
  String _successMessage = '';
  bool _loading = true;
  bool _saving = false;

  final _fullNameCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();
  String _gender = 'Laki-laki';
  String _religion = 'Islam';
  String _maritalStatus = 'Belum Menikah';

  String _province = '';
  String _city = '';
  String _district = '';
  String _subdistrict = '';
  final _addressCtrl = TextEditingController();
  final _rtCtrl = TextEditingController();
  final _rwCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();

  // Read-only fields from API
  String _email = '';
  String _nip = '';
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
          _nip = data['nomorInduk'] ?? '';
          _fullNameCtrl.text = data['namaLengkap'] ?? '';
          _nikCtrl.text = data['nik'] ?? '';
          _birthPlaceCtrl.text = data['tempatLahir'] ?? '';
          _gender = data['jenisKelamin'] ?? 'Laki-laki';
          _religion = data['agama'] ?? 'Islam';
          _maritalStatus = data['statusPernikahan'] ?? 'Belum Menikah';
          _province = data['provinsi'] ?? '';
          _city = data['kota'] ?? '';
          _district = data['kecamatan'] ?? '';
          _subdistrict = data['kelurahan'] ?? '';
          _addressCtrl.text = data['alamat'] ?? '';
          _rtCtrl.text = data['rt'] ?? '';
          _rwCtrl.text = data['rw'] ?? '';
          _postalCtrl.text = data['kodePos'] ?? '';
          // Build initials from name
          final names = (data['namaLengkap'] ?? '').toString().split(' ');
          _initials = names.length >= 2
              ? '${names[0][0]}${names[1][0]}'.toUpperCase()
              : names.isNotEmpty && names[0].isNotEmpty
                  ? names[0][0].toUpperCase()
                  : '?';
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
        'nik': _nikCtrl.text,
        'tempatLahir': _birthPlaceCtrl.text,
        'jenisKelamin': _gender,
        'agama': _religion,
        'statusPernikahan': _maritalStatus,
        'provinsi': _province,
        'kota': _city,
        'kecamatan': _district,
        'kelurahan': _subdistrict,
        'alamat': _addressCtrl.text,
        'rt': _rtCtrl.text,
        'rw': _rwCtrl.text,
        'kodePos': _postalCtrl.text,
      });
      if (mounted) {
        // Sinkronisasi nama ke authProvider agar TopBar ikut berubah
        await ref.read(authProvider.notifier).updateUserName(_fullNameCtrl.text);
        setState(() {
          _successMessage = 'Profil berhasil diperbarui';
          _showSuccessToast = true;
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _successMessage = 'Gagal menyimpan profil';
          _showSuccessToast = true;
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nikCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _addressCtrl.dispose();
    _rtCtrl.dispose();
    _rwCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profil Pengguna', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('Kelola informasi profil dan data pribadi Anda', style: TextStyle(color: AppColors.gray600)),
              const SizedBox(height: 32),

              // Avatar
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.accent, AppColors.accentHover],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 40)),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Material(
                            color: AppColors.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: () {},
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Hapus Foto', style: TextStyle(color: Color(0xFFB91C1C))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Credentials (read-only)
              _buildSection('Informasi Akun', [
                _buildReadOnlyField('Email', _email),
                const SizedBox(height: 16),
                _buildReadOnlyField('NIP', _nip),
              ]),
              const SizedBox(height: 32),

              // Personal Info
              _buildSection('Informasi Pribadi', [
                _buildTextField('Nama Lengkap', _fullNameCtrl),
                const SizedBox(height: 16),
                _buildTextField('NIK (16 digit)', _nikCtrl, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildLabel('Jenis Kelamin'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _GenderButton(label: 'Laki-laki', selected: _gender == 'Laki-laki', onTap: () => setState(() => _gender = 'Laki-laki')),
                    const SizedBox(width: 12),
                    _GenderButton(label: 'Perempuan', selected: _gender == 'Perempuan', onTap: () => setState(() => _gender = 'Perempuan')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Tempat Lahir', _birthPlaceCtrl)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Tanggal Lahir'),
                          const SizedBox(height: 8),
                          TextField(
                            readOnly: true,
                            onTap: () async {
                              await showDatePicker(
                                context: context,
                                initialDate: DateTime(1968, 1, 5),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: 'Pilih tanggal',
                              suffixIcon: const Icon(Icons.calendar_today, size: 18, color: AppColors.gray400),
                              filled: true, fillColor: AppColors.gray50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Agama', ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'], _religion.isEmpty ? 'Islam' : _religion, (v) => setState(() => _religion = v!))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Status Pernikahan', ['Belum Menikah', 'Menikah', 'Cerai'], _maritalStatus.isEmpty ? 'Belum Menikah' : _maritalStatus, (v) => setState(() => _maritalStatus = v!))),
                  ],
                ),
              ]),
              const SizedBox(height: 32),

              // Address
              _buildSection('Alamat', [
                Row(
                  children: [
                    Expanded(child: _buildTextField('Provinsi', TextEditingController(text: _province), onChanged: (v) => _province = v)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Kota/Kabupaten', TextEditingController(text: _city), onChanged: (v) => _city = v)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Kecamatan', TextEditingController(text: _district), onChanged: (v) => _district = v)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Kelurahan/Desa', TextEditingController(text: _subdistrict), onChanged: (v) => _subdistrict = v)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Detail Alamat', _addressCtrl, maxLines: 2),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('RT', _rtCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('RW', _rwCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Kode Pos (5 digit)', _postalCtrl, keyboardType: TextInputType.number)),
                  ],
                ),
              ]),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _loading ? null : _loadProfile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray600,
                      side: const BorderSide(color: AppColors.gray300),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),

        if (_showSuccessToast)
          Positioned(
            top: 16, right: 16,
            child: SuccessToast(
              isVisible: true,
              message: _successMessage,
              onClose: () => setState(() => _showSuccessToast = false),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true, fillColor: AppColors.gray50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true, fillColor: AppColors.gray50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground));
}

class _GenderButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GenderButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.gray300),
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.foreground)),
        ),
      ),
    );
  }
}
