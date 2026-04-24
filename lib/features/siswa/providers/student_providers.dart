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
    return _fetch();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final response = await ApiService.getSiswaDashboard();
    return response['data'] ?? {};
  }

  Future<void> refresh() async {
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
  return dashboard.valueOrNull?['kelasId'] as String?;
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
