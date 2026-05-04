import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_app/features/kurikulum/controllers/migrasi_controller.dart';

void main() {
  group('SiswaPromosi status parsing', () {
    test('parses perluCek and missingData from backend', () {
      final siswa = SiswaPromosi.fromJson({
        'id': 'siswa-001',
        'nama': 'Aulia',
        'nisn': '001',
        'nilaiRataRata': 0,
        'persentaseKehadiran': 0,
        'status': 'perluCek',
        'isDataComplete': false,
        'missingData': ['nilai', 'kehadiran'],
      });

      expect(siswa.status, StatusKenaikan.perluCek);
      expect(siswa.isDataComplete, isFalse);
      expect(siswa.missingData, ['nilai', 'kehadiran']);
    });
  });
}
