// File: lib/features/kurikulum/screens/manajemen_rombel.dart
// ===========================================
// MANAJEMEN ROMBEL (Class Group Management)
// Translated from ManajemenRombel.tsx
// Dual-pane transfer list + config card
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/success_toast.dart';

class ManajemenRombel extends StatefulWidget {
  const ManajemenRombel({super.key});

  @override
  State<ManajemenRombel> createState() => _ManajemenRombelState();
}

class _ManajemenRombelState extends State<ManajemenRombel> {
  String? _selectedKelas;
  String? _selectedTahunAjaran;
  String? _selectedWaliKelas;
  String? _selectedRuangan;
  String _leftSearch = '';
  String _rightSearch = '';
  bool _showSuccessToast = false;
  String _successMessage = '';

  // All available students
  final List<Map<String, String>> _availableStudents = List.generate(20, (i) {
    final idx = i + 1;
    final names = [
      'Ahmad Fauzi', 'Siti Aisyah', 'Budi Pratama', 'Dewi Lestari', 'Rizki Hidayat',
      'Nur Haliza', 'Eko Saputra', 'Maya Sari', 'Dian Purnama', 'Faisal Rahman',
      'Putri Amelia', 'Yoga Pratama', 'Anisa Fitri', 'Rendi Kurniawan', 'Lina Marlina',
      'Bayu Setiawan', 'Citra Dewi', 'Hadi Santoso', 'Rina Wati', 'Agus Supriyadi',
    ];
    return {
      'id': 'S${idx.toString().padLeft(3, '0')}',
      'name': names[i],
      'nisn': '202600${(1000 + idx).toString()}',
    };
  });

  // Students currently assigned to the class
  final List<Map<String, String>> _assignedStudents = [];

  // Selected checkboxes on the left
  final Set<String> _leftSelected = {};

  List<Map<String, String>> get _filteredAvailable {
    final assigned = _assignedStudents.map((s) => s['id']).toSet();
    var list = _availableStudents.where((s) => !assigned.contains(s['id'])).toList();
    if (_leftSearch.isNotEmpty) {
      final q = _leftSearch.toLowerCase();
      list = list.where((s) => s['name']!.toLowerCase().contains(q) || s['nisn']!.contains(q)).toList();
    }
    return list;
  }

  List<Map<String, String>> get _filteredAssigned {
    if (_rightSearch.isEmpty) return _assignedStudents;
    final q = _rightSearch.toLowerCase();
    return _assignedStudents.where((s) => s['name']!.toLowerCase().contains(q) || s['nisn']!.contains(q)).toList();
  }

  void _addSelected() {
    setState(() {
      for (final id in _leftSelected) {
        final student = _availableStudents.firstWhere((s) => s['id'] == id);
        _assignedStudents.add(student);
      }
      _leftSelected.clear();
    });
  }

  void _addAll() {
    setState(() {
      final available = _filteredAvailable;
      for (final s in available) {
        if (!_assignedStudents.any((a) => a['id'] == s['id'])) {
          _assignedStudents.add(s);
        }
      }
      _leftSelected.clear();
    });
  }

  void _removeStudent(String id) {
    setState(() {
      _assignedStudents.removeWhere((s) => s['id'] == id);
    });
  }

  void _removeAll() {
    setState(() {
      _assignedStudents.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Title ──
            const Text(
              'Manajemen Rombongan Belajar',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola pemetaan siswa ke dalam rombongan belajar',
              style: TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 32),

            // ── Configuration Card ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDropdown('Nama Rombel', ['X IPA 1', 'X IPA 2', 'XI IPA 1', 'XI IPS 1', 'XII IPA 1'], _selectedKelas, (v) => setState(() => _selectedKelas = v)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown('Tahun Ajaran', ['2026/2027', '2025/2026'], _selectedTahunAjaran, (v) => setState(() => _selectedTahunAjaran = v)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown('Ruangan', ['R-101', 'R-102', 'R-201', 'R-202', 'LAB-01'], _selectedRuangan, (v) => setState(() => _selectedRuangan = v)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown('Wali Kelas', ['Dr. Siti Nurhaliza', 'Budi Santoso, M.Pd', 'Ahmad Hidayat, S.Pd'], _selectedWaliKelas, (v) => setState(() => _selectedWaliKelas = v)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _successMessage = 'Konfigurasi rombel berhasil disimpan';
                        _showSuccessToast = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Dual-Pane Transfer List ──
            Expanded(
              child: Row(
                children: [
                  // Left — Available Students
                  Expanded(child: _buildAvailablePane()),

                  // Center — Transfer Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TransferButton(
                          icon: Icons.keyboard_double_arrow_right,
                          tooltip: 'Tambahkan semua',
                          onPressed: _addAll,
                        ),
                        const SizedBox(height: 8),
                        _TransferButton(
                          icon: Icons.chevron_right,
                          tooltip: 'Tambahkan terpilih',
                          onPressed: _leftSelected.isNotEmpty ? _addSelected : null,
                        ),
                        const SizedBox(height: 8),
                        _TransferButton(
                          icon: Icons.keyboard_double_arrow_left,
                          tooltip: 'Keluarkan semua',
                          onPressed: _assignedStudents.isNotEmpty ? _removeAll : null,
                        ),
                      ],
                    ),
                  ),

                  // Right — Assigned Students
                  Expanded(child: _buildAssignedPane()),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Capacity Info + Confirm ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Text(
                    'Terisi: ${_assignedStudents.length} / 36 siswa',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _assignedStudents.length / 36,
                        minHeight: 8,
                        backgroundColor: AppColors.gray200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _assignedStudents.length > 36 ? const Color(0xFFB91C1C) : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _successMessage = 'Pemetaan rombel berhasil dikonfirmasi';
                        _showSuccessToast = true;
                      });
                    },
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Konfirmasi Pemetaan Rombel'),
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
            ),
          ],
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

  // ── Available Students Pane ──
  Widget _buildAvailablePane() {
    final list = _filteredAvailable;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text('Daftar Siswa Tersedia (${list.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _leftSearch = v),
                  decoration: InputDecoration(
                    hintText: 'Cari siswa...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.gray400),
                    isDense: true,
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final s = list[i];
                final selected = _leftSelected.contains(s['id']);
                return ListTile(
                  dense: true,
                  leading: Checkbox(
                    value: selected,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _leftSelected.add(s['id']!);
                      } else {
                        _leftSelected.remove(s['id']!);
                      }
                    }),
                    activeColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  title: Text(s['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text('NISN: ${s['nisn']}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                  trailing: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.gray200,
                    child: Text(s['name']![0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Assigned Students Pane ──
  Widget _buildAssignedPane() {
    final list = _filteredAssigned;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text('Siswa di Rombel Ini (${_assignedStudents.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _rightSearch = v),
                  decoration: InputDecoration(
                    hintText: 'Cari siswa...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.gray400),
                    isDense: true,
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: AppColors.gray300),
                        SizedBox(height: 8),
                        Text('Belum ada siswa dipetakan', style: TextStyle(color: AppColors.gray500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final s = list[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(s['name']![0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                        title: Text(s['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text('NISN: ${s['nisn']}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.gray400),
                          onPressed: () => _removeStudent(s['id']!),

                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.gray600),
        filled: true, fillColor: AppColors.gray50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// TRANSFER BUTTON
// ═══════════════════════════════════════════════
class _TransferButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _TransferButton({required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onPressed != null ? AppColors.primary : AppColors.gray200,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: onPressed != null ? Colors.white : AppColors.gray400,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
