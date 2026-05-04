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
  Future<bool> validasiDanKunci() async {
    if (_currentRombelId == null) return false;
    if (state.siswaList.any((s) => s.status == StatusKenaikan.perluCek)) {
      return false;
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
      return true;
    } catch (e) {
      return false;
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

  // ── Step 1: Set Source ──
  void setTahunAjaranLama(String id) {
    state = MigrasiState(
      tahunAjaranLamaId: id,
      rombelAsalId: null, // explicitly clear
      tahunAjaranBaruId: state.tahunAjaranBaruId,
      rombelTujuanId: state.rombelTujuanId,
      siswaList: [], // explicitly clear
      tahunAjaranList: state.tahunAjaranList,
      rombelList: state.rombelList,
      isLoadingData: state.isLoadingData,
      isProcessing: state.isProcessing,
      isDone: state.isDone,
    );
  }

  Future<void> setRombelAsal(String id) async {
    state = state.copyWith(rombelAsalId: id, isLoadingData: true);
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
  void setTahunAjaranBaru(String id) {
    state = MigrasiState(
      tahunAjaranLamaId: state.tahunAjaranLamaId,
      rombelAsalId: state.rombelAsalId,
      tahunAjaranBaruId: id,
      rombelTujuanId: null, // explicitly clear
      siswaList: state.siswaList,
      tahunAjaranList: state.tahunAjaranList,
      rombelList: state.rombelList,
      isLoadingData: state.isLoadingData,
      isProcessing: state.isProcessing,
      isDone: state.isDone,
    );
  }

  void setRombelTujuan(String id) {
    state = state.copyWith(rombelTujuanId: id);
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
