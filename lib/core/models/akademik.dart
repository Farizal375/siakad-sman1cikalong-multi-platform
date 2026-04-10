// File: lib/core/models/akademik.dart
// ===========================================
// ACADEMIC MODELS
// Translated from src/types/akademik.d.ts
// ===========================================

class TahunAjaran {
  final String id;
  final String code; // e.g., "2026/2027"
  final String description;
  final bool isActive;

  const TahunAjaran({
    required this.id,
    required this.code,
    required this.description,
    required this.isActive,
  });

  factory TahunAjaran.fromJson(Map<String, dynamic> json) => TahunAjaran(
        id: json['id'] as String,
        code: json['code'] as String,
        description: json['description'] as String,
        isActive: json['isActive'] as bool,
      );
}

class Semester {
  final String id;
  final String name; // "Ganjil" or "Genap"
  final String academicYear;
  final bool isActive;

  const Semester({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.isActive,
  });

  factory Semester.fromJson(Map<String, dynamic> json) => Semester(
        id: json['id'] as String,
        name: json['name'] as String,
        academicYear: json['academicYear'] as String,
        isActive: json['isActive'] as bool,
      );
}

class RuangKelas {
  final String id;
  final String code; // e.g., "R-101"
  final String building;
  final int capacity;

  const RuangKelas({
    required this.id,
    required this.code,
    required this.building,
    required this.capacity,
  });

  factory RuangKelas.fromJson(Map<String, dynamic> json) => RuangKelas(
        id: json['id'] as String,
        code: json['code'] as String,
        building: json['building'] as String,
        capacity: json['capacity'] as int,
      );
}

class MasterKelas {
  final String id;
  final String name; // e.g., "XII-1"
  final String grade; // e.g., "Kelas 12"
  final String homeroomTeacher;
  final String classroom;

  const MasterKelas({
    required this.id,
    required this.name,
    required this.grade,
    required this.homeroomTeacher,
    required this.classroom,
  });

  factory MasterKelas.fromJson(Map<String, dynamic> json) => MasterKelas(
        id: json['id'] as String,
        name: json['name'] as String,
        grade: json['grade'] as String,
        homeroomTeacher: json['homeroomTeacher'] as String,
        classroom: json['classroom'] as String,
      );
}

class MataPelajaran {
  final String id;
  final String code;
  final String name;
  final String category; // "Muatan Nasional" | "Muatan Lokal" | "Peminatan"
  final int kkm;
  final String? description;

  const MataPelajaran({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.kkm,
    this.description,
  });

  factory MataPelajaran.fromJson(Map<String, dynamic> json) => MataPelajaran(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        kkm: json['kkm'] as int,
        description: json['description'] as String?,
      );
}

class JadwalPelajaran {
  final String id;
  final String day;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;
  final String classId;

  const JadwalPelajaran({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
    required this.classId,
  });

  factory JadwalPelajaran.fromJson(Map<String, dynamic> json) =>
      JadwalPelajaran(
        id: json['id'] as String,
        day: json['day'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        subject: json['subject'] as String,
        teacher: json['teacher'] as String,
        classId: json['classId'] as String,
      );
}

class Kehadiran {
  final String id;
  final String siswaId;
  final String jadwalId;
  final String tanggal;
  final String status; // "HADIR" | "SAKIT" | "IZIN" | "ALPA"
  final String? keterangan;

  const Kehadiran({
    required this.id,
    required this.siswaId,
    required this.jadwalId,
    required this.tanggal,
    required this.status,
    this.keterangan,
  });

  factory Kehadiran.fromJson(Map<String, dynamic> json) => Kehadiran(
        id: json['id'] as String,
        siswaId: json['siswaId'] as String,
        jadwalId: json['jadwalId'] as String,
        tanggal: json['tanggal'] as String,
        status: json['status'] as String,
        keterangan: json['keterangan'] as String?,
      );
}

class Nilai {
  final String id;
  final String siswaId;
  final String mataPelajaranId;
  final String semesterId;
  final double nilaiTugas;
  final double nilaiUTS;
  final double nilaiUAS;
  final double nilaiAkhir;
  final String predikat;

  const Nilai({
    required this.id,
    required this.siswaId,
    required this.mataPelajaranId,
    required this.semesterId,
    required this.nilaiTugas,
    required this.nilaiUTS,
    required this.nilaiUAS,
    required this.nilaiAkhir,
    required this.predikat,
  });

  factory Nilai.fromJson(Map<String, dynamic> json) => Nilai(
        id: json['id'] as String,
        siswaId: json['siswaId'] as String,
        mataPelajaranId: json['mataPelajaranId'] as String,
        semesterId: json['semesterId'] as String,
        nilaiTugas: (json['nilaiTugas'] as num).toDouble(),
        nilaiUTS: (json['nilaiUTS'] as num).toDouble(),
        nilaiUAS: (json['nilaiUAS'] as num).toDouble(),
        nilaiAkhir: (json['nilaiAkhir'] as num).toDouble(),
        predikat: json['predikat'] as String,
      );
}

class Rombel {
  final String id;
  final String masterKelasId;
  final String tahunAjaranId;
  final String waliKelasId;
  final List<String> siswaIds;

  const Rombel({
    required this.id,
    required this.masterKelasId,
    required this.tahunAjaranId,
    required this.waliKelasId,
    required this.siswaIds,
  });

  factory Rombel.fromJson(Map<String, dynamic> json) => Rombel(
        id: json['id'] as String,
        masterKelasId: json['masterKelasId'] as String,
        tahunAjaranId: json['tahunAjaranId'] as String,
        waliKelasId: json['waliKelasId'] as String,
        siswaIds: List<String>.from(json['siswaIds'] as List),
      );
}
