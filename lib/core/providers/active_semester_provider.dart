import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_service.dart';

final activeSemesterProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final response = await ApiService.getActiveSemester();
  final data = response['data'];
  return data is Map ? Map<String, dynamic>.from(data) : null;
});

final activeSemesterLabelProvider = Provider<AsyncValue<String>>((ref) {
  final semester = ref.watch(activeSemesterProvider);

  return semester.whenData((data) {
    if (data == null) return 'Tidak ada semester aktif';
    final label = data['label']?.toString().trim();
    return label == null || label.isEmpty ? 'Aktif: -' : 'Aktif: $label';
  });
});
