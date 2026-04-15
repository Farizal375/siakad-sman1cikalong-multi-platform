// File: lib/features/siswa/screens/student_profile.dart
// ===========================================
// STUDENT PROFILE – Profil Siswa
// Pola sama dengan curriculum_profile.dart untuk Siswa
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/success_toast.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  bool _showSuccessToast = false;

  final _fullNameCtrl = TextEditingController(text: 'Ahmad Fauzi');
  final _nisnCtrl = TextEditingController(text: '2023001');
  final _motherCtrl = TextEditingController(text: 'Siti Aminah');
  final _birthPlaceCtrl = TextEditingController(text: 'Cianjur');
  String _gender = 'Laki-laki';
  String _religion = 'Islam';

  String _province = 'Jawa Barat';
  String _city = 'Kab. Cianjur';
  String _district = 'Cikalong';
  String _subdistrict = 'Cikalong';
  final _addressCtrl = TextEditingController(text: 'Jl. Raya Cikalong No. 5');
  final _rtCtrl = TextEditingController(text: '002');
  final _rwCtrl = TextEditingController(text: '004');
  final _postalCtrl = TextEditingController(text: '43282');

  @override
  void dispose() {
    _fullNameCtrl.dispose(); _nisnCtrl.dispose(); _motherCtrl.dispose();
    _birthPlaceCtrl.dispose(); _addressCtrl.dispose();
    _rtCtrl.dispose(); _rwCtrl.dispose(); _postalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profil Siswa', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary)),
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
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accent, AppColors.accentHover]),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Center(child: Text('AF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 40))),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Material(
                            color: AppColors.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: () {},
                              customBorder: const CircleBorder(),
                              child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.camera_alt, size: 18, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () {}, child: const Text('Hapus Foto', style: TextStyle(color: Color(0xFFB91C1C)))),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Credentials
              _buildSection('Informasi Akun', [
                _buildReadOnlyField('Email', 'ahmad.fauzi@siswa.sman1cikalong.sch.id'),
                const SizedBox(height: 16),
                _buildReadOnlyField('NISN', '2023001'),
                const SizedBox(height: 16),
                _buildReadOnlyField('Kelas', 'XII-1'),
              ]),
              const SizedBox(height: 32),

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
                            onTap: () async { await showDatePicker(context: context, initialDate: DateTime(2005), firstDate: DateTime(1995), lastDate: DateTime.now()); },
                            decoration: InputDecoration(
                              hintText: '01/01/2005',
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
                _buildDropdownField('Agama', ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'], _religion, (v) => setState(() => _religion = v!)),
              ]),
              const SizedBox(height: 32),

              // Address
              _buildSection('Alamat', [
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Provinsi', ['Jawa Barat', 'Jawa Tengah', 'Jawa Timur', 'DKI Jakarta'], _province, (v) => setState(() => _province = v!))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Kota/Kabupaten', ['Kab. Cianjur', 'Kab. Bandung', 'Kota Bandung'], _city, (v) => setState(() => _city = v!))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Kecamatan', ['Cikalong', 'Cipanas', 'Cianjur'], _district, (v) => setState(() => _district = v!))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownField('Kelurahan/Desa', ['Cikalong', 'Cibeber', 'Sindangsari'], _subdistrict, (v) => setState(() => _subdistrict = v!))),
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
                    Expanded(child: _buildTextField('Kode Pos', _postalCtrl, keyboardType: TextInputType.number)),
                  ],
                ),
              ]),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.gray600, side: const BorderSide(color: AppColors.gray300), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _showSuccessToast = true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w600)),
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
            child: SuccessToast(isVisible: true, message: 'Profil berhasil diperbarui', onClose: () => setState(() => _showSuccessToast = false)),
          ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 24),
        ...children,
      ]),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label), const SizedBox(height: 8),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)), child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.gray600))),
    ]);
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label), const SizedBox(height: 8),
      TextField(controller: ctrl, maxLines: maxLines, keyboardType: keyboardType, decoration: InputDecoration(filled: true, fillColor: AppColors.gray50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
    ]);
  }

  Widget _buildDropdownField(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label), const SizedBox(height: 8),
      DropdownButtonFormField<String>(initialValue: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged, decoration: InputDecoration(filled: true, fillColor: AppColors.gray50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
    ]);
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground));
}

class _GenderButton extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _GenderButton({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.primary : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.primary : AppColors.gray300)), child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.foreground)))),
  );
}
