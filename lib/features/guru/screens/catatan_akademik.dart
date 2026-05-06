// File: lib/features/guru/screens/catatan_akademik.dart
// ===========================================
// CATATAN AKADEMIK - Wali Kelas
// Connected to /catatan-akademik + /dashboard/wali-kelas API
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/success_toast.dart';
import '../providers/homeroom_provider.dart';

class CatatanAkademik extends ConsumerStatefulWidget {
  const CatatanAkademik({super.key});

  @override
  ConsumerState<CatatanAkademik> createState() => _CatatanAkademikState();
}

class _CatatanAkademikState extends ConsumerState<CatatanAkademik> {
  static const int _maxChar = 500;

  bool _showToast = false;
  bool _loading = true;
  bool _saving = false;
  String _toastMsg = '';
  String _className = '';
  String _semesterLabel = '-';
  String? _semesterId;

  List<Map<String, dynamic>> _students = [];
  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final homeroom = await ref.read(homeroomContextProvider.future);
      final semesterId = homeroom.semesterAktif?.id;

      if (!homeroom.hasClass ||
          homeroom.masterKelasId == null ||
          semesterId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final response = await ApiService.getCatatanKelas(
        homeroom.masterKelasId!,
        semesterId,
      );
      final catatanList = (response['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final catatanBySiswa = {
        for (final item in catatanList) item['siswaId']?.toString() ?? '': item,
      };

      final students = homeroom.students.map<Map<String, dynamic>>((s) {
        final siswaId = s['id']?.toString() ?? '';
        final existing = catatanBySiswa[siswaId];
        final note = existing?['catatan']?.toString() ?? '';
        return {
          'id': siswaId,
          'nisn': s['nisn']?.toString() ?? '-',
          'name': s['name']?.toString() ?? '-',
          'noteId': existing?['id']?.toString(),
          'note': note,
          'originalNote': note,
          'count': note.length,
        };
      }).toList();

      final controllers = students
          .map((s) => TextEditingController(text: s['note'] as String))
          .toList();

      for (int i = 0; i < controllers.length; i++) {
        controllers[i].addListener(() {
          if (!mounted) return;
          setState(() {
            _students[i]['note'] = controllers[i].text;
            _students[i]['count'] = controllers[i].text.length;
          });
        });
      }

      if (mounted) {
        for (final c in _controllers) {
          c.dispose();
        }
        setState(() {
          _className = homeroom.kelas;
          _semesterId = semesterId;
          _semesterLabel = homeroom.semesterAktif?.label ?? '-';
          _students = students;
          _controllers = controllers;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveAll() async {
    final semesterId = _semesterId;
    if (semesterId == null) return;

    setState(() => _saving = true);
    try {
      var changed = 0;
      for (int i = 0; i < _students.length; i++) {
        final note = (_students[i]['note'] as String).trim();
        final original = (_students[i]['originalNote'] as String? ?? '').trim();
        final noteId = _students[i]['noteId'] as String?;

        if (note.isEmpty && noteId != null) {
          await ApiService.deleteCatatanAkademik(noteId);
          _students[i]['noteId'] = null;
          _students[i]['originalNote'] = '';
          changed++;
        } else if (note.isNotEmpty && note != original) {
          final response = await ApiService.upsertCatatanAkademik({
            'siswaId': _students[i]['id'],
            'semesterId': semesterId,
            'catatan': note,
          });
          final data = response['data'];
          if (data is Map) _students[i]['noteId'] = data['id']?.toString();
          _students[i]['originalNote'] = note;
          changed++;
        }
      }

      if (mounted) {
        setState(() {
          _toastMsg = changed == 0
              ? 'Tidak ada perubahan catatan'
              : 'Berhasil menyimpan $changed perubahan catatan';
          _showToast = true;
          _saving = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan catatan akademik')),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _filledCount =>
      _students.where((s) => (s['note'] as String).trim().isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final isNarrow = MediaQuery.sizeOf(context).width < 780;

    if (_students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 64, color: AppColors.gray400),
            SizedBox(height: 16),
            Text(
              'Anda belum ditugaskan sebagai wali kelas',
              style: TextStyle(fontSize: 18, color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catatan Akademik $_className',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Input evaluasi karakter dan perkembangan siswa pada $_semesterLabel',
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 24),
              _buildControlCard(isNarrow),
              const SizedBox(height: 20),
              ..._students.asMap().entries.map(
                (e) => _buildStudentCard(e.key, e.value),
              ),
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

  Widget _buildControlCard(bool isNarrow) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evaluasi Karakter Siswa $_semesterLabel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_filledCount dari ${_students.length} siswa telah diisi',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveAll,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      _saving ? 'Menyimpan...' : 'Simpan Semua Catatan',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evaluasi Karakter Siswa $_semesterLabel',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_filledCount dari ${_students.length} siswa telah diisi',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _saveAll,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(
                    _saving ? 'Menyimpan...' : 'Simpan Semua Catatan',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentCard(int idx, Map<String, dynamic> s) {
    final isNarrow = MediaQuery.sizeOf(context).width < 780;
    final filled = (s['note'] as String).trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primary, Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['name'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.foreground,
                                ),
                              ),
                              Text(
                                'NISN: ${s['nisn']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          filled ? 'Terisi' : 'Belum Diisi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: filled
                                ? const Color(0xFF15803D)
                                : AppColors.gray600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground,
                            ),
                          ),
                          Text(
                            'NISN: ${s['nisn']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: filled
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        filled ? 'Terisi' : 'Belum Diisi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: filled
                              ? const Color(0xFF15803D)
                              : AppColors.gray600,
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 16),
          Stack(
            children: [
              TextField(
                controller: _controllers[idx],
                maxLines: 4,
                maxLength: _maxChar,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) => null,
                decoration: InputDecoration(
                  hintText:
                      'Tuliskan perkembangan karakter, sikap, dan saran untuk siswa ini selama satu semester...',
                  hintStyle: const TextStyle(
                    color: AppColors.gray400,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.gray200,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.gray200,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 12,
                child: Text(
                  '${s['count']}/$_maxChar karakter',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
