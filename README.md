# 🎓 Temu Guru — English Tutoring App

> **"Temukan Guru Terbaik, Belajar di Tempat Pilihanmu."**

Aplikasi mobile Android berbasis Flutter dengan konsep bimbingan les privat bahasa Inggris (seperti Ruangguru), dilengkapi alur registrasi terpisah untuk Siswa dan Guru, verifikasi kualifikasi guru oleh Admin, serta sistem Laporan Harian Belajar (*Daily Lesson Report*).

---

## 🌟 Fitur Utama (Tahap 1 - 6 Selesai)

1. **Autentikasi & Navigasi Berbasis Role (Role-Based Route Guards):**
   - **Siswa (Student):** Mengakses Student Dashboard, ringkasan belajar, dan riwayat laporan les privat.
   - **Guru (Teacher - Approved):** Mengakses Teacher Dashboard, metrik mengajar, buat laporan harian baru, dan riwayat lengkap.
   - **Guru (Teacher - Pending / Rejected):** Masuk ke halaman *Application Status* untuk memantau proses verifikasi dan alasan penolakan (bila ada).
   - **Admin:** Panel verifikasi guru dengan filter tab (Semua, Menunggu, Disetujui, Ditolak), pencarian instan (Nama/NIK/Email), tinjau dokumen PDF, serta modal persetujuan/penolakan dengan catatan resmi.
   - **Quick Demo Chips:** Tersedia 4 akun pengujian instan di layar Login (Admin, Guru Approved, Guru Pending, Siswa).

2. **Registrasi Siswa (12 Field):**
   - Perhitungan usia otomatis real-time dari tanggal lahir.
   - Pilihan preferensi area les, riwayat les sebelumnya, program/level yang diminati, serta persetujuan privasi.

3. **Registrasi Guru (15 Field & Standar CEFR):**
   - Validasi ketat NIK 16 digit numerik.
   - Batas usia guru 18 – 35 tahun (dihitung otomatis).
   - Standar kompetensi bahasa Inggris minimal CEFR B2 (B2 Upper-Intermediate, C1 Advanced, C2 Proficient).
   - Pemilih dokumen bukti tes/sertifikat PDF dengan validasi ukuran ≤ 5 MB.
   - Multi-select chips untuk area mengajar yang dilayani.
   - Status otomatis berstatus `pending` saat pendaftaran awal.

4. **Daily Lesson Report (Laporan Pembelajaran Harian):**
   - Form pembuatan laporan 8 field: Siswa, Tanggal, Jam Mulai, Jam Selesai, Pertemuan Ke-, Materi, Catatan Sesi, Evaluasi/Tugas.
   - Validasi jam selesai harus lebih besar dari jam mulai.
   - Dialog konfirmasi ringkasan dan pencegahan double-submit.
   - Riwayat laporan dengan filter tanggal (Semua, Hari Ini, 7 Hari Terakhir, 30 Hari Terakhir) dan fitur pencarian.
   - Halaman detail laporan dengan opsi Edit dan Salin/Kirim ke WhatsApp.

5. **Keamanan & Storage 100% Free-Tier (Spark Plan):**
   - Menggunakan `StorageService` cerdas: otomatis menggunakan Firebase Storage jika tersedia, dan beralih ke *Local/In-Memory Storage Fallback* bebas biaya tanpa perlu kartu kredit (*Credit Card Free*).
   - Cloud Firestore Security Rules menjaga privasi data NIK guru, profil siswa, dan laporan pertemuan.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** Flutter (Channel stable) & Dart
- **Design System:** Material 3 (Theme warna: Biru Royal, Cyan aksen, Putih, Slate Grey)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`) dengan redirect guard role-based
- **Backend & Database:** Firebase Authentication & Cloud Firestore
- **Date Formatting:** `intl` dengan perlindungan `AppDateFormatter` (lokal Bahasa Indonesia)
- **Arsitektur:** Feature-First Architecture:
  ```text
  lib/
  ├── app/                  # Theme, Router, Root App Widget
  ├── core/                 # Constants, Utils, Validators, Widgets, Services
  └── features/
      ├── auth/             # Login, Splash, Welcome, Auth Notifier, AppUser
      ├── student/          # Student Registration, Student Dashboard
      ├── teacher/          # Teacher Registration, Teacher Dashboard
      ├── teacher_verification/ # Admin Verification, Application Status
      └── daily_report/     # Lesson Report Form, History, Detail, Repository
  ```

---

## 🚀 Panduan Menjalankan Aplikasi

### 1. Prasyarat
- Flutter SDK (versi 3.24.x atau lebih baru)
- Android SDK (Platform 34 / Android 14) atau Google Chrome untuk pengujian Web
- Java JDK 17 atau 21

### 2. Instalasi Dependensi
Jalankan di terminal proyek:
```bash
flutter pub get
```

### 3. Menjalankan di Android Emulator / Perangkat Fisik
Pastikan emulator Android sudah berjalan atau ponsel Android terhubung via USB Debugging:
```bash
flutter run
```

### 4. Menjalankan di Web Browser (Chrome)
```bash
flutter run -d chrome
```

---

## 🧪 Pengujian & Analisis Kode

### Menjalankan Seluruh Unit & Widget Tests:
```bash
flutter test
```
*Hasil: Seluruh 23 unit & widget tests lulus (100% Passed).*

### Menjalankan Analisis Statis:
```bash
flutter analyze
```
*Hasil: 0 issues found.*

---

## 📦 Membangun File APK Android

Untuk membuat APK Android versi pengujian (Debug APK):
```bash
flutter build apk --debug
```
File APK yang dihasilkan akan berada di:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 🛡️ Akun Demo untuk Pengujian Cepat

Pada halaman **Login**, klik salah satu chip uji cepat di bagian bawah:
| Role | Email | Password | Status | Halaman Dituju |
|---|---|---|---|---|
| **Admin** | `admin@temuguru.id` | `admin123` | Active | `/admin/dashboard` |
| **Guru (Approved)** | `sarah.jenkins@temuguru.id` | `teacher123` | Approved | `/teacher/dashboard` |
| **Guru (Pending)** | `budi.santoso@temuguru.id` | `teacher123` | Pending | `/teacher/status` |
| **Siswa** | `faiz.pratama@temuguru.id` | `student123` | Active | `/student/dashboard` |

---

## 📄 Lisensi
Hak Cipta © 2026 Temu Guru. Seluruh hak cipta dilindungi undang-undang.
