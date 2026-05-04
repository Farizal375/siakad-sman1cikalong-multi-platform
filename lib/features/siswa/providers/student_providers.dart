// File: lib/features/siswa/providers/student_providers.dart
// ===========================================
// STUDENT STATE PROVIDERS (Riverpod)
// Shared state for mobile siswa screens
// ===========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';
import '../../../core/providers/auth_provider.dart';

/// Cached dashboard data for the student
class StudentDashboardNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return {};

    return _fetch();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final response = await ApiService.getSiswaDashboard();
    final data = Map<String, dynamic>.from(response['data'] ?? {});
    final kelasId = data['kelasId'] as String?;
    if (kelasId == null || kelasId.trim().isEmpty) {
      data['kelasId'] = null;
    }
    return data;
  }

  Future<void> refresh() async {
    if (ref.read(currentUserIdProvider) == null) {
      state = const AsyncValue.data({});
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }
}

final studentDashboardProvider =
    AsyncNotifierProvider<StudentDashboardNotifier, Map<String, dynamic>>(
      () => StudentDashboardNotifier(),
    );

/// Derived provider: student's master_kelas_id (for schedule page)
final studentClassIdProvider = Provider<String?>((ref) {
  final dashboard = ref.watch(studentDashboardProvider);
  final kelasId = dashboard.valueOrNull?['kelasId'] as String?;
  return kelasId == null || kelasId.trim().isEmpty ? null : kelasId;
});

/// Derived provider: student's class name
final studentClassNameProvider = Provider<String>((ref) {
  final dashboard = ref.watch(studentDashboardProvider);
  return (dashboard.valueOrNull?['kelas'] as String?) ?? '-';
});

/// Derived provider: student's display name
final studentNameProvider = Provider<String>((ref) {
  final user = ref.watch(authProvider).valueOrNull;
  return user?.name ?? 'Siswa';
});

/// Derived provider: student avatar initials
final studentInitialsProvider = Provider<String>((ref) {
  final name = ref.watch(studentNameProvider);
  final parts = name.split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts.isNotEmpty && parts[0].isNotEmpty
      ? parts[0][0].toUpperCase()
      : '?';
});
