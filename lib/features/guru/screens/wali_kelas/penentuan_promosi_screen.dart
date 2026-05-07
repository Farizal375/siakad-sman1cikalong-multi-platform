// File: lib/features/guru/screens/wali_kelas/penentuan_promosi_screen.dart
// ===========================================
// PENENTUAN STATUS KENAIKAN KELAS — Wali Kelas
// Accessible at end of Semester Genap.
// DataTable of students with toggleable status badge.
// "Validasi & Kunci Data" button to finalize decisions.
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../kurikulum/controllers/migrasi_controller.dart';
import '../../providers/homeroom_provider.dart';

class PenentuanPromosiScreen extends ConsumerStatefulWidget {
  const PenentuanPromosiScreen({super.key});

  @override
  ConsumerState<PenentuanPromosiScreen> createState() =>
      _PenentuanPromosiScreenState();
}

class _PenentuanPromosiScreenState
    extends ConsumerState<PenentuanPromosiScreen> {
  bool _loading = true;
  bool _saving = false;
  String _searchQuery = '';

  String? _assignedRombelId;
  String _assignedRombelName = '-';
  String _tahunAjaran = '-';
  String _semesterLabel = '-';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final homeroom = await ref.read(homeroomContextProvider.future);
    if (!homeroom.hasClass || homeroom.rombelId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _assignedRombelId = homeroom.rombelId;
    _assignedRombelName = homeroom.kelas;
    _tahunAjaran = homeroom.tahunAjaran;
    _semesterLabel = homeroom.semesterAktif?.label ?? '-';

    await ref
        .read(promosiStatusProvider.notifier)
        .loadSiswa(homeroom.rombelId!);
    if (mounted) setState(() => _loading = false);
  }

  void _toggleStatus(String siswaId) {
    final state = ref.read(promosiStatusProvider);
    if (state.isLocked) return;
    ref.read(promosiStatusProvider.notifier).toggleStatus(siswaId);
  }

  Future<void> _batalkanKunci() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_open_outlined,
                color: AppColors.destructive,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Batalkan Kunci Data?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semua status kenaikan siswa akan direset dan kunci data akan dibuka.'
              ' Anda perlu menentukan ulang keputusan kenaikan untuk setiap siswa.',
              style: TextStyle(fontSize: 14, color: AppColors.gray600),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: AppColors.accent),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tindakan ini tidak dapat dibatalkan secara otomatis.',
                    style: TextStyle(fontSize: 13, color: AppColors.gray500),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.gray600)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.lock_open, size: 18),
            label: const Text('Ya, Batalkan Kunci'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    final result = await ref.read(promosiStatusProvider.notifier).batalkanKunci();
    if (mounted) {
      setState(() => _saving = false);
      if (result == null) {
        _showFeedback('Kunci dibatalkan. Silakan tentukan ulang status kenaikan siswa.');
      } else {
        _showFeedback(result, isError: true);
      }
    }
  }

  Future<void> _validasiDanKunci() async {
    final notifier = ref.read(promosiStatusProvider.notifier);
    final jumlahTinggal = notifier.jumlahTinggal;
    final jumlahPerluCek = notifier.jumlahPerluCek;

    if (jumlahPerluCek > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$jumlahPerluCek siswa masih perlu dicek sebelum data dikunci.',
          ),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppColors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Validasi & Kunci Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Setelah data dikunci, status kenaikan tidak dapat diubah lagi. '
              'Data ini akan digunakan oleh Kurikulum untuk proses migrasi kelas.',
              style: TextStyle(fontSize: 14, color: AppColors.gray600),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    'Naik Kelas',
                    '${notifier.jumlahNaik} siswa',
                    AppColors.green600,
                    Icons.arrow_upward,
                  ),
                  const SizedBox(height: 12),
                  _summaryRow(
                    'Tinggal Kelas',
                    '$jumlahTinggal siswa',
                    AppColors.destructive,
                    Icons.block,
                  ),
                ],
              ),
            ),
            if (jumlahTinggal > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.red200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      size: 18,
                      color: AppColors.destructive,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$jumlahTinggal siswa akan tinggal kelas. Pastikan keputusan sudah final.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.destructive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.gray600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.lock, size: 18),
            label: const Text('Kunci Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    final result = await ref
        .read(promosiStatusProvider.notifier)
        .validasiDanKunci();

    if (mounted) {
      setState(() {
        _saving = false;
      });
      if (result == null) {
        _showFeedback(
          'Data kenaikan berhasil dikunci! Kurikulum dapat memproses migrasi.',
        );
      } else {
        _showFeedback(result, isError: true);
      }
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.destructive : AppColors.green600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.foreground,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promosiStatusProvider);
    final siswaList = state.siswaList;

    if (_loading || state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assignedRombelId == null) {
      return const Center(
        child: Text('Anda belum ditugaskan sebagai wali kelas'),
      );
    }

    // Filter by search
    final filteredList = _searchQuery.isEmpty
        ? siswaList
        : siswaList
              .where(
                (s) =>
                    s.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    s.nisn.contains(_searchQuery),
              )
              .toList();

    final notifier = ref.read(promosiStatusProvider.notifier);

    if (MediaQuery.sizeOf(context).width < 900) {
      return _buildCompactLayout(
        state,
        filteredList,
        notifier,
        siswaList.length,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Page Header ──
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penentuan Status Kenaikan Kelas',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rombel $_assignedRombelName • Tahun Ajaran $_tahunAjaran • $_semesterLabel',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            if (state.isLocked) ...
              [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.green600),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: AppColors.green600, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Data Terkunci',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.green600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _batalkanKunci,
                    icon: _saving
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open_outlined, size: 18),
                    label: const Text('Batalkan Kunci'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.destructive,
                      side: const BorderSide(color: AppColors.destructive),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
          ],
        ),
        const SizedBox(height: 24),

        // ── Summary KPI Cards ──
        Row(
          children: [
            _buildKpiCard(
              'Total Siswa',
              '${siswaList.length}',
              Icons.people,
              AppColors.primary,
              const Color(0xFF2563EB),
            ),
            const SizedBox(width: 16),
            _buildKpiCard(
              'Naik Kelas',
              '${notifier.jumlahNaik}',
              Icons.trending_up,
              AppColors.green600,
              const Color(0xFF16A34A),
            ),
            const SizedBox(width: 16),
            _buildKpiCard(
              'Tinggal Kelas',
              '${notifier.jumlahTinggal}',
              Icons.block,
              AppColors.destructive,
              const Color(0xFFDC2626),
            ),
            const SizedBox(width: 16),
            _buildKpiCard(
              'Perlu Cek',
              '${notifier.jumlahPerluCek}',
              Icons.rule,
              AppColors.accent,
              const Color(0xFFF59E0B),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Table Card ──
        Expanded(
          child: Container(
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
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.table_chart_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Daftar Siswa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${filteredList.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Search
                      SizedBox(
                        width: 280,
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Cari nama / NISN...',
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 18,
                              color: AppColors.gray400,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.gray50,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.gray300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.gray300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Data Table
                Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                          AppColors.gray50,
                        ),
                        headingTextStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray700,
                        ),
                        dataTextStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.foreground,
                        ),
                        columnSpacing: 24,
                        horizontalMargin: 20,
                        columns: const [
                          DataColumn(label: Text('No')),
                          DataColumn(label: Text('Nama Siswa')),
                          DataColumn(label: Text('NISN')),
                          DataColumn(
                            label: Text('Rata-rata Nilai'),
                            numeric: true,
                          ),
                          DataColumn(label: Text('Kehadiran'), numeric: true),
                          DataColumn(label: Text('Status Kenaikan')),
                          DataColumn(label: Text('Aksi')),
                        ],
                        rows: filteredList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final s = entry.value;
                          final isNaik = s.status == StatusKenaikan.naik;
                          final isPerluCek =
                              s.status == StatusKenaikan.perluCek;
                          return DataRow(
                            color: WidgetStatePropertyAll(
                              idx.isEven
                                  ? Colors.white
                                  : const Color(0xFFFAFAFB),
                            ),
                            cells: [
                              DataCell(Text('${idx + 1}')),
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      child: Text(
                                        s.nama[0],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      s.nama,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  s.nisn,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  s.nilaiRataRata.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: s.nilaiRataRata >= 75
                                        ? AppColors.green600
                                        : AppColors.destructive,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(99),
                                        child: LinearProgressIndicator(
                                          value: s.persentaseKehadiran / 100,
                                          minHeight: 6,
                                          backgroundColor: AppColors.gray200,
                                          valueColor: AlwaysStoppedAnimation(
                                            s.persentaseKehadiran >= 80
                                                ? AppColors.green600
                                                : AppColors.destructive,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${s.persentaseKehadiran}%',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: s.persentaseKehadiran >= 80
                                            ? AppColors.green600
                                            : AppColors.destructive,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(_buildStatusBadge(s)),
                              DataCell(
                                state.isLocked
                                    ? const Icon(
                                        Icons.lock,
                                        size: 16,
                                        color: AppColors.gray400,
                                      )
                                    : IconButton(
                                        onPressed: () => _toggleStatus(s.id),
                                        icon: Icon(
                                          isNaik
                                              ? Icons.thumb_down_outlined
                                              : Icons.thumb_up_outlined,
                                          size: 18,
                                          color: isPerluCek
                                              ? AppColors.accent
                                              : isNaik
                                              ? AppColors.destructive
                                              : AppColors.green600,
                                        ),
                                        tooltip: isPerluCek
                                            ? 'Tetapkan Naik Kelas'
                                            : isNaik
                                            ? 'Ubah ke Tinggal Kelas'
                                            : 'Ubah ke Naik Kelas',
                                        style: IconButton.styleFrom(
                                          backgroundColor: isPerluCek
                                              ? AppColors.amber50
                                              : isNaik
                                              ? AppColors.red50
                                              : AppColors.green50,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                // Footer — Validasi Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.amber200),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.accent,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Klik ikon aksi untuk mengubah status kenaikan siswa',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.gray700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (state.isLocked)
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _batalkanKunci,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.lock_open_outlined, size: 20),
                            label: const Text('Batalkan Kunci'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.destructive,
                              side: const BorderSide(color: AppColors.destructive),
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (!state.isLocked)
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _saving || notifier.jumlahPerluCek > 0
                                ? null
                                : _validasiDanKunci,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock, size: 20),
                            label: Text(
                              _saving
                                  ? 'Memproses...'
                                  : 'Validasi & Kunci Data',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(
    PromosiStatusState state,
    List<SiswaPromosi> filteredList,
    PromosiStatusNotifier notifier,
    int totalSiswa,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penentuan Status Kenaikan Kelas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rombel $_assignedRombelName • Tahun Ajaran $_tahunAjaran • $_semesterLabel',
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
          if (state.isLocked) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green600),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: AppColors.green600, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Data Terkunci',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.green600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _batalkanKunci,
                icon: _saving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_outlined, size: 18),
                label: Text(_saving ? 'Memproses...' : 'Batalkan Kunci Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.destructive,
                  side: const BorderSide(color: AppColors.destructive),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 520;
              final itemWidth = twoColumns
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _compactKpiCard(
                      'Total Siswa',
                      '$totalSiswa',
                      Icons.people,
                      AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _compactKpiCard(
                      'Naik Kelas',
                      '${notifier.jumlahNaik}',
                      Icons.trending_up,
                      AppColors.green600,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _compactKpiCard(
                      'Tinggal Kelas',
                      '${notifier.jumlahTinggal}',
                      Icons.block,
                      AppColors.destructive,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _compactKpiCard(
                      'Perlu Cek',
                      '${notifier.jumlahPerluCek}',
                      Icons.rule,
                      AppColors.accent,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
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
                Row(
                  children: [
                    const Icon(
                      Icons.table_chart_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Daftar Siswa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${filteredList.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari nama / NISN...',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.gray400,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.gray50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...filteredList.asMap().entries.map(
                  (entry) => _buildCompactStudentCard(
                    entry.value,
                    entry.key,
                    state.isLocked,
                  ),
                ),
                if (filteredList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Tidak ada siswa yang cocok.',
                        style: TextStyle(color: AppColors.gray500),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!state.isLocked)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saving || notifier.jumlahPerluCek > 0
                    ? null
                    : _validasiDanKunci,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock, size: 20),
                label: Text(_saving ? 'Memproses...' : 'Validasi & Kunci Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _compactKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStudentCard(SiswaPromosi siswa, int idx, bool isLocked) {
    final isNaik = siswa.status == StatusKenaikan.naik;
    final isPerluCek = siswa.status == StatusKenaikan.perluCek;
    final initial = siswa.nama.isNotEmpty ? siswa.nama[0] : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${idx + 1}. ${siswa.nama}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    Text(
                      'NISN: ${siswa.nisn}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _compactInfoChip(
                'Rata-rata',
                siswa.nilaiRataRata.toStringAsFixed(1),
                siswa.nilaiRataRata >= 75
                    ? AppColors.green600
                    : AppColors.destructive,
              ),
              _compactInfoChip(
                'Kehadiran',
                '${siswa.persentaseKehadiran}%',
                siswa.persentaseKehadiran >= 80
                    ? AppColors.green600
                    : AppColors.destructive,
              ),
              _buildStatusBadge(siswa),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLocked ? null : () => _toggleStatus(siswa.id),
              icon: Icon(
                isLocked
                    ? Icons.lock
                    : isNaik
                    ? Icons.thumb_down_outlined
                    : Icons.thumb_up_outlined,
                size: 18,
              ),
              label: Text(
                isLocked
                    ? 'Data terkunci'
                    : isPerluCek
                    ? 'Tetapkan Naik Kelas'
                    : isNaik
                    ? 'Ubah ke Tinggal Kelas'
                    : 'Ubah ke Naik Kelas',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isLocked
                    ? AppColors.gray500
                    : isPerluCek
                    ? AppColors.accent
                    : isNaik
                    ? AppColors.destructive
                    : AppColors.green600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color gradientEnd,
  ) {
    return Expanded(
      child: Container(
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, gradientEnd],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SiswaPromosi siswa) {
    if (siswa.status == StatusKenaikan.perluCek) {
      final label = siswa.missingData.isEmpty
          ? 'Perlu Cek'
          : 'Perlu Cek: ${siswa.missingData.join(', ')}';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.amber50,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rule, size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      );
    }

    final isNaik = siswa.status == StatusKenaikan.naik;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isNaik ? AppColors.green50 : AppColors.red50,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isNaik
              ? AppColors.green600.withValues(alpha: 0.3)
              : AppColors.destructive.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNaik ? Icons.arrow_upward : Icons.block,
            size: 14,
            color: isNaik ? AppColors.green600 : AppColors.destructive,
          ),
          const SizedBox(width: 4),
          Text(
            isNaik ? 'Naik Kelas' : 'Tinggal Kelas',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isNaik ? AppColors.green600 : AppColors.destructive,
            ),
          ),
        ],
      ),
    );
  }
}
