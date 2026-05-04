# Frontend SIAKAD SMAN 1 Cikalong 🎓

Selamat datang di repositori Frontend **SIAKAD SMAN 1 Cikalong**. Proyek ini adalah aplikasi *multi-platform* (Web dan Android/iOS) yang dibangun dengan menggunakan **Flutter** untuk memfasilitasi interaksi pengguna dengan Sistem Informasi Akademik.

Aplikasi ini melayani seluruh kebutuhan civitas akademika SMAN 1 Cikalong dengan portal yang disesuaikan berdasarkan peran (*role-based access*), meliputi Administrator, Staff Kurikulum, Guru (Wali Kelas & Guru Mapel), Siswa, serta portal Tamu (*Guest*).

---

## 🚀 Fitur Utama Berdasarkan Peran

### 1. Tamu / Guest (Portal Publik)
- **Halaman Beranda:** Menampilkan CMS interaktif (Berita, Pengumuman, Daftar Prestasi, dan Profil Video Sekolah).

### 2. Administrator
- **Dashboard:** Ringkasan statistik pengguna dan aktivitas sekolah.
- **Manajemen Pengguna:** Penambahan dan pengaturan akun guru, siswa, dan staff kurikulum.
- **CMS Publik:** Pengaturan dan pengelolaan konten dinamis yang muncul di halaman beranda.

### 3. Staff Kurikulum
- **Master Data Akademik:** Mengelola data Tahun Ajaran, Semester, Mata Pelajaran, dan penetapan Guru Mapel.
- **Manajemen Kelas:** Pengaturan Rombongan Belajar (Rombel), pemetaan siswa, dan pembagian Jadwal Pelajaran.
- **Migrasi Kelas:** Sistem *wizard* untuk menaikkan atau mengubah kelas siswa di awal tahun ajaran baru.

### 4. Guru & Wali Kelas
- **Dashboard Mengajar:** Akses cepat ke jadwal harian dan jurnal kelas.
- **Jurnal & Kehadiran:** Pemindaian QR Code (untuk absensi siswa instan) dan pencatatan materi yang diajarkan (Jurnal).
- **Penilaian:** Memasukkan nilai tugas, ulangan harian, UTS, dan UAS.
- **Wali Kelas:** Mencetak *E-Rapor*, menambahkan Catatan Akademik siswa, dan melakukan monitoring riwayat absensi.

### 5. Siswa
- **Dashboard Siswa:** Jadwal harian personal dan statistik tingkat kehadiran.
- **QR Scanner Presensi:** Fitur pemindai kode QR kelas untuk merekam absensi secara otomatis.
- **Riwayat Akademik:** Melihat nilai ujian, laporan rapor semester, dan rekapitulasi absensi.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [Riverpod](https://riverpod.dev/) (Reactive caching and data binding)
- **Routing:** [GoRouter](https://pub.dev/packages/go_router) (Declarative URL-based navigation)
- **Networking:** [Dio](https://pub.dev/packages/dio) (Advanced HTTP Client with Interceptors)
- **Storage:** `shared_preferences` (Token & session caching)
- **UI Components:** Material 3 Design, Google Fonts, Lucide Icons, FL Chart (Grafik)
- **Feature Add-ons:** Mobile Scanner (QR), Flutter Quill (Rich Text Editor CMS), Printing (E-Rapor PDF rendering)

Arsitektur menggunakan pola **Feature-First (Domain-Driven)** di mana logika dipisah secara modular berdasarkan fitur (`features/admin`, `features/siswa`, dll).

---

## ⚙️ Persiapan & Instalasi (Getting Started)

### Prasyarat (Prerequisites)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) versi terbaru (3.x)
- Akses ke Backend `BE-SIAKAD` yang sedang berjalan (lokal atau cloud).

### 1. Kloning Repositori
```bash
git clone https://github.com/Farizal375/siakad-sman1cikalong-multi-platform.git
cd siakad-sman1cikalong-multi-platform
```

### 2. Unduh Dependensi
```bash
flutter pub get
```

### 3. Konfigurasi Lingkungan (API URL)
Aplikasi ini berkomunikasi dengan backend melalui URL yang diatur di `lib/core/network/api_client.dart`.
Secara *default*, aplikasi dikonfigurasi untuk Web (`localhost:3001`). Jika Anda menjalankan aplikasi di emulator Android, pastikan backend Anda dapat diakses (biasanya `10.0.2.2:3001` atau menggunakan IP lokal PC Anda).

Anda dapat menyisipkan `API_BASE_URL` saat kompilasi:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3001/api
```

### 4. Menjalankan Aplikasi
Untuk Platform Web:
```bash
flutter run -d chrome
```
Untuk Perangkat Mobile (Android/iOS) atau Emulator:
```bash
flutter run
```

---

## 📁 Struktur Direktori

```text
siakad-sman1cikalong-multi-platform/
├── assets/                 # Gambar logo, favicon, dan ilustrasi default
├── lib/
│   ├── core/               # Konfigurasi inti (Theme, Network API, Models, Auth Provider global)
│   ├── features/           # Pembagian UI dan State per fitur/role (admin, auth, guest, guru, kurikulum, siswa)
│   ├── shared_widgets/     # Komponen UI modular yang dapat digunakan ulang (Re-usable buttons, dialogs, dll)
│   ├── main_web.dart       # Entry point utama (Routing utama web & mobile)
│   └── main_mobile_siswa.dart # (Opsional) Entry point khusus untuk build aplikasi standalone siswa
├── test/                   # File skrip testing unit/widget
├── pubspec.yaml            # Deklarasi dependencies Flutter
└── README.md
```

---

## 📝 Konvensi Kode (Clean Code)
Kami secara aktif melakukan refactoring menuju struktur yang lebih bersih:
1. Menghindari "Fat Widgets": Memecah layar besar menjadi modul komponen UI (Widgets) kecil.
2. Pemisahan Logika: Menjaga *business logic* di file `providers` (Riverpod) dan menjauhkannya dari `build()` di komponen UI.
