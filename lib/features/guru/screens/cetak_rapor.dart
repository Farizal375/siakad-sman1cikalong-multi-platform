// File: lib/features/guru/screens/cetak_rapor.dart
// ===========================================
// CETAK RAPOR – Wali Kelas
// Translated from CetakRapor.tsx
// Tabel verifikasi + bulk print modal
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/success_toast.dart';

class CetakRapor extends StatefulWidget {
  const CetakRapor({super.key});

  @override
  State<CetakRapor> createState() => _CetakRaporState();
}

class _CetakRaporState extends State<CetakRapor> {
  Set<int> _selected = {};
  bool _showModal = false;
  bool _showToast = false;
  String _toastMsg = '';
  String _semester = 'Semester Ganjil 2026/2027';
  bool _digitalSignature = true;

  final _students = [
    {'id': 1, 'no': 1, 'nisn': '0012345671', 'name': 'Ahmad Fauzi', 'comp': 14, 'total': 14, 'hasNotes': true},
    {'id': 2, 'no': 2, 'nisn': '0012345672', 'name': 'Siti Rahmawati', 'comp': 14, 'total': 14, 'hasNotes': true},
    {'id': 3, 'no': 3, 'nisn': '0012345673', 'name': 'Budi Santoso', 'comp': 12, 'total': 14, 'hasNotes': false},
    {'id': 4, 'no': 4, 'nisn': '0012345674', 'name': 'Dewi Lestari', 'comp': 14, 'total': 14, 'hasNotes': true},
    {'id': 5, 'no': 5, 'nisn': '0012345675', 'name': 'Andi Wijaya', 'comp': 14, 'total': 14, 'hasNotes': true},
    {'id': 6, 'no': 6, 'nisn': '0012345676', 'name': 'Maya Sari', 'comp': 13, 'total': 14, 'hasNotes': true},
  ];

  int get _readyCount => _students.where((s) => s['comp'] == s['total'] && s['hasNotes'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text('Cetak e-Rapor XI-1', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.foreground)),
              const SizedBox(height: 8),
              const Text('Verifikasi kelengkapan data dan cetak rapor siswa', style: TextStyle(color: AppColors.gray600)),
              const SizedBox(height: 24),

              // Status Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.description, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status Data', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
                          Text('$_readyCount/${_students.length} Siswa Siap Cetak', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() { _toastMsg = 'Memuat ulang data...'; _showToast = true; }),
                      icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selected.isEmpty ? null : () => setState(() => _showModal = true),
                      icon: const Icon(Icons.archive, size: 18),
                      label: Text('Cetak Massal (${_selected.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.gray300,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Table Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selected.length == _students.length,
                            tristate: _selected.isNotEmpty && _selected.length < _students.length,
                            onChanged: (_) => setState(() {
                              if (_selected.length == _students.length) {
                                _selected = {};
                              } else {
                                _selected = _students.map((s) => s['id'] as int).toSet();
                              }
                            }),
                            activeColor: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(flex: 3, child: Text('Nama Siswa & NISN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                          const Expanded(flex: 2, child: Text('Nilai Mapel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                          const Expanded(flex: 2, child: Text('Catatan Wali Kelas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground))),
                          const SizedBox(width: 120, child: Center(child: Text('Aksi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)))),
                        ],
                      ),
                    ),
                    // Rows
                    ..._students.map((s) {
                      final id = s['id'] as int;
                      final isComplete = s['comp'] == s['total'];
                      final canPrint = isComplete && s['hasNotes'] == true;
                      final isSelected = _selected.contains(id);
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                          border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) => setState(() {
                                  if (isSelected) {
                                    _selected.remove(id);
                                  } else {
                                    _selected.add(id);
                                  }
                                }),
                                activeColor: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground, fontSize: 14)),
                                    Text('NISN: ${s['nisn']}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _statusBadge(
                                  isComplete ? '${s['comp']}/${s['total']}' : '${s['comp']}/${s['total']} Pending',
                                  isComplete ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                  isComplete ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: s['hasNotes'] == true
                                    ? _statusBadge('✓ Ready', const Color(0xFF15803D), const Color(0xFFDCFCE7))
                                    : _statusBadge('Empty', AppColors.gray600, const Color(0xFFF3F4F6)),
                              ),
                              SizedBox(
                                width: 120,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _actionBtn(Icons.visibility_outlined, const Color(0xFF2563EB), () => context.go('/guru/rapor-detail/$id')),
                                    _actionBtn(Icons.description_outlined, AppColors.accent, canPrint ? () {} : null),
                                    _actionBtn(Icons.restart_alt, AppColors.gray600, () {}),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),

        // Bulk Print Modal
        if (_showModal)
          _buildModal(context),

        if (_showToast)
          Positioned(
            top: 16, right: 16,
            child: SuccessToast(
              isVisible: true,
              message: _toastMsg,
              onClose: () => setState(() => _showToast = false),
            ),
          ),
      ],
    );
  }

  Widget _statusBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: onTap == null ? AppColors.gray300 : color),
      ),
    );
  }

  Widget _buildModal(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showModal = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 480,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(blurRadius: 32, color: Colors.black26)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Konfigurasi Cetak Massal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                        IconButton(onPressed: () => setState(() => _showModal = false), icon: const Icon(Icons.close, color: Colors.white)),
                      ],
                    ),
                  ),

                  // Modal Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pilih Semester', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground, fontSize: 14)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _semester,
                          items: ['Semester Ganjil 2026/2027', 'Semester Genap 2026/2027']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _semester = v!),
                          decoration: InputDecoration(
                            filled: true, fillColor: AppColors.gray50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sertakan Tanda Tangan Digital', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground, fontSize: 14)),
                                  SizedBox(height: 4),
                                  Text('Tambahkan TTD Kepala Sekolah & Wali Kelas', style: TextStyle(fontSize: 12, color: AppColors.gray600)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _digitalSignature,
                              onChanged: (v) => setState(() => _digitalSignature = v),
                              activeThumbColor: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Siswa yang dipilih:', style: TextStyle(fontSize: 12, color: AppColors.gray600)),
                              Text('${_selected.length} dari ${_students.length} siswa', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Modal Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => setState(() => _showModal = false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gray700,
                            side: const BorderSide(color: AppColors.gray300, width: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showModal = false;
                              _selected = {};
                              _toastMsg = 'Memproses e-Rapor dalam format ZIP...';
                              _showToast = true;
                            });
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Proses & Unduh ZIP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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
