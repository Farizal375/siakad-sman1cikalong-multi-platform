// File: lib/features/kurikulum/screens/migrasi_kelas_wizard.dart
// ===========================================
// MIGRASI KELAS WIZARD — Kurikulum
// Wizard UI (Stepper) to perform student promotion.
// Step 1: Select Source Rombel
// Step 2: Review (Naik vs Tinggal)
// Step 3: Select Target Rombel
// Step 4: Execute & Confirm
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/migrasi_controller.dart';

class MigrasiKelasWizard extends ConsumerStatefulWidget {
  const MigrasiKelasWizard({super.key});

  @override
  ConsumerState<MigrasiKelasWizard> createState() => _MigrasiKelasWizardState();
}

class _MigrasiKelasWizardState extends ConsumerState<MigrasiKelasWizard> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(migrasiProvider.notifier).loadMasterData();
    });
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _canProceedToStep2(MigrasiState state) {
    return state.tahunAjaranLamaId != null &&
        state.rombelAsalId != null &&
        state.siswaList.isNotEmpty;
  }

  bool _canProceedToStep4(MigrasiState state) {
    return state.tahunAjaranBaruId != null && state.rombelTujuanId != null;
  }

  Future<void> _execute() async {
    final errorMsg = await ref
        .read(migrasiProvider.notifier)
        .executePromotion();
    if (mounted) {
      if (errorMsg == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Migrasi Kelas Berhasil Dieksekusi!')),
              ],
            ),
            backgroundColor: AppColors.green600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(migrasiProvider);
    final notifier = ref.read(migrasiProvider.notifier);
    final isNarrow = MediaQuery.sizeOf(context).width < 780;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        const Text(
          'Wizard Kenaikan Kelas',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Panduan langkah demi langkah untuk memindahkan siswa antar tahun ajaran',
          style: TextStyle(fontSize: 14, color: AppColors.gray600),
        ),
        const SizedBox(height: 24),

        // ── Stepper Card ──
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
            child: state.isDone
                ? _buildSuccessScreen(notifier)
                : Stepper(
                    type: isNarrow
                        ? StepperType.vertical
                        : StepperType.horizontal,
                    currentStep: _currentStep,
                    onStepCancel: _prevStep,
                    onStepContinue: () {
                      if (_currentStep == 0 && !_canProceedToStep2(state)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pilih Tahun Ajaran dan Rombel Asal'),
                            backgroundColor: AppColors.destructive,
                          ),
                        );
                        return;
                      }
                      if (_currentStep == 2) {
                        if (!_canProceedToStep4(state)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pilih Tahun Ajaran dan Rombel Tujuan',
                              ),
                              backgroundColor: AppColors.destructive,
                            ),
                          );
                          return;
                        }
                        if (state.rombelAsalId == state.rombelTujuanId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Rombel Asal dan Rombel Tujuan tidak boleh sama!',
                              ),
                              backgroundColor: AppColors.destructive,
                            ),
                          );
                          return;
                        }
                      }
                      if (_currentStep == 3) {
                        _execute();
                      } else {
                        _nextStep();
                      }
                    },
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: isNarrow
                              ? WrapAlignment.start
                              : WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (_currentStep > 0)
                              OutlinedButton(
                                onPressed: details.onStepCancel,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Kembali'),
                              ),
                            ElevatedButton(
                              onPressed: state.isProcessing
                                  ? null
                                  : details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: state.isProcessing && _currentStep == 3
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _currentStep == 3
                                          ? 'Eksekusi Migrasi'
                                          : 'Lanjut',
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      // STEP 1: Pilih Sumber
                      Step(
                        title: const Text('Sumber'),
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStep1(state, notifier),
                      ),
                      // STEP 2: Review
                      Step(
                        title: const Text('Review Data'),
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStep2(state),
                      ),
                      // STEP 3: Pilih Tujuan
                      Step(
                        title: const Text('Tujuan'),
                        isActive: _currentStep >= 2,
                        state: _currentStep > 2
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildStep3(state, notifier),
                      ),
                      // STEP 4: Eksekusi
                      Step(
                        title: const Text('Eksekusi'),
                        isActive: _currentStep >= 3,
                        content: _buildStep4(state),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ── Step 1 UI ──
  Widget _buildStep1(MigrasiState state, MigrasiNotifier notifier) {
    final isNarrow = MediaQuery.sizeOf(context).width < 780;
    final tas = state.tahunAjaranList;
    final rombels = state.tahunAjaranLamaId != null
        ? state.rombelList
              .where(
                (r) => r['tahunAjaranId'].toString() == state.tahunAjaranLamaId,
              )
              .toList()
        : <dynamic>[];

    if (state.isLoadingData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Rombel Asal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tentukan dari rombel mana siswa akan dipromosikan.',
          style: TextStyle(color: AppColors.gray600),
        ),
        const SizedBox(height: 24),
        isNarrow
            ? Column(
                children: [
                  _fieldGroup(
                    'Tahun Ajaran Asal',
                    DropdownButtonFormField<String>(
                      initialValue: state.tahunAjaranLamaId,
                      items: tas
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e['id'].toString(),
                              child: Text(
                                (e['code'] ?? e['kode'] ?? '').toString(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => notifier.setTahunAjaranLama(v!),
                      decoration: _inputDeco('Pilih Tahun Ajaran Asal'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _fieldGroup(
                    'Rombel Asal',
                    DropdownButtonFormField<String>(
                      initialValue: state.rombelAsalId,
                      items: rombels.isEmpty && state.tahunAjaranLamaId != null
                          ? [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Belum ada data rombel'),
                              ),
                            ]
                          : rombels
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e['id'].toString(),
                                    child: Text(
                                      '${e['masterKelasName']} (${e['siswaCount']} Siswa)',
                                    ),
                                  ),
                                )
                                .toList(),
                      onChanged:
                          state.tahunAjaranLamaId == null || rombels.isEmpty
                          ? null
                          : (v) => notifier.setRombelAsal(v!),
                      decoration: _inputDeco('Pilih Rombel Asal'),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _fieldGroup(
                      'Tahun Ajaran Asal',
                      DropdownButtonFormField<String>(
                        initialValue: state.tahunAjaranLamaId,
                        items: tas
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e['id'].toString(),
                                child: Text(
                                  (e['code'] ?? e['kode'] ?? '').toString(),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => notifier.setTahunAjaranLama(v!),
                        decoration: _inputDeco('Pilih Tahun Ajaran Asal'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _fieldGroup(
                      'Rombel Asal',
                      DropdownButtonFormField<String>(
                        initialValue: state.rombelAsalId,
                        items:
                            rombels.isEmpty && state.tahunAjaranLamaId != null
                            ? [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('Belum ada data rombel'),
                                ),
                              ]
                            : rombels
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e['id'].toString(),
                                      child: Text(
                                        '${e['masterKelasName']} (${e['siswaCount']} Siswa)',
                                      ),
                                    ),
                                  )
                                  .toList(),
                        onChanged:
                            state.tahunAjaranLamaId == null || rombels.isEmpty
                            ? null
                            : (v) => notifier.setRombelAsal(v!),
                        decoration: _inputDeco('Pilih Rombel Asal'),
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  // ── Step 2 UI ──
  Widget _buildStep2(MigrasiState state) {
    final isNarrow = MediaQuery.sizeOf(context).width < 780;
    if (state.siswaList.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Status Kenaikan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pastikan data keputusan dari Wali Kelas sudah benar. '
          'Hanya siswa dengan status "Naik Kelas" yang akan dimigrasikan.',
          style: TextStyle(color: AppColors.gray600),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              'Total Siswa',
              '${state.siswaList.length}',
              AppColors.blue50,
              AppColors.blue600,
              wide: !isNarrow,
            ),
            _buildStatCard(
              'Siap Naik Kelas',
              '${state.siswaNaik.length}',
              AppColors.green50,
              AppColors.green600,
              wide: !isNarrow,
            ),
            _buildStatCard(
              'Tinggal Kelas',
              '${state.siswaTinggal.length}',
              AppColors.red50,
              AppColors.destructive,
              wide: !isNarrow,
            ),
            _buildStatCard(
              'Perlu Cek',
              '${state.siswaList.where((s) => s.status == StatusKenaikan.perluCek).length}',
              AppColors.amber50,
              AppColors.accent,
              wide: !isNarrow,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.siswaList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = state.siswaList[i];
              final isNaik = s.status == StatusKenaikan.naik;
              final isPerluCek = s.status == StatusKenaikan.perluCek;
              final badgeColor = isPerluCek
                  ? AppColors.accent
                  : (isNaik ? AppColors.green600 : AppColors.destructive);
              final badgeBg = isPerluCek
                  ? AppColors.amber50
                  : (isNaik ? AppColors.green50 : AppColors.red50);
              final badgeText = isPerluCek
                  ? 'Perlu Cek'
                  : (isNaik ? 'Naik Kelas' : 'Tinggal Kelas');
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.gray100,
                  child: Text(
                    s.nama[0],
                    style: const TextStyle(color: AppColors.gray600),
                  ),
                ),
                title: Text(
                  s.nama,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('NISN: ${s.nisn}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Step 3 UI ──
  Widget _buildStep3(MigrasiState state, MigrasiNotifier notifier) {
    final isNarrow = MediaQuery.sizeOf(context).width < 780;
    final tas = state.tahunAjaranList;
    final rombels = state.tahunAjaranBaruId != null
        ? state.rombelList
              .where(
                (r) => r['tahunAjaranId'].toString() == state.tahunAjaranBaruId,
              )
              .toList()
        : <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Rombel Tujuan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tentukan rombel baru untuk menampung siswa yang naik kelas.',
          style: TextStyle(color: AppColors.gray600),
        ),
        const SizedBox(height: 24),
        isNarrow
            ? Column(
                children: [
                  _fieldGroup(
                    'Tahun Ajaran Baru',
                    DropdownButtonFormField<String>(
                      initialValue: state.tahunAjaranBaruId,
                      items: tas
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e['id'].toString(),
                              child: Text(
                                (e['code'] ?? e['kode'] ?? '').toString(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => notifier.setTahunAjaranBaru(v!),
                      decoration: _inputDeco('Pilih Tahun Ajaran Tujuan'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _fieldGroup(
                    'Rombel Tujuan',
                    DropdownButtonFormField<String>(
                      initialValue: state.rombelTujuanId,
                      items: rombels.isEmpty && state.tahunAjaranBaruId != null
                          ? [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Belum ada data rombel'),
                              ),
                            ]
                          : rombels
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e['id'].toString(),
                                    child: Text(
                                      '${e['masterKelasName']} (${e['siswaCount']} Siswa saat ini)',
                                    ),
                                  ),
                                )
                                .toList(),
                      onChanged:
                          state.tahunAjaranBaruId == null || rombels.isEmpty
                          ? null
                          : (v) => notifier.setRombelTujuan(v!),
                      decoration: _inputDeco('Pilih Rombel Tujuan'),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _fieldGroup(
                      'Tahun Ajaran Baru',
                      DropdownButtonFormField<String>(
                        initialValue: state.tahunAjaranBaruId,
                        items: tas
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e['id'].toString(),
                                child: Text(
                                  (e['code'] ?? e['kode'] ?? '').toString(),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => notifier.setTahunAjaranBaru(v!),
                        decoration: _inputDeco('Pilih Tahun Ajaran Tujuan'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _fieldGroup(
                      'Rombel Tujuan',
                      DropdownButtonFormField<String>(
                        initialValue: state.rombelTujuanId,
                        items:
                            rombels.isEmpty && state.tahunAjaranBaruId != null
                            ? [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('Belum ada data rombel'),
                                ),
                              ]
                            : rombels
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e['id'].toString(),
                                      child: Text(
                                        '${e['masterKelasName']} (${e['siswaCount']} Siswa saat ini)',
                                      ),
                                    ),
                                  )
                                  .toList(),
                        onChanged:
                            state.tahunAjaranBaruId == null || rombels.isEmpty
                            ? null
                            : (v) => notifier.setRombelTujuan(v!),
                        decoration: _inputDeco('Pilih Rombel Tujuan'),
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  // ── Step 4 UI ──
  Widget _buildStep4(MigrasiState state) {
    // Extract readable names
    final taAsalObj = state.tahunAjaranList.firstWhere(
      (e) => e['id'].toString() == state.tahunAjaranLamaId,
      orElse: () => null,
    );
    final taAsalName = taAsalObj != null
        ? (taAsalObj['code'] ?? taAsalObj['kode'] ?? '-')
        : '-';

    final rombelAsalObj = state.rombelList.firstWhere(
      (e) => e['id'].toString() == state.rombelAsalId,
      orElse: () => null,
    );
    final rombelAsalName = rombelAsalObj != null
        ? rombelAsalObj['masterKelasName'] ?? '-'
        : '-';

    final taTujuanObj = state.tahunAjaranList.firstWhere(
      (e) => e['id'].toString() == state.tahunAjaranBaruId,
      orElse: () => null,
    );
    final taTujuanName = taTujuanObj != null
        ? (taTujuanObj['code'] ?? taTujuanObj['kode'] ?? '-')
        : '-';

    final rombelTujuanObj = state.rombelList.firstWhere(
      (e) => e['id'].toString() == state.rombelTujuanId,
      orElse: () => null,
    );
    final rombelTujuanName = rombelTujuanObj != null
        ? rombelTujuanObj['masterKelasName'] ?? '-'
        : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Konfirmasi Migrasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Periksa kembali ringkasan migrasi di bawah ini. Proses ini akan membuat riwayat RombelSiswa yang baru.',
          style: TextStyle(color: AppColors.gray600),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.amber50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.amber500),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUMBER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rombel: $rombelAsalName\nTahun Ajaran: $taAsalName',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.amber600),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TUJUAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rombel: $rombelTujuanName\nTahun Ajaran: $taTujuanName',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sebanyak ${state.siswaNaik.length} siswa akan dipindahkan. '
                  '${state.siswaTinggal.length} siswa yang tinggal kelas tidak akan ikut dipindahkan.',
                  style: const TextStyle(color: AppColors.foreground),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen(MigrasiNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.green50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.green600,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Migrasi Berhasil!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Siswa berhasil dipindahkan ke rombel baru.',
              style: TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                notifier.reset();
                setState(() => _currentStep = 0);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Migrasi Rombel Lain'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color bg,
    Color color, {
    bool wide = true,
  }) {
    return SizedBox(
      width: wide ? null : 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldGroup(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.gray50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }
}
