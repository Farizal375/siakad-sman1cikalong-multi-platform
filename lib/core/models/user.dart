// File: lib/core/models/user.dart
// ===========================================
// USER & PROFILE MODELS
// Translated from src/types/user.d.ts
// ===========================================

enum UserRole {
  admin,
  curriculum,
  teacher,
  student;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.curriculum:
        return 'Kurikulum';
      case UserRole.teacher:
        return 'Guru';
      case UserRole.student:
        return 'Siswa';
    }
  }
}

class User {
  final String id;
  final String email;
  final String password;
  final String name;
  final UserRole role;
  final String? avatar;

  const User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      password: json['password'] as String? ?? '',
      name: json['name'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.student,
      ),
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'name': name,
        'role': role.name,
        'avatar': avatar,
      };
}

class UserProfile {
  final String id;
  final String userId;
  final String nomorInduk; // NIP for teachers, NISN for students
  final String namaLengkap;
  final String jenisKelamin; // "L" or "P"
  final String tanggalLahir;
  final String tempatLahir;
  final String agama;
  final String? nik;
  final String? namaIbuKandung;
  final String? statusPerkawinan;

  // Address
  final String provinsi;
  final String kotaKabupaten;
  final String kecamatan;
  final String kelurahan;
  final String detailAlamat;
  final String? rt;
  final String? rw;
  final String? kodePos;

  // Avatar
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.nomorInduk,
    required this.namaLengkap,
    required this.jenisKelamin,
    required this.tanggalLahir,
    required this.tempatLahir,
    required this.agama,
    this.nik,
    this.namaIbuKandung,
    this.statusPerkawinan,
    required this.provinsi,
    required this.kotaKabupaten,
    required this.kecamatan,
    required this.kelurahan,
    required this.detailAlamat,
    this.rt,
    this.rw,
    this.kodePos,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      nomorInduk: json['nomorInduk'] as String,
      namaLengkap: json['namaLengkap'] as String,
      jenisKelamin: json['jenisKelamin'] as String,
      tanggalLahir: json['tanggalLahir'] as String,
      tempatLahir: json['tempatLahir'] as String,
      agama: json['agama'] as String,
      nik: json['nik'] as String?,
      namaIbuKandung: json['namaIbuKandung'] as String?,
      statusPerkawinan: json['statusPerkawinan'] as String?,
      provinsi: json['provinsi'] as String,
      kotaKabupaten: json['kotaKabupaten'] as String,
      kecamatan: json['kecamatan'] as String,
      kelurahan: json['kelurahan'] as String,
      detailAlamat: json['detailAlamat'] as String,
      rt: json['rt'] as String?,
      rw: json['rw'] as String?,
      kodePos: json['kodePos'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'nomorInduk': nomorInduk,
        'namaLengkap': namaLengkap,
        'jenisKelamin': jenisKelamin,
        'tanggalLahir': tanggalLahir,
        'tempatLahir': tempatLahir,
        'agama': agama,
        'nik': nik,
        'namaIbuKandung': namaIbuKandung,
        'statusPerkawinan': statusPerkawinan,
        'provinsi': provinsi,
        'kotaKabupaten': kotaKabupaten,
        'kecamatan': kecamatan,
        'kelurahan': kelurahan,
        'detailAlamat': detailAlamat,
        'rt': rt,
        'rw': rw,
        'kodePos': kodePos,
        'avatarUrl': avatarUrl,
      };
}
