import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_service.dart';
import '../../../core/providers/active_semester_provider.dart';
import '../../../core/providers/auth_provider.dart';

class HomeroomSemester {
  final String id;
  final String nama;
  final String tahunAjaran;
  final String label;

  const HomeroomSemester({
    required this.id,
    required this.nama,
    required this.tahunAjaran,
    required this.label,
  });

  factory HomeroomSemester.fromJson(Map<String, dynamic> json) {
    final nama = json['nama']?.toString() ?? '';
    final tahunAjaran = json['tahunAjaran']?.toString() ?? '-';
    return HomeroomSemester(
      id: json['id']?.toString() ?? '',
      nama: nama,
      tahunAjaran: tahunAjaran,
      label:
          json['label']?.toString() ??
          (nama.isEmpty ? tahunAjaran : '$nama - $tahunAjaran'),
    );
  }
}

class HomeroomContext {
  final bool hasClass;
  final String? rombelId;
  final String? masterKelasId;
  final String kelas;
  final String tahunAjaran;
  final HomeroomSemester? semesterAktif;
  final List<Map<String, dynamic>> students;
  final Map<String, dynamic> attendanceStats;
  final List<Map<String, dynamic>> flaggedStudents;

  const HomeroomContext({
    required this.hasClass,
    this.rombelId,
    this.masterKelasId,
    this.kelas = '-',
    this.tahunAjaran = '-',
    this.semesterAktif,
    this.students = const [],
    this.attendanceStats = const {},
    this.flaggedStudents = const [],
  });

  factory HomeroomContext.fromJson(
    Map<String, dynamic> data, {
    Map<String, dynamic>? activeSemester,
  }) {
    final students = (data['students'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final flaggedStudents = (data['flaggedStudents'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final semesterMap = data['semesterAktif'] is Map
        ? Map<String, dynamic>.from(data['semesterAktif'] as Map)
        : activeSemester;

    return HomeroomContext(
      hasClass: data['hasClass'] == true,
      rombelId: data['rombelId']?.toString(),
      masterKelasId: data['masterKelasId']?.toString(),
      kelas: data['kelas']?.toString() ?? '-',
      tahunAjaran: data['tahunAjaran']?.toString() ?? '-',
      semesterAktif: semesterMap == null
          ? null
          : HomeroomSemester.fromJson(semesterMap),
      students: students,
      attendanceStats: data['attendanceStats'] is Map
          ? Map<String, dynamic>.from(data['attendanceStats'] as Map)
          : const {},
      flaggedStudents: flaggedStudents,
    );
  }
}

final homeroomContextProvider = FutureProvider<HomeroomContext>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return const HomeroomContext(hasClass: false);

  final dashboardResponse = await ApiService.getWaliKelasDashboard();
  final activeSemester = await ref
      .watch(activeSemesterProvider.future)
      .catchError((_) => null);

  final data = dashboardResponse['data'] is Map
      ? Map<String, dynamic>.from(dashboardResponse['data'] as Map)
      : <String, dynamic>{'hasClass': false};
  return HomeroomContext.fromJson(data, activeSemester: activeSemester);
});

class HomeroomRouteGuard extends ConsumerWidget {
  final Widget child;

  const HomeroomRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeroom = ref.watch(homeroomContextProvider);

    return homeroom.when(
      data: (data) {
        if (!data.hasClass) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/guru/dashboard');
          });
          return const SizedBox.shrink();
        }
        return child;
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/guru/dashboard');
        });
        return const SizedBox.shrink();
      },
    );
  }
}
