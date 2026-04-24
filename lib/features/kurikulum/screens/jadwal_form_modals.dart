// lib/features/kurikulum/screens/jadwal_form_modals.dart
// Form modals for Jadwal Pelajaran - all data loaded from DB
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';

// ═══════════════════════════════════════════════
// GURU-MAPEL FORM MODAL
// Fields: teacher (from Guru Mapel role), subject (MataPelajaran),
//         classes (free text), hoursPerWeek
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
        ApiService.getUsers(role: 'Guru Mapel', limit: 1000), // Fetch only Guru Mapel
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
            _selectedClasses = clsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
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
                  spacing: 8,
                  runSpacing: 8,
                  children: _kelasList.map((k) {
                    final className = k['name'] ?? k['nama'] ?? '';
                    final isSelected = _selectedClasses.contains(className);
                    return FilterChip(
                      label: Text(className),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedClasses.add(className);
                          } else {
                            _selectedClasses.remove(className);
                          }
                        });
                      },
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
// Fields: kelas, hari, startTime, endTime, mapel (from DB), guru (from DB), ruang
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
  List<Map<String, dynamic>> _guruList = [], _mapelList = [], _ruangList = [];

  String? _selectedDay, _selectedGuruId, _selectedMapelId, _selectedRuangId, _selectedKelasId;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 45);

  static const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
  static const _slotStarts = [
    TimeOfDay(hour: 7, minute: 0), TimeOfDay(hour: 7, minute: 45),
    TimeOfDay(hour: 8, minute: 30), TimeOfDay(hour: 9, minute: 30),
    TimeOfDay(hour: 10, minute: 15), TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 13, minute: 0), TimeOfDay(hour: 13, minute: 45),
  ];

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
      _selectedRuangId = d['roomId'];
      _selectedKelasId = d['classId'] ?? widget.kelasId;
      final st = d['startTime'] ?? '07:00';
      final et = d['endTime'] ?? '07:45';
      _startTime = _parse(st);
      _endTime = _parse(et);
    }
  }

  TimeOfDay _parse(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.tryParse(p[0]) ?? 7, minute: int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _slotOf(TimeOfDay t) {
    int closest = 0, minDiff = 9999;
    for (int i = 0; i < _slotStarts.length; i++) {
      final diff = ((_slotStarts[i].hour * 60 + _slotStarts[i].minute) - (t.hour * 60 + t.minute)).abs();
      if (diff < minDiff) { minDiff = diff; closest = i; }
    }
    return closest;
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService.getUsers(role: 'Guru Mapel', limit: 1000),
        ApiService.getMataPelajaran(),
        ApiService.getRuangKelas(),
      ]);
      if (mounted) setState(() {
        _guruList = ((results[0]['data'] as List?) ?? []).cast<Map<String, dynamic>>();
        _mapelList = ((results[1]['data'] as List?) ?? []).cast<Map<String, dynamic>>();
        _ruangList = ((results[2]['data'] as List?) ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _startTime : _endTime);
    if (picked != null) setState(() { if (isStart) _startTime = picked; else _endTime = picked; });
  }

  Future<void> _save() async {
    if (_selectedDay == null || _selectedGuruId == null || _selectedMapelId == null || _selectedKelasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field yang wajib'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    final payload = {
      'classId': _selectedKelasId,
      'subjectId': _selectedMapelId,
      'guruId': _selectedGuruId,
      'roomId': _selectedRuangId,
      'day': _selectedDay,
      'startTime': _fmt(_startTime),
      'endTime': _fmt(_endTime),
      'slotIndex': _slotOf(_startTime),
    };
    try {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.isEdit ? 'Edit Jadwal' : 'Tambah Jadwal Baru',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF59E0B))),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Sistem menolak jika Guru dijadwalkan ganda pada hari & jam yang sama.', style: TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
            ]),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          else ...[
            _label('Kelas'),
            DropdownButtonFormField<String>(
              initialValue: _selectedKelasId,
              items: widget.kelasList.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] ?? e['nama'] ?? ''))).toList(),
              onChanged: (v) => setState(() => _selectedKelasId = v),
              decoration: _deco('Pilih Kelas'),
            ),
            const SizedBox(height: 12),
            _label('Hari'),
            DropdownButtonFormField<String>(
              initialValue: _selectedDay,
              items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _selectedDay = v),
              decoration: _deco('Pilih Hari'),
            ),
            const SizedBox(height: 12),
            _label('Waktu Mulai & Selesai'),
            Row(children: [
              Expanded(child: InkWell(
                onTap: () => _pickTime(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray300)),
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
                  decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray300)),
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
            const SizedBox(height: 12),
            _label('Mata Pelajaran'),
            DropdownButtonFormField<String>(
              initialValue: _selectedMapelId,
              items: _mapelList.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] ?? e['nama'] ?? '', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _selectedMapelId = v),
              decoration: _deco('Pilih Mata Pelajaran'),
            ),
            const SizedBox(height: 12),
            _label('Guru Pengajar'),
            DropdownButtonFormField<String>(
              initialValue: _selectedGuruId,
              items: _guruList.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] ?? e['nama_lengkap'] ?? '', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _selectedGuruId = v),
              decoration: _deco('Pilih Guru'),
            ),
            const SizedBox(height: 12),
            _label('Ruang Kelas (Opsional)'),
            DropdownButtonFormField<String>(
              initialValue: _selectedRuangId,
              items: [
                const DropdownMenuItem(value: null, child: Text('Tidak ada / Belum ditentukan', style: TextStyle(color: AppColors.gray500))),
                ..._ruangList.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text('${e['code'] ?? e['kode'] ?? ''} (${e['capacity'] ?? e['kapasitas']})'))),
              ],
              onChanged: (v) => setState(() => _selectedRuangId = v),
              decoration: _deco('Pilih Ruangan'),
            ),
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
                  : Text(widget.isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal'),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
