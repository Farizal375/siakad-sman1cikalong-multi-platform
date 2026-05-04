// File: lib/features/guru/screens/cetak_rapor.dart
// ===========================================
// CETAK RAPOR - Wali Kelas
// Connected to backend rapor status + PDF endpoints
// ===========================================

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_transfer.dart';
import '../../../shared_widgets/success_toast.dart';
import '../providers/homeroom_provider.dart';

class CetakRapor extends ConsumerStatefulWidget {
  const CetakRapor({super.key});

  @override
  ConsumerState<CetakRapor> createState() => _CetakRaporState();
}

class _CetakRaporState extends ConsumerState<CetakRapor> {
  Set<String> _selected = {};
  bool _loading = true;
  bool _processing = false;
  bool _showToast = false;
  String _toastMsg = '';
  HomeroomContext? _homeroom;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final homeroom = await ref.read(homeroomContextProvider.future);
      final semesterId = homeroom.semesterAktif?.id;
      if (!homeroom.hasClass ||
          homeroom.rombelId == null ||
          semesterId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final response = await ApiService.getRaporStatusRombel(
        homeroom.rombelId!,
        semesterId,
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final students = (data['students'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (mounted) {
        setState(() {
          _homeroom = homeroom;
          _students = students;
          _selected = _selected.where(_isReadyId).toSet();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isReady(Map<String, dynamic> student) => student['canPrint'] == true;

  bool _isReadyId(String id) {
    return _students.any((s) => s['id']?.toString() == id && _isReady(s));
  }

  List<Map<String, dynamic>> get _readyStudents =>
      _students.where(_isReady).toList();

  int get _readyCount => _readyStudents.length;

  Future<void> _printSingle(Map<String, dynamic> student) async {
    final semesterId = _homeroom?.semesterAktif?.id;
    final siswaId = student['id']?.toString();
    if (semesterId == null || siswaId == null) return;

    setState(() {
      _processing = true;
      _toastMsg = 'Memuat PDF rapor...';
      _showToast = true;
    });

    try {
      final bytes = await ApiService.downloadRaporPdf(siswaId, semesterId);
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mencetak rapor')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _downloadSingle(Map<String, dynamic> student) async {
    final semesterId = _homeroom?.semesterAktif?.id;
    final siswaId = student['id']?.toString();
    if (semesterId == null || siswaId == null) return;

    setState(() {
      _processing = true;
      _toastMsg = 'Mengunduh PDF rapor...';
      _showToast = true;
    });

    try {
      final bytes = await ApiService.downloadRaporPdf(siswaId, semesterId);
      await _savePdf(
        'rapor_${_safeFileName(student['name']?.toString() ?? siswaId)}_${_safeFileName(_homeroom?.semesterAktif?.label ?? 'semester')}.pdf',
        bytes,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengunduh rapor')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _printBulk() async {
    final semesterId = _homeroom?.semesterAktif?.id;
    if (semesterId == null || _selected.isEmpty) return;

    setState(() {
      _processing = true;
      _toastMsg = 'Memproses e-Rapor massal...';
      _showToast = true;
    });

    try {
      final bytes = await ApiService.downloadBulkRaporPdf(
        semesterId,
        _selected.toList(),
      );
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
      );
      if (mounted) setState(() => _selected = {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mencetak rapor massal')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _downloadBulk() async {
    final semesterId = _homeroom?.semesterAktif?.id;
    if (semesterId == null || _selected.isEmpty) return;

    setState(() {
      _processing = true;
      _toastMsg = 'Mengunduh e-Rapor massal...';
      _showToast = true;
    });

    try {
      final bytes = await ApiService.downloadBulkRaporPdf(
        semesterId,
        _selected.toList(),
      );
      await _savePdf(
        'rapor_massal_${_safeFileName(_homeroom?.kelas ?? 'rombel')}_${_safeFileName(_homeroom?.semesterAktif?.label ?? 'semester')}.pdf',
        bytes,
      );
      if (mounted) setState(() => _selected = {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunduh rapor massal')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _savePdf(String filename, List<int> bytes) async {
    try {
      downloadBytesFile(filename, bytes, mimeType: 'application/pdf');
    } on UnsupportedError {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: filename,
      );
    }
  }

  String _safeFileName(String value) {
    return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final homeroom = _homeroom;
    if (homeroom == null || _students.isEmpty) {
      return const Center(child: Text('Belum ada data siswa untuk dicetak'));
    }

    final allReadySelected =
        _readyStudents.isNotEmpty &&
        _readyStudents.every((s) => _selected.contains(s['id']?.toString()));

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cetak e-Rapor ${homeroom.kelas}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifikasi kelengkapan data ${homeroom.semesterAktif?.label ?? '-'}',
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 24),
              _buildStatusBar(),
              const SizedBox(height: 20),
              _buildTable(allReadySelected),
              const SizedBox(height: 32),
            ],
          ),
        ),
        if (_showToast)
          Positioned(
            top: 16,
            right: 16,
            child: SuccessToast(
              isVisible: true,
              message: _toastMsg,
              onClose: () => setState(() => _showToast = false),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Data',
                  style: TextStyle(fontSize: 13, color: AppColors.gray600),
                ),
                Text(
                  '$_readyCount/${_students.length} Siswa Siap Cetak',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              IconButton(
                onPressed: _processing ? null : _loadData,
                icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
              ),
              OutlinedButton.icon(
                onPressed: _selected.isEmpty || _processing
                    ? null
                    : _downloadBulk,
                icon: const Icon(Icons.download, size: 18),
                label: Text('Unduh Massal (${_selected.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selected.isEmpty || _processing ? null : _printBulk,
                icon: _processing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.archive, size: 18),
                label: Text('Cetak Massal (${_selected.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.gray300,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(bool allReadySelected) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
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
                  value: allReadySelected,
                  tristate: _selected.isNotEmpty && !allReadySelected,
                  onChanged: _readyStudents.isEmpty
                      ? null
                      : (_) => setState(() {
                          if (allReadySelected) {
                            _selected = {};
                          } else {
                            _selected = _readyStudents
                                .map((s) => s['id'].toString())
                                .toSet();
                          }
                        }),
                  activeColor: AppColors.accent,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Nama Siswa & NISN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Nilai Mapel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Absensi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Catatan Wali Kelas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 150,
                  child: Center(
                    child: Text(
                      'Aksi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._students.map(_buildRow),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> s) {
    final id = s['id']?.toString() ?? '';
    final isReady = _isReady(s);
    final isSelected = _selected.contains(id);
    final comp = (s['comp'] as num?)?.toInt() ?? 0;
    final total = (s['total'] as num?)?.toInt() ?? 0;
    final attendanceCount = (s['kehadiranCount'] as num?)?.toInt() ?? 0;

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
              onChanged: isReady
                  ? (_) => setState(() {
                      if (isSelected) {
                        _selected.remove(id);
                      } else {
                        _selected.add(id);
                      }
                    })
                  : null,
              activeColor: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['name']?.toString() ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'NISN: ${s['nisn'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: _statusBadge(
                total == 0 ? '$comp data' : '$comp/$total',
                comp > 0 && (total == 0 || comp >= total)
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB91C1C),
                comp > 0 && (total == 0 || comp >= total)
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEF2F2),
              ),
            ),
            Expanded(
              flex: 2,
              child: _statusBadge(
                attendanceCount > 0 ? '$attendanceCount rekam' : 'Belum Ada',
                attendanceCount > 0
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB91C1C),
                attendanceCount > 0
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEF2F2),
              ),
            ),
            Expanded(
              flex: 2,
              child: s['hasNotes'] == true
                  ? _statusBadge(
                      'Ready',
                      const Color(0xFF15803D),
                      const Color(0xFFDCFCE7),
                    )
                  : _statusBadge(
                      'Belum Ada',
                      AppColors.gray600,
                      const Color(0xFFF3F4F6),
                    ),
            ),
            SizedBox(
              width: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionBtn(
                    Icons.visibility_outlined,
                    const Color(0xFF2563EB),
                    () => context.go('/guru/rapor-detail/$id'),
                  ),
                  _actionBtn(
                    Icons.description_outlined,
                    AppColors.accent,
                    isReady && !_processing ? () => _printSingle(s) : null,
                  ),
                  _actionBtn(
                    Icons.download_outlined,
                    const Color(0xFF059669),
                    isReady && !_processing ? () => _downloadSingle(s) : null,
                  ),
                  _actionBtn(
                    Icons.restart_alt,
                    AppColors.gray600,
                    _processing ? null : _loadData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color textColor, Color bgColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? AppColors.gray300 : color,
        ),
      ),
    );
  }
}
