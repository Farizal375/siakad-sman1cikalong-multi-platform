// File: lib/core/network/api_service.dart
// ===========================================
// CENTRALIZED API SERVICE
// All backend API calls in one place
// ===========================================

import 'api_client.dart';

class ApiService {
  static final ApiClient _client = ApiClient();

  // ═══════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await _client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final response = await _client.get('/auth/me');
    return response.data;
  }

  // ═══════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _client.get('/dashboard/stats');
    return response.data;
  }

  static Future<Map<String, dynamic>> getCurriculumDashboard() async {
    final response = await _client.get('/dashboard/kurikulum');
    return response.data;
  }

  static Future<Map<String, dynamic>> getWaliKelasDashboard() async {
    final response = await _client.get('/dashboard/wali-kelas');
    return response.data;
  }

  static Future<Map<String, dynamic>> getSiswaDashboard() async {
    final response = await _client.get('/dashboard/siswa');
    return response.data;
  }

  static Future<Map<String, dynamic>> getGuruDashboard() async {
    final response = await _client.get('/dashboard/guru');
    return response.data;
  }

  static Future<Map<String, dynamic>> getGuruClassDetail(String id) async {
    final response = await _client.get('/dashboard/guru/kelas/$id');
    return response.data;
  }

  static Future<Map<String, dynamic>> quickSession(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      '/dashboard/guru/quick-session',
      data: data,
    );
    return response.data;
  }

  // ═══════════════════════════════════════════
  // USER MANAGEMENT
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 10,
    String search = '',
    String role = '',
  }) async {
    final response = await _client.get(
      '/users',
      queryParameters: {
        'page': page,
        'limit': limit,
        'search': search,
        'role': role,
      },
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getUserById(String id) async {
    final response = await _client.get('/users/$id');
    return response.data;
  }

  static Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/users', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/users/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteUser(String id) async {
    final response = await _client.delete('/users/$id');
    return response.data;
  }

  static Future<Map<String, dynamic>> resetPassword(
    String id,
    String password,
  ) async {
    final response = await _client.patch(
      '/users/$id/reset-password',
      data: {'password': password},
    );
    return response.data;
  }

  // ═══════════════════════════════════════════
  // PROFILE
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get('/profile');
    return response.data;
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/profile', data: data);
    return response.data;
  }

  // ═══════════════════════════════════════════
  // MASTER DATA
  // ═══════════════════════════════════════════

  // Tahun Ajaran
  static Future<Map<String, dynamic>> getTahunAjaran() async {
    final response = await _client.get('/master/tahun-ajaran');
    return response.data;
  }

  static Future<Map<String, dynamic>> createTahunAjaran(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/master/tahun-ajaran', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> updateTahunAjaran(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/master/tahun-ajaran/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> toggleTahunAjaran(String id) async {
    final response = await _client.patch('/master/tahun-ajaran/$id/toggle');
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteTahunAjaran(String id) async {
    final response = await _client.delete('/master/tahun-ajaran/$id');
    return response.data;
  }

  // Semester
  static Future<Map<String, dynamic>> getSemester() async {
    final response = await _client.get('/master/semester');
    return response.data;
  }

  static Future<Map<String, dynamic>> createSemester(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/master/semester', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> updateSemester(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/master/semester/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> toggleSemester(String id) async {
    final response = await _client.patch('/master/semester/$id/toggle');
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteSemester(String id) async {
    final response = await _client.delete('/master/semester/$id');
    return response.data;
  }

  // Ruang Kelas
  static Future<Map<String, dynamic>> getRuangKelas() async {
    final response = await _client.get('/master/ruang-kelas');
    return response.data;
  }

  static Future<Map<String, dynamic>> createRuangKelas(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/master/ruang-kelas', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> updateRuangKelas(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/master/ruang-kelas/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteRuangKelas(String id) async {
    final response = await _client.delete('/master/ruang-kelas/$id');
    return response.data;
  }

  // Master Kelas
  static Future<Map<String, dynamic>> getMasterKelas() async {
    final response = await _client.get('/master/master-kelas');
    return response.data;
  }

  static Future<Map<String, dynamic>> createMasterKelas(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/master/master-kelas', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> updateMasterKelas(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/master/master-kelas/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteMasterKelas(String id) async {
    final response = await _client.delete('/master/master-kelas/$id');
    return response.data;
  }

  // ═══════════════════════════════════════════
  // MATA PELAJARAN
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getMataPelajaran() async {
    final response = await _client.get('/mata-pelajaran');
    return response.data;
  }

  static Future<Map<String, dynamic>> createMataPelajaran(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/mata-pelajaran', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> updateMataPelajaran(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/mata-pelajaran/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteMataPelajaran(String id) async {
    final response = await _client.delete('/mata-pelajaran/$id');
    return response.data;
  }

  // ═══════════════════════════════════════════
  // GURU - MAPEL MAPPING
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getGuruMapel({String search = ''}) async {
    final response = await _client.get(
      '/guru-mapel',
      queryParameters: {'search': search},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> createGuruMapel(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/guru-mapel', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> updateGuruMapel(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/guru-mapel/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteGuruMapel(String id) async {
    final response = await _client.delete('/guru-mapel/$id');
    return response.data;
  }

  // ═══════════════════════════════════════════
  // ROMBEL
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getRombel() async {
    final response = await _client.get('/rombel');
    return response.data;
  }

  static Future<Map<String, dynamic>> createRombel(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/rombel', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> updateRombel(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/rombel/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteRombel(String id) async {
    final response = await _client.delete('/rombel/$id');
    return response.data;
  }

  static Future<Map<String, dynamic>> getRombelSiswa(String id) async {
    final response = await _client.get('/rombel/$id/siswa');
    return response.data;
  }

  static Future<Map<String, dynamic>> getAvailableWali({
    String? currentRombelId,
  }) async {
    final params = currentRombelId != null
        ? {'currentRombelId': currentRombelId}
        : null;
    final response = await _client.get(
      '/rombel/available-wali',
      queryParameters: params,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getAvailableSiswa(String id) async {
    final response = await _client.get('/rombel/$id/available-siswa');
    return response.data;
  }

  static Future<Map<String, dynamic>> assignSiswa(
    String id,
    List<String> siswaIds,
  ) async {
    final response = await _client.post(
      '/rombel/$id/siswa',
      data: {'siswaIds': siswaIds},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> removeSiswaFromRombel(
    String rombelId,
    String siswaId,
  ) async {
    final response = await _client.delete('/rombel/$rombelId/siswa/$siswaId');
    return response.data;
  }

  // ═══════════════════════════════════════════
  // KENAIKAN KELAS (PROMOSI)
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getSiswaPromosi(String rombelId) async {
    final response = await _client.get('/promosi/rombel/$rombelId');
    return response.data;
  }

  static Future<Map<String, dynamic>> lockPromosi(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/promosi/lock', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> executePromosi(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/promosi/execute', data: data);
    return response.data;
  }

  // ═══════════════════════════════════════════
  // JADWAL
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getJadwal({
    String? kelasId,
    String? hari,
  }) async {
    final params = <String, dynamic>{};
    if (kelasId != null) params['kelasId'] = kelasId;
    if (hari != null) params['hari'] = hari;
    final response = await _client.get('/jadwal', queryParameters: params);
    return response.data;
  }

  static Future<Map<String, dynamic>> getJadwalByGuru(String guruId) async {
    final response = await _client.get('/jadwal/by-guru/$guruId');
    return response.data;
  }

  static Future<Map<String, dynamic>> createJadwal(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/jadwal', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> updateJadwal(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/jadwal/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> moveJadwal(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.patch('/jadwal/$id/move', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteJadwal(String id) async {
    final response = await _client.delete('/jadwal/$id');
    return response.data;
  }

  // ═══════════════════════════════════════════
  // KEHADIRAN
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> saveKehadiran(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/kehadiran/batch', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> getRekapKehadiran(String jadwalId) async {
    final response = await _client.get('/kehadiran/rekap/$jadwalId');
    return response.data;
  }

  static Future<Map<String, dynamic>> getKehadiranSiswa(
    String siswaId, [
    String? semesterId,
  ]) async {
    final params = <String, dynamic>{};
    if (semesterId != null) params['semesterId'] = semesterId;
    final response = await _client.get(
      '/kehadiran/siswa/$siswaId',
      queryParameters: params,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getKehadiranHistory(
    String jadwalId,
  ) async {
    final response = await _client.get('/kehadiran/history/$jadwalId');
    return response.data;
  }

  static Future<Map<String, dynamic>> generateQR(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/kehadiran/generate-qr', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> scanQR(Map<String, dynamic> data) async {
    final response = await _client.post('/kehadiran/qr-scan', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> refreshQR(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/kehadiran/refresh-qr', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> endSession(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/kehadiran/end-session', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> saveBatchAttendance(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/kehadiran/batch', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> getLiveAttendance({
    required String jadwalId,
    required String tanggal,
  }) async {
    final response = await _client.get(
      '/kehadiran/live-attendance',
      queryParameters: {'jadwalId': jadwalId, 'tanggal': tanggal},
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getActiveSemester() async {
    final response = await _client.get('/dashboard/active-semester');
    return response.data;
  }

  // ═══════════════════════════════════════════
  // NILAI
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getNilai({
    String? mapelId,
    String? semesterId,
    String? kelasId,
  }) async {
    final params = <String, dynamic>{};
    if (mapelId != null) params['mapelId'] = mapelId;
    if (semesterId != null) params['semesterId'] = semesterId;
    if (kelasId != null) params['kelasId'] = kelasId;
    final response = await _client.get('/nilai', queryParameters: params);
    return response.data;
  }

  static Future<Map<String, dynamic>> getNilaiSiswa(
    String siswaId, {
    String? semesterId,
  }) async {
    final params = <String, dynamic>{};
    if (semesterId != null) params['semesterId'] = semesterId;
    final response = await _client.get(
      '/nilai/siswa/$siswaId',
      queryParameters: params,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> saveNilaiBatch(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/nilai/batch', data: data);
    return response.data;
  }

  // ═══════════════════════════════════════════
  // JURNAL MENGAJAR
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> createJurnal(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/jurnal', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> getJurnalByJadwal(String jadwalId) async {
    final response = await _client.get('/jurnal/$jadwalId');
    return response.data;
  }

  static Future<Map<String, dynamic>> checkJurnal(
    String jadwalId,
    String tanggal,
  ) async {
    final response = await _client.get('/jurnal/check/$jadwalId/$tanggal');
    return response.data;
  }

  static Future<Map<String, dynamic>> updateJurnal(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/jurnal/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteJurnal(String id) async {
    final response = await _client.delete('/jurnal/$id');
    return response.data;
  }

  // ═══════════════════════════════════════════
  // CATATAN AKADEMIK
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> upsertCatatanAkademik(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/catatan-akademik', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> getCatatanSiswa(
    String siswaId, {
    String? semesterId,
  }) async {
    final params = <String, dynamic>{};
    if (semesterId != null) params['semesterId'] = semesterId;
    final response = await _client.get(
      '/catatan-akademik/siswa/$siswaId',
      queryParameters: params,
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> getCatatanKelas(
    String kelasId,
    String semesterId,
  ) async {
    final response = await _client.get(
      '/catatan-akademik/kelas/$kelasId',
      queryParameters: {'semesterId': semesterId},
    );
    return response.data;
  }

  // ═══════════════════════════════════════════
  // E-RAPOR
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> previewRapor(
    String siswaId,
    String semesterId,
  ) async {
    final response = await _client.get('/rapor/preview/$siswaId/$semesterId');
    return response.data;
  }

  /// Returns the URL for downloading the PDF rapor
  static String getRaporPdfUrl(String siswaId, String semesterId) {
    return 'http://localhost:3001/api/rapor/$siswaId/$semesterId';
  }

  static Future<List<int>> downloadRaporPdf(
    String siswaId,
    String semesterId,
  ) async {
    final response = await _client.downloadBytes('/rapor/$siswaId/$semesterId');
    return response.data ?? <int>[];
  }

  static Future<List<int>> downloadTranskripPdf(String siswaId) async {
    final response = await _client.downloadBytes('/rapor/transkrip/$siswaId');
    return response.data ?? <int>[];
  }

  // ═══════════════════════════════════════════
  // CMS / KONTEN PUBLIK
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> getPublicContent({String? tipe}) async {
    final params = <String, dynamic>{};
    if (tipe != null) params['tipe'] = tipe;
    final response = await _client.get('/cms', queryParameters: params);
    return response.data;
  }

  static Future<Map<String, dynamic>> getAllContent({String? tipe}) async {
    final params = <String, dynamic>{};
    if (tipe != null) params['tipe'] = tipe;
    final response = await _client.get('/cms/all', queryParameters: params);
    return response.data;
  }

  static Future<Map<String, dynamic>> createContent(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/cms', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> updateContent(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/cms/$id', data: data);
    return response.data;
  }

  static Future<Map<String, dynamic>> toggleContent(String id) async {
    final response = await _client.patch('/cms/$id/toggle');
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteContent(String id) async {
    final response = await _client.delete('/cms/$id');
    return response.data;
  }

  // ═══════════════════════════════════════════
  // UPLOAD
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final response = await _client.uploadFile(
      '/upload/avatar',
      filePath: filePath,
      fieldName: 'avatar',
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> deleteAvatar() async {
    final response = await _client.delete('/upload/avatar');
    return response.data;
  }

  // ═══════════════════════════════════════════
  // IMPORT
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> importUsers(String filePath) async {
    final response = await _client.uploadFile(
      '/import/users',
      filePath: filePath,
      fieldName: 'file',
    );
    return response.data;
  }

  static Future<Map<String, dynamic>> importUsersFile(
    List<int> bytes,
    String filename,
  ) async {
    final response = await _client.uploadBytes(
      '/import/users',
      bytes: bytes,
      filename: filename,
      fieldName: 'file',
    );
    return response.data;
  }

  static Future<List<int>> exportUsers({String format = 'csv'}) async {
    final response = await _client.downloadBytes(
      '/import/users/export',
      queryParameters: {'format': format},
    );
    return response.data ?? <int>[];
  }
}
