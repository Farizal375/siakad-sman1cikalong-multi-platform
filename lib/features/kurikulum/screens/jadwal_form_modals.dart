// lib/features/kurikulum/screens/jadwal_form_modals.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

// ═══════════════════════════════════════════════
// GURU-MAPEL FORM MODAL
// ═══════════════════════════════════════════════
class GuruMapelFormModal extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const GuruMapelFormModal({super.key, this.initialData});
  @override
  State<GuruMapelFormModal> createState() => _GuruMapelFormModalState();
}

class _GuruMapelFormModalState extends State<GuruMapelFormModal> {
  bool _loading = true, _saving = false;
  List<Map<String, dynamic>> _guruList = [], _mapelList = [], _kelasList = [];
  String? _guruId, _mapelId;
  List<String> _selectedClasses = [];
  final _quotaCtrl = TextEditingController(text: '8');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _quotaCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService.getUsers(role: 'Guru Mapel', limit: 1000),
        ApiService.getMataPelajaran(),
        ApiService.getMasterKelas(),
      ]);
      if (mounted) {
        setState(() {
          _guruList = ((results[0]['data'] as List?) ?? []).cast<Map<String, dynamic>>();
          _mapelList = ((results[1]['data'] as List?) ?? []).cast<Map<String, dynamic>>();
          _kelasList = ((results[2]['data'] as List?) ?? []).cast<Map<String, dynamic>>();
          if (widget.initialData != null) {
            _guruId = widget.initialData!['teacherId'];
            _mapelId = widget.initialData!['subjectId'];
            final clsStr = widget.initialData!['classes'] as String? ?? '';
            final validNames = _kelasList
                .map((k) => (k['name'] ?? k['nama'] ?? '') as String)
                .toSet();
            _selectedClasses = clsStr
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty && validNames.contains(e))
                .toList();
            _quotaCtrl.text = '${widget.initialData!['hoursPerWeek'] ?? 8}';
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_guruId == null || _mapelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guru dan mata pelajaran wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        'teacherId': _guruId,
        'subjectId': _mapelId,
        'classes': _selectedClasses.join(', '),
        'hoursPerWeek': int.tryParse(_quotaCtrl.text) ?? 8,
      };
      if (widget.initialData != null) {
        await ApiService.updateGuruMapel(widget.initialData!['id'], payload);
      } else {
        await ApiService.createGuruMapel(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        String msg = 'Terjadi kesalahan';
        if (e is DioException && e.response?.data != null) {
          msg = e.response!.data['message'] ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: AppColors.gray400),
    filled: true, fillColor: AppColors.gray50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(isEdit ? 'Edit Pemetaan Guru' : 'Tambah Pemetaan Guru',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 24),
        if (_loading)
          const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()))
        else ...[
          const Text('Guru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _guruId,
            menuMaxHeight: 280,
            items: _guruList.map((e) => DropdownMenuItem(
              value: e['id'] as String,
              child: Text(e['name'] ?? e['nama_lengkap'] ?? '', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) => setState(() => _guruId = v),
            decoration: _deco('Pilih Guru'),
          ),
          const SizedBox(height: 16),
          const Text('Mata Pelajaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _mapelId,
            menuMaxHeight: 280,
            items: _mapelList.map((e) => DropdownMenuItem(
              value: e['id'] as String,
              child: Text(e['name'] ?? e['nama'] ?? '', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) => setState(() => _mapelId = v),
            decoration: _deco('Pilih Mata Pelajaran'),
          ),
          const SizedBox(height: 16),
          const Text('Kelas yang Diampu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray300),
            ),
            child: _kelasList.isEmpty
              ? const Text('Belum ada data kelas', style: TextStyle(color: AppColors.gray500))
              : Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _kelasList.map((k) {
                    final className = (k['name'] ?? k['nama'] ?? '') as String;
                    final isSelected = _selectedClasses.contains(className);
                    return FilterChip(
                      label: Text(className),
                      selected: isSelected,
                      onSelected: (sel) => setState(() {
                        if (sel) _selectedClasses.add(className);
                        else _selectedClasses.remove(className);
                      }),
                      selectedColor: AppColors.primary.withValues(alpha: 0.1),
                      checkmarkColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.gray300),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.foreground,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
          ),
          const SizedBox(height: 16),
          const Text('Kuota Jam per Minggu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(controller: _quotaCtrl, keyboardType: TextInputType.number, decoration: _deco('Contoh: 8')),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.gray600, side: const BorderSide(color: AppColors.gray300), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Batal'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Pemetaan'),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════
// SCHEDULE FORM MODAL
// Guru Pengajar difilter: hanya tampil guru yang dipetakan
// untuk mata pelajaran & kelas yang dipilih (via GuruMapel API)
// ═══════════════════════════════════════════════
class ScheduleFormModal extends StatefulWidget {
  final String kelasId;
  final List<Map<String, dynamic>> kelasList;
  final Map<String, dynamic>? initialData;
  final bool isEdit;
  const ScheduleFormModal({
    super.key,
    required this.kelasId,
    required this.kelasList,
    this.initialData,
    this.isEdit = false,
  });
  @override
  State<ScheduleFormModal> createState() => _ScheduleFormModalState();
}

class _ScheduleFormModalState extends State<ScheduleFormModal> {
  bool _loading = true, _saving = false;
  List<Map<String, dynamic>> _mapelList = [], _guruMapelList = [];

  String? _selectedDay, _selectedGuruId, _selectedMapelId, _selectedKelasId;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 45);

  static const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  // ── Aturan waktu sekolah ──
  static const _schoolStart = TimeOfDay(hour: 7, minute: 0);
  static const _schoolEnd   = TimeOfDay(hour: 16, minute: 0);
  static const _break1Start = TimeOfDay(hour: 9, minute: 0);
  static const _break1End   = TimeOfDay(hour: 10, minute: 0);
  static const _break2Start = TimeOfDay(hour: 12, minute: 0);
  static const _break2End   = TimeOfDay(hour: 13, minute: 0);

  @override
  void initState() {
    super.initState();
    _selectedKelasId = widget.kelasId;
    _load();
    if (widget.isEdit && widget.initialData != null) {
      final d = widget.initialData!;
      _selectedDay = d['day'] ?? d['hari'];
      _selectedGuruId = d['teacherId'] ?? d['guruId'];
      _selectedMapelId = d['subjectId'];
      _selectedKelasId = d['classId'] ?? widget.kelasId;
      _startTime = _parse(d['startTime'] ?? '07:00');
      _endTime = _parse(d['endTime'] ?? '07:45');
    }
  }

  TimeOfDay _parse(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.tryParse(p[0]) ?? 7, minute: int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Menghitung slot index terdekat dari startTime
  int _slotOf(TimeOfDay t) {
    // Slot valid (diluar jam istirahat)
    const slots = [
      TimeOfDay(hour: 7, minute: 0),  TimeOfDay(hour: 7, minute: 45),
      TimeOfDay(hour: 8, minute: 0),  TimeOfDay(hour: 8, minute: 45),
      TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 10, minute: 45),
      TimeOfDay(hour: 11, minute: 30),
      TimeOfDay(hour: 13, minute: 0), TimeOfDay(hour: 13, minute: 45),
      TimeOfDay(hour: 14, minute: 30),TimeOfDay(hour: 15, minute: 15),
    ];
    int closest = 0, minDiff = 9999;
    for (int i = 0; i < slots.length; i++) {
      final diff = (_toMin(slots[i]) - _toMin(t)).abs();
      if (diff < minDiff) { minDiff = diff; closest = i; }
    }
    return closest;
  }

  /// Validasi waktu terhadap aturan sekolah
  /// Return null jika valid, atau pesan error jika tidak valid
  String? _validateSchedule() {
    final start = _toMin(_startTime);
    final end   = _toMin(_endTime);
    final ss    = _toMin(_schoolStart);
    final se    = _toMin(_schoolEnd);
    final b1s   = _toMin(_break1Start);
    final b1e   = _toMin(_break1End);
    final b2s   = _toMin(_break2Start);
    final b2e   = _toMin(_break2End);

    if (start >= end)
      return 'Waktu selesai harus setelah waktu mulai.';
    if (start < ss)
      return 'Jam pelajaran tidak boleh dimulai sebelum 07:00.';
    if (end > se)
      return 'Jadwal melebihi waktu pulang sekolah (16:00). Harap sesuaikan.';
    if (start < b1e && end > b1s)
      return 'Jadwal bentrok dengan Istirahat 1 (09:00–10:00). Gunakan rentang sebelum 09:00 atau sesudah 10:00.';
    if (start < b2e && end > b2s)
      return 'Jadwal bentrok dengan Istirahat 2 (12:00–13:00). Gunakan rentang sebelum 12:00 atau sesudah 13:00.';
    return null;
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService.getMataPelajaran(),
        ApiService.getGuruMapel(),
      ]);
      if (mounted) setState(() {
        _mapelList = ((results[0]['data'] as List?) ?? []).cast<Map<String, dynamic>>();
        _guruMapelList = ((results[1]['data'] as List?) ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Data kelas yang sedang dipilih (lengkap)
  Map<String, dynamic> get _currentKelasData {
    return widget.kelasList.firstWhere(
      (e) => e['id'] == (_selectedKelasId ?? widget.kelasId),
      orElse: () => {},
    );
  }

  /// Nama kelas yang sedang aktif dipilih
  String get _currentKelasName {
    final k = _currentKelasData;
    return (k['name'] ?? k['nama'] ?? '') as String;
  }

  /// Ruangan dari rombel/master kelas — read-only
  String get _roomDisplay {
    final k = _currentKelasData;
    final code = k['classroom'] ?? k['classroomCode'] ?? k['kode_ruang'] ?? '';
    final cap = k['classroomCapacity'] ?? k['kapasitas'] ?? '';
    if (code.toString().isEmpty) return 'Belum ada ruang kelas';
    return cap.toString().isNotEmpty ? '$code (Kapasitas: $cap)' : code.toString();
  }

  /// ID ruangan dari rombel/master kelas — dikirim ke backend
  String? get _roomId {
    final k = _currentKelasData;
    return k['classroomId'] as String?;
  }

  /// Hanya guru yang punya pemetaan GuruMapel untuk mapel + kelas ini
  List<Map<String, dynamic>> get _filteredGuru {
    if (_selectedMapelId == null) return [];
    final kelasName = _currentKelasName;
    return _guruMapelList.where((gm) {
      if (gm['subjectId'] != _selectedMapelId) return false;
      if (kelasName.isEmpty) return true;
      final classes = (gm['classes'] ?? '').toString();
      return classes.split(',').map((e) => e.trim()).contains(kelasName);
    }).toList();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) setState(() { if (isStart) _startTime = picked; else _endTime = picked; });
  }

  Future<void> _save() async {
    if (_selectedDay == null || _selectedGuruId == null || _selectedMapelId == null || _selectedKelasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field yang wajib'), backgroundColor: Colors.red),
      );
      return;
    }
    // Validasi waktu sekolah
    final timeError = _validateSchedule();
    if (timeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.schedule, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(timeError)),
          ]),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        'classId': _selectedKelasId,
        'subjectId': _selectedMapelId,
        'guruId': _selectedGuruId,
        'roomId': _roomId,          // otomatis dari rombel kelas
        'day': _selectedDay,
        'startTime': _fmt(_startTime),
        'endTime': _fmt(_endTime),
        'slotIndex': _slotOf(_startTime),
      };
      if (widget.isEdit && widget.initialData != null) {
        await ApiService.updateJadwal(widget.initialData!['id'], payload);
      } else {
        await ApiService.createJadwal(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        String msg = 'Terjadi kesalahan';
        if (e is DioException && e.response?.data != null) msg = e.response!.data['message'] ?? msg;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: AppColors.gray50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground)),
  );

  Widget _scheduleInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(children: [
      SizedBox(width: 88, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF)))),
      const Text(': ', style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF))),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final filteredGuru = _filteredGuru;
    // Pastikan value selalu null atau ada di dalam items list (mencegah dropdown assertion)
    final safeMapelId = _mapelList.any((e) => e['id'] == _selectedMapelId)
        ? _selectedMapelId : null;
    final safeGuruId = filteredGuru.any((g) => g['teacherId'] == _selectedGuruId)
        ? _selectedGuruId : null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.isEdit ? 'Edit Jadwal' : 'Tambah Jadwal Baru',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Guru Pengajar hanya tampil sesuai pemetaan Guru-Mapel untuk kelas ini.',
                style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
              )),
            ]),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          else ...[
            // Kelas
            _label('Kelas'),
            DropdownButtonFormField<String>(
              initialValue: _selectedKelasId,
              menuMaxHeight: 250,
              items: widget.kelasList.map((e) => DropdownMenuItem(
                value: e['id'] as String,
                child: Text(e['name'] ?? e['nama'] ?? ''),
              )).toList(),
              onChanged: (v) => setState(() {
                _selectedKelasId = v;
                _selectedMapelId = null;
                _selectedGuruId = null;
              }),
              decoration: _deco('Pilih Kelas'),
            ),
            const SizedBox(height: 12),
            // Hari
            _label('Hari'),
            DropdownButtonFormField<String>(
              initialValue: _selectedDay,
              items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _selectedDay = v),
              decoration: _deco('Pilih Hari'),
            ),
            const SizedBox(height: 12),
            // Info jadwal sekolah
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.info_outlined, size: 14, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 6),
                  Text('Jadwal Sekolah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                ]),
                const SizedBox(height: 6),
                _scheduleInfoRow('Jam Masuk', '07:00'),
                _scheduleInfoRow('Istirahat 1', '09:00 – 10:00'),
                _scheduleInfoRow('Istirahat 2', '12:00 – 13:00'),
                _scheduleInfoRow('Jam Pulang', '16:00'),
              ]),
            ),
            const SizedBox(height: 12),
            // Waktu
            _label('Waktu Mulai & Selesai'),
            Row(children: [
              Expanded(child: InkWell(
                onTap: () => _pickTime(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _validateSchedule() != null ? const Color(0xFFDC2626) : AppColors.gray300),
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(_fmt(_startTime), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Text('Mulai', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                  ]),
                ),
              )),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.arrow_forward, size: 18, color: AppColors.gray400)),
              Expanded(child: InkWell(
                onTap: () => _pickTime(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _validateSchedule() != null ? const Color(0xFFDC2626) : AppColors.gray300),
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time, size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(_fmt(_endTime), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Text('Selesai', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                  ]),
                ),
              )),
            ]),
            // Inline error waktu
            if (_validateSchedule() != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, size: 15, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    _validateSchedule()!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                  )),
                ]),
              ),
            ],
            // Mata Pelajaran — scrollable
            _label('Mata Pelajaran'),
            DropdownButtonFormField<String>(
              value: safeMapelId,
              menuMaxHeight: 280,
              items: _mapelList.map((e) => DropdownMenuItem(
                value: e['id'] as String,
                child: Text(e['name'] ?? e['nama'] ?? '', overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => setState(() {
                _selectedMapelId = v;
                _selectedGuruId = null;
              }),
              decoration: _deco('Pilih Mata Pelajaran'),
            ),
            const SizedBox(height: 12),
            // Guru Pengajar — filtered
            _label('Guru Pengajar'),
            if (_selectedMapelId == null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray300)),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.gray400),
                  SizedBox(width: 8),
                  Text('Pilih mata pelajaran terlebih dahulu', style: TextStyle(color: AppColors.gray400, fontSize: 14)),
                ]),
              )
            else if (filteredGuru.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFCA5A5))),
                child: const Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Belum ada guru yang dipetakan untuk mata pelajaran & kelas ini.\nTambahkan di menu Pemetaan Guru-Mapel terlebih dahulu.',
                    style: TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                  )),
                ]),
              )
            else
              DropdownButtonFormField<String>(
                value: safeGuruId,
                menuMaxHeight: 280,
                items: filteredGuru.map((g) => DropdownMenuItem(
                  value: g['teacherId'] as String,
                  child: Text(g['teacher'] ?? '', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setState(() => _selectedGuruId = v),
                decoration: _deco('Pilih Guru'),
              ),
            const SizedBox(height: 12),
            // Ruang Kelas — read-only, otomatis dari rombel kelas yang dipilih
            _label('Ruang Kelas'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray300),
              ),
              child: Row(children: [
                Icon(
                  _roomId != null ? Icons.meeting_room_outlined : Icons.no_meeting_room_outlined,
                  size: 18,
                  color: _roomId != null ? AppColors.primary : AppColors.gray400,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  _roomDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    color: _roomId != null ? AppColors.foreground : AppColors.gray400,
                    fontWeight: _roomId != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Dari Rombel', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            // Tombol aksi
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.gray600, side: const BorderSide(color: AppColors.gray300), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal'),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
