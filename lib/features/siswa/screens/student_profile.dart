// File: lib/features/siswa/screens/student_profile.dart
// ===========================================
// STUDENT PROFILE – Profil Siswa
// Connected to /profile API
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared_widgets/profile_photo_editor.dart';
import '../../../shared_widgets/success_toast.dart';

class StudentProfile extends ConsumerStatefulWidget {
  const StudentProfile({super.key});

  @override
  ConsumerState<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends ConsumerState<StudentProfile> {
  static const bool _enableEmailOtp = bool.fromEnvironment(
    'ENABLE_EMAIL_OTP',
    defaultValue: false,
  );

  bool _showSuccessToast = false;
  String _successMessage = 'Profil berhasil diperbarui';
  bool _loading = true;
  bool _saving = false;
  bool _emailOtpSending = false;
  bool _emailOtpVerifying = false;
  String _emailOtpMessage = '';
  String _emailOtpError = '';
  String _devOtp = '';

  final _fullNameCtrl = TextEditingController();
  final _motherCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();
  String _gender = 'Laki-laki';
  String _religion = 'Islam';

  String _province = '';
  String _city = '';
  String _district = '';
  String _subdistrict = '';
  final _addressCtrl = TextEditingController();
  final _rtCtrl = TextEditingController();
  final _rwCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _personalEmailCtrl = TextEditingController();
  final _personalEmailOtpCtrl = TextEditingController();

  // Read-only
  String _email = '';
  String _nisn = '';
  String _kelas = '-';
  String _initials = '';
  String _avatarUrl = '';
  String _personalEmail = '';
  String _personalEmailPending = '';

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
          _avatarUrl = data['avatarUrl'] ?? '';
          _personalEmail = data['personalEmail'] ?? '';
          _personalEmailPending = data['personalEmailPending'] ?? '';
          _personalEmailCtrl.text = _personalEmailPending.isNotEmpty
              ? _personalEmailPending
              : _personalEmail;
          _nisn = data['nomorInduk'] ?? '';
          _kelas = data['kelas'] ?? '-';
          _fullNameCtrl.text = data['namaLengkap'] ?? '';
          _motherCtrl.text = data['namaIbuKandung'] ?? '';
          _birthPlaceCtrl.text = data['tempatLahir'] ?? '';
          _gender = data['jenisKelamin'] ?? 'Laki-laki';
          _religion = data['agama'] ?? 'Islam';
          _province = data['provinsi'] ?? '';
          _city = data['kota'] ?? '';
          _district = data['kecamatan'] ?? '';
          _subdistrict = data['kelurahan'] ?? '';
          _addressCtrl.text = data['alamat'] ?? '';
          _rtCtrl.text = data['rt'] ?? '';
          _rwCtrl.text = data['rw'] ?? '';
          _postalCtrl.text = data['kodePos'] ?? '';
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
        'namaIbuKandung': _motherCtrl.text,
        'tempatLahir': _birthPlaceCtrl.text,
        'jenisKelamin': _gender,
        'agama': _religion,
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
        await ref
            .read(authProvider.notifier)
            .updateUserName(_fullNameCtrl.text);
        setState(() {
          _successMessage = 'Profil berhasil diperbarui';
          _showSuccessToast = true;
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _handleAvatarChanged(String? avatarUrl) {
    setState(() {
      _avatarUrl = avatarUrl ?? '';
      _successMessage = avatarUrl == null
          ? 'Foto profil berhasil dihapus'
          : 'Foto profil berhasil diperbarui';
      _showSuccessToast = true;
    });
  }

  void _showProfileMessage(String message) {
    setState(() {
      _successMessage = message;
      _showSuccessToast = true;
    });
  }

  Future<void> _requestPersonalEmailOtp() async {
    final email = _personalEmailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailOtpError = 'Email pribadi wajib diisi.';
        _emailOtpMessage = '';
      });
      return;
    }

    setState(() {
      _emailOtpSending = true;
      _emailOtpError = '';
      _emailOtpMessage = '';
      _devOtp = '';
    });
    try {
      final response = await ApiService.requestPersonalEmailOtp(email);
      final data = response['data'] ?? {};
      final pendingEmail = data['personalEmailPending'] ?? email;
      final devOtp = data['devOtp']?.toString() ?? '';
      if (mounted) {
        setState(() {
          _personalEmailPending = pendingEmail;
          _devOtp = devOtp;
          if (devOtp.isNotEmpty) {
            _personalEmailOtpCtrl.text = devOtp;
          }
          _emailOtpMessage =
              response['message'] ?? 'OTP verifikasi telah dikirim.';
          _emailOtpSending = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _emailOtpSending = false;
          _emailOtpError =
              'Gagal mengirim OTP. Periksa email atau konfigurasi SMTP backend.';
        });
      }
    }
  }

  Future<void> _verifyPersonalEmailOtp() async {
    if (_personalEmailOtpCtrl.text.trim().isEmpty) {
      setState(() {
        _emailOtpError = 'Kode OTP wajib diisi.';
        _emailOtpMessage = '';
      });
      return;
    }

    setState(() {
      _emailOtpVerifying = true;
      _emailOtpError = '';
      _emailOtpMessage = '';
    });
    try {
      await ApiService.verifyPersonalEmailOtp(
        _personalEmailOtpCtrl.text.trim(),
      );
      await _loadProfile();
      if (mounted) {
        setState(() {
          _personalEmailOtpCtrl.clear();
          _devOtp = '';
          _emailOtpMessage = 'Email pemulihan berhasil diverifikasi.';
          _emailOtpVerifying = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _emailOtpVerifying = false;
          _emailOtpError = 'Kode OTP tidak valid atau sudah kadaluarsa.';
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _motherCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _addressCtrl.dispose();
    _rtCtrl.dispose();
    _rwCtrl.dispose();
    _postalCtrl.dispose();
    _personalEmailCtrl.dispose();
    _personalEmailOtpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil Siswa',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kelola informasi profil dan data pribadi Anda',
                style: TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 32),

              // Avatar
              Center(
                child: ProfilePhotoEditor(
                  initials: _initials,
                  avatarUrl: _avatarUrl,
                  onAvatarChanged: _handleAvatarChanged,
                  onMessage: _showProfileMessage,
                ),
              ),
              const SizedBox(height: 32),

              // Credentials
              _buildSection('Informasi Akun', [
                _buildReadOnlyField('Email', _email),
                const SizedBox(height: 16),
                _buildReadOnlyField('NISN', _nisn),
                const SizedBox(height: 16),
                _buildReadOnlyField('Kelas', _kelas),
              ]),
              const SizedBox(height: 32),

              if (_enableEmailOtp) ...[
                _buildSection('Email Pemulihan', [
                  _buildReadOnlyField('Email Terverifikasi', _personalEmail),
                  const SizedBox(height: 16),
                  if (_emailOtpError.isNotEmpty) ...[
                    _buildStatusBox(_emailOtpError, false),
                    const SizedBox(height: 16),
                  ],
                  if (_emailOtpMessage.isNotEmpty) ...[
                    _buildStatusBox(_emailOtpMessage, true),
                    const SizedBox(height: 16),
                  ],
                  _buildTextField(
                    'Email Pribadi',
                    _personalEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _emailOtpSending
                          ? null
                          : _requestPersonalEmailOtp,
                      icon: _emailOtpSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mail_outline, size: 18),
                      label: const Text('Kirim OTP'),
                    ),
                  ),
                  if (_personalEmailPending.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildOtpVerificationForm(),
                  ],
                ]),
                const SizedBox(height: 32),
              ],

              // Personal Info
              _buildSection('Informasi Pribadi', [
                _buildTextField('Nama Lengkap', _fullNameCtrl),
                const SizedBox(height: 16),
                _buildTextField('Nama Ibu Kandung', _motherCtrl),
                const SizedBox(height: 16),
                _buildLabel('Jenis Kelamin'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _GenderButton(
                      label: 'Laki-laki',
                      selected: _gender == 'Laki-laki',
                      onTap: () => setState(() => _gender = 'Laki-laki'),
                    ),
                    const SizedBox(width: 12),
                    _GenderButton(
                      label: 'Perempuan',
                      selected: _gender == 'Perempuan',
                      onTap: () => setState(() => _gender = 'Perempuan'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Tempat Lahir', _birthPlaceCtrl),
                    ),
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
                                initialDate: DateTime(2005),
                                firstDate: DateTime(1995),
                                lastDate: DateTime.now(),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: 'Pilih tanggal',
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: AppColors.gray400,
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.gray300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.gray300,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  'Agama',
                  [
                    'Islam',
                    'Kristen',
                    'Katolik',
                    'Hindu',
                    'Buddha',
                    'Konghucu',
                  ],
                  _religion.isEmpty ? 'Islam' : _religion,
                  (v) => setState(() => _religion = v!),
                ),
              ]),
              const SizedBox(height: 32),

              // Address
              _buildSection('Alamat', [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Provinsi',
                        TextEditingController(text: _province),
                        onChanged: (v) => _province = v,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Kota/Kabupaten',
                        TextEditingController(text: _city),
                        onChanged: (v) => _city = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Kecamatan',
                        TextEditingController(text: _district),
                        onChanged: (v) => _district = v,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Kelurahan/Desa',
                        TextEditingController(text: _subdistrict),
                        onChanged: (v) => _subdistrict = v,
                      ),
                    ),
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
                    Expanded(
                      child: _buildTextField(
                        'Kode Pos',
                        _postalCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _loadProfile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray600,
                      side: const BorderSide(color: AppColors.gray300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
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

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
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
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 14, color: AppColors.gray600),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBox(String message, bool success) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFEFFDF4) : AppColors.red50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: success ? const Color(0xFF86EFAC) : AppColors.red200,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: success ? const Color(0xFF166534) : AppColors.destructive,
        ),
      ),
    );
  }

  Widget _buildOtpVerificationForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadOnlyField(
            'Email Menunggu Verifikasi',
            _personalEmailPending,
          ),
          if (_devOtp.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildStatusBox('Kode OTP dev: $_devOtp', true),
          ],
          const SizedBox(height: 16),
          _buildTextField(
            'Masukkan Kode OTP',
            _personalEmailOtpCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _emailOtpVerifying ? null : _verifyPersonalEmailOtp,
              icon: _emailOtpVerifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined, size: 18),
              label: const Text('Verifikasi OTP'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
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
            filled: true,
            fillColor: AppColors.gray50,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.gray50,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.foreground,
    ),
  );
}

class _GenderButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GenderButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.primary : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.foreground,
          ),
        ),
      ),
    ),
  );
}
