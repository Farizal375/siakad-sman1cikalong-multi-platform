// File: lib/features/kurikulum/controllers/migrasi_controller.dart
// ===========================================
// MIGRASI KELAS CONTROLLER (Riverpod)
// - Fetches status kenaikan from Backend (API)
// - Filters only "Naik" students
// - Executes migration payload via Backend (API)
// ===========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_service.dart';

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

enum StatusKenaikan { naik, tinggal, perluCek }

class SiswaPromosi {
  final String id;
  final String nama;
  final String nisn;
  final double nilaiRataRata;
  final int persentaseKehadiran;
  final bool isDataComplete;
  final List<String> missingData;
  StatusKenaikan status;

  SiswaPromosi({
    required this.id,
    required this.nama,
    required this.nisn,
    required this.nilaiRataRata,
    required this.persentaseKehadiran,
    this.isDataComplete = true,
    this.missingData = const [],
    this.status = StatusKenaikan.naik,
  });

  SiswaPromosi copyWith({StatusKenaikan? status}) {
    return SiswaPromosi(
      id: id,
      nama: nama,
      nisn: nisn,
      nilaiRataRata: nilaiRataRata,
      persentaseKehadiran: persentaseKehadiran,
      isDataComplete: isDataComplete,
      missingData: missingData,
      status: status ?? this.status,
    );
  }

  factory SiswaPromosi.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString();
    return SiswaPromosi(
      id: json['id'],
      nama: json['nama'],
      nisn: json['nisn'] ?? '-',
      nilaiRataRata: (json['nilaiRataRata'] ?? 0).toDouble(),
      persentaseKehadiran: json['persentaseKehadiran'] ?? 0,
      isDataComplete: json['isDataComplete'] != false,
      missingData: (json['missingData'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      status: rawStatus == 'tinggal'
          ? StatusKenaikan.tinggal
          : (rawStatus == 'perluCek'
                ? StatusKenaikan.perluCek
                : StatusKenaikan.naik),
    );
  }
}

// ═══════════════════════════════════════════════
// WALI KELAS — Penentuan Status Provider
// ═══════════════════════════════════════════════

class PromosiStatusState {
  final List<SiswaPromosi> siswaList;
  final bool isLocked;
  final bool isLoading;

  const PromosiStatusState({
    this.siswaList = const [],
    this.isLocked = false,
    this.isLoading = false,
  });

  PromosiStatusState copyWith({
    List<SiswaPromosi>? siswaList,
    bool? isLocked,
    bool? isLoading,
  }) {
    return PromosiStatusState(
      siswaList: siswaList ?? this.siswaList,
      isLocked: isLocked ?? this.isLocked,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PromosiStatusNotifier extends StateNotifier<PromosiStatusState> {
  PromosiStatusNotifier() : super(const PromosiStatusState());

  String? _currentRombelId;

  /// Load students for a given rombel from Backend
  Future<void> loadSiswa(String rombelId) async {
    _currentRombelId = rombelId;
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiService.getSiswaPromosi(rombelId);
      final rawData = response['data'] as List;
      final siswaList = rawData.map((e) => SiswaPromosi.fromJson(e)).toList();
      state = state.copyWith(
        siswaList: siswaList,
        isLocked: response['isLocked'] == true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Handle error accordingly
    }
  }

  /// Toggle individual student status locally before locking
  void toggleStatus(String siswaId) {
    if (state.isLocked) return;

    final newList = state.siswaList.map((s) {
      if (s.id == siswaId) {
        return s.copyWith(
          status: s.status == StatusKenaikan.naik
              ? StatusKenaikan.tinggal
              : StatusKenaikan.naik,
        );
      }
      return s;
    }).toList();

    state = state.copyWith(siswaList: newList);
  }

  /// Lock/validate all decisions (POST to backend)
  Future<String?> validasiDanKunci() async {
    if (_currentRombelId == null) return 'Rombel belum dipilih.';
    if (state.siswaList.any((s) => s.status == StatusKenaikan.perluCek)) {
      return 'Masih ada siswa dengan status perlu dicek.';
    }

    try {
      final decisions = state.siswaList
          .map(
            (s) => {
              'siswaId': s.id,
              'status': s.status == StatusKenaikan.naik ? 'naik' : 'tinggal',
            },
          )
          .toList();

      await ApiService.lockPromosi({
        'rombelId': _currentRombelId,
        'decisions': decisions,
      });

      state = state.copyWith(isLocked: true);
      return null;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return e.response!.data['message']?.toString() ??
            'Gagal mengunci data promosi';
      }
      return 'Gagal mengunci data promosi';
    }
  }

  /// Batalkan kunci promosi — wali kelas bisa edit keputusan kembali
  Future<String?> batalkanKunci() async {
    if (_currentRombelId == null) return 'Rombel belum dipilih.';
    if (!state.isLocked) return 'Data belum dikunci.';

    try {
      await ApiService.unlockPromosi(_currentRombelId!);
      // Reload data dari server agar status siswa kembali fresh
      await loadSiswa(_currentRombelId!);
      return null; // sukses
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return e.response!.data['message']?.toString() ??
            'Gagal membatalkan kunci data promosi';
      }
      return 'Gagal membatalkan kunci data promosi';
    }
  }

  int get jumlahNaik =>
      state.siswaList.where((s) => s.status == StatusKenaikan.naik).length;
  int get jumlahTinggal =>
      state.siswaList.where((s) => s.status == StatusKenaikan.tinggal).length;
  int get jumlahPerluCek =>
      state.siswaList.where((s) => s.status == StatusKenaikan.perluCek).length;
}

final promosiStatusProvider =
    StateNotifierProvider<PromosiStatusNotifier, PromosiStatusState>((ref) {
      return PromosiStatusNotifier();
    });

// ═══════════════════════════════════════════════
// KURIKULUM — Migrasi Wizard State
// ═══════════════════════════════════════════════

class MigrasiState {
  final String? tahunAjaranLamaId;
  final String? rombelAsalId;
  final String? tahunAjaranBaruId;
  final String? rombelTujuanId;
  final List<SiswaPromosi> siswaList;

  final List<dynamic> tahunAjaranList;
  final List<dynamic> rombelList;

  final bool isLoadingData;
  final bool isLoadingRombelTujuan;
  final bool isProcessing;
  final bool isDone;

  const MigrasiState({
    this.tahunAjaranLamaId,
    this.rombelAsalId,
    this.tahunAjaranBaruId,
    this.rombelTujuanId,
    this.siswaList = const [],
    this.tahunAjaranList = const [],
    this.rombelList = const [],
    this.isLoadingData = false,
    this.isLoadingRombelTujuan = false,
    this.isProcessing = false,
    this.isDone = false,
  });

  MigrasiState copyWith({
    String? tahunAjaranLamaId,
    String? rombelAsalId,
    String? tahunAjaranBaruId,
    String? rombelTujuanId,
    List<SiswaPromosi>? siswaList,
    List<dynamic>? tahunAjaranList,
    List<dynamic>? rombelList,
    bool? isLoadingData,
    bool? isLoadingRombelTujuan,
    bool? isProcessing,
    bool? isDone,
  }) {
    return MigrasiState(
      tahunAjaranLamaId: tahunAjaranLamaId ?? this.tahunAjaranLamaId,
      rombelAsalId: rombelAsalId ?? this.rombelAsalId,
      tahunAjaranBaruId: tahunAjaranBaruId ?? this.tahunAjaranBaruId,
      rombelTujuanId: rombelTujuanId ?? this.rombelTujuanId,
      siswaList: siswaList ?? this.siswaList,
      tahunAjaranList: tahunAjaranList ?? this.tahunAjaranList,
      rombelList: rombelList ?? this.rombelList,
      isLoadingData: isLoadingData ?? this.isLoadingData,
      isLoadingRombelTujuan:
          isLoadingRombelTujuan ?? this.isLoadingRombelTujuan,
      isProcessing: isProcessing ?? this.isProcessing,
      isDone: isDone ?? this.isDone,
    );
  }

  /// Filtered list: only students with status Naik
  List<SiswaPromosi> get siswaNaik =>
      siswaList.where((s) => s.status == StatusKenaikan.naik).toList();

  /// Filtered list: only students with status Tinggal
  List<SiswaPromosi> get siswaTinggal =>
      siswaList.where((s) => s.status == StatusKenaikan.tinggal).toList();
}

class MigrasiNotifier extends StateNotifier<MigrasiState> {
  MigrasiNotifier() : super(const MigrasiState());

  /// Load master data (Tahun Ajaran & Rombel) when wizard starts
  Future<void> loadMasterData() async {
    state = state.copyWith(isLoadingData: true);
    try {
      final taResponse = await ApiService.getTahunAjaran();
      final rombelResponse = await ApiService.getRombel();

      state = state.copyWith(
        tahunAjaranList: taResponse['data'] ?? [],
        rombelList: rombelResponse['data'] ?? [],
        isLoadingData: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingData: false);
    }
  }

  List<dynamic> _replaceRombelByTahunAjaran(
    List<dynamic> current,
    String tahunAjaranId,
    List<dynamic> fetched,
  ) {
    final others = current
        .where((r) => r['tahunAjaranId'].toString() != tahunAjaranId)
        .toList();
    return [...others, ...fetched];
  }

  // ── Step 1: Set Source ──
  void setTahunAjaranLama(String id) {
    state = MigrasiState(
      tahunAjaranLamaId: id,
      rombelAsalId: null, // explicitly clear
      tahunAjaranBaruId: null,
      rombelTujuanId: null,
      siswaList: [], // explicitly clear
      tahunAjaranList: state.tahunAjaranList,
      rombelList: state.rombelList,
      isLoadingData: state.isLoadingData,
      isLoadingRombelTujuan: state.isLoadingRombelTujuan,
      isProcessing: state.isProcessing,
      isDone: state.isDone,
    );
  }

  Future<void> setRombelAsal(String id) async {
    state = MigrasiState(
      tahunAjaranLamaId: state.tahunAjaranLamaId,
      rombelAsalId: id,
      tahunAjaranBaruId: state.tahunAjaranBaruId,
      rombelTujuanId: null,
      siswaList: state.siswaList,
      tahunAjaranList: state.tahunAjaranList,
      rombelList: state.rombelList,
      isLoadingData: true,
      isLoadingRombelTujuan: state.isLoadingRombelTujuan,
      isProcessing: state.isProcessing,
      isDone: state.isDone,
    );
    try {
      final response = await ApiService.getSiswaPromosi(id);
      final rawData = response['data'] as List;
      final siswaList = rawData.map((e) => SiswaPromosi.fromJson(e)).toList();

      state = state.copyWith(siswaList: siswaList, isLoadingData: false);
    } catch (e) {
      state = state.copyWith(isLoadingData: false);
    }
  }

  // ── Step 3: Set Target ──
  Future<void> setTahunAjaranBaru(String id) async {
    state = MigrasiState(
      tahunAjaranLamaId: state.tahunAjaranLamaId,
      rombelAsalId: state.rombelAsalId,
      tahunAjaranBaruId: id,
      rombelTujuanId: null, // explicitly clear
      siswaList: state.siswaList,
      tahunAjaranList: state.tahunAjaranList,
      rombelList: state.rombelList,
      isLoadingData: state.isLoadingData,
      isLoadingRombelTujuan: true,
      isProcessing: state.isProcessing,
      isDone: state.isDone,
    );

    try {
      final response = await ApiService.getRombel(tahunAjaranId: id);
      final fetched = (response['data'] as List?) ?? [];
      if (state.tahunAjaranBaruId != id) return;
      state = state.copyWith(
        rombelList: _replaceRombelByTahunAjaran(state.rombelList, id, fetched),
        isLoadingRombelTujuan: false,
      );
    } catch (e) {
      if (state.tahunAjaranBaruId == id) {
        state = state.copyWith(isLoadingRombelTujuan: false);
      }
    }
  }

  void setRombelTujuan(String id) {
    state = state.copyWith(rombelTujuanId: id);
  }

  Future<void> refreshRombelTujuan({String? selectRombelId}) async {
    final tahunAjaranId = state.tahunAjaranBaruId;
    if (tahunAjaranId == null) return;

    state = state.copyWith(isLoadingRombelTujuan: true);
    try {
      final response = await ApiService.getRombel(tahunAjaranId: tahunAjaranId);
      final fetched = (response['data'] as List?) ?? [];
      state = MigrasiState(
        tahunAjaranLamaId: state.tahunAjaranLamaId,
        rombelAsalId: state.rombelAsalId,
        tahunAjaranBaruId: state.tahunAjaranBaruId,
        rombelTujuanId: selectRombelId ?? state.rombelTujuanId,
        siswaList: state.siswaList,
        tahunAjaranList: state.tahunAjaranList,
        rombelList: _replaceRombelByTahunAjaran(
          state.rombelList,
          tahunAjaranId,
          fetched,
        ),
        isLoadingData: state.isLoadingData,
        isLoadingRombelTujuan: false,
        isProcessing: state.isProcessing,
        isDone: state.isDone,
      );
    } catch (e) {
      state = state.copyWith(isLoadingRombelTujuan: false);
    }
  }

  // ── Step 4: Execute Migration ──
  Future<String?> executePromotion() async {
    state = state.copyWith(isProcessing: true);

    try {
      await ApiService.executePromosi({
        'rombelAsalId': state.rombelAsalId,
        'rombelTujuanId': state.rombelTujuanId,
        'tahunAjaranBaruId': state.tahunAjaranBaruId,
        'siswaIds': state.siswaNaik.map((s) => s.id).toList(),
      });

      state = state.copyWith(isProcessing: false, isDone: true);
      return null; // Success
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      if (e is DioException && e.response?.data != null) {
        return e.response!.data['message']?.toString() ??
            'Terjadi kesalahan saat mengeksekusi migrasi';
      }
      return 'Terjadi kesalahan saat mengeksekusi migrasi';
    }
  }

  /// Reset wizard to initial state
  void reset() {
    state = MigrasiState(
      tahunAjaranList: state.tahunAjaranList,
      rombelList: state.rombelList,
    );
  }
}

final migrasiProvider = StateNotifierProvider<MigrasiNotifier, MigrasiState>((
  ref,
) {
  return MigrasiNotifier();
});
