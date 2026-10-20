# FEATURE ADDITION — BAHAN AJAR DAN ULASAN SISWA

Implementasikan dua fitur baru pada aplikasi Flutter Temu Guru tanpa merusak fitur yang sudah ada.

## A. Bahan Ajar Guru

- Gunakan Google Drive sebagai lokasi penyimpanan petunjuk ajar dan materi presentasi guru.
- Jangan memasukkan seluruh file bahan ajar ke dalam aset APK.
- Buat menu Bahan Ajar pada Teacher Dashboard.
- Tampilkan materi berdasarkan level dan nomor pertemuan.
- Setiap pertemuan dapat memiliki tautan Petunjuk Ajar dan Materi Presentasi.
- Simpan metadata materi dan tautan di database agar admin dapat memperbarui materi tanpa merilis ulang aplikasi.
- Sediakan loading, error state, dan tombol buka tautan.
- Buka tautan menggunakan browser atau aplikasi yang sesuai.
- Jangan menganggap materi dapat diakses sebelum izin Google Drive diuji.
- Jangan menyimpan kredensial Google atau secret key di source code Flutter.

Struktur metadata:
- materialId
- title
- level
- meetingNumber
- materialType
- externalUrl
- updatedAt
- isPublished

## B. Modul Belajar Siswa

- Buat menu Modul Belajar pada Student Dashboard.
- Untuk tahap pertama, tampilkan Buku Saku Grammar dalam format PDF.
- Simpan PDF di cloud storage, bukan sebagai aset APK.
- Tampilkan PDF melalui viewer di dalam aplikasi.
- Tampilkan judul, deskripsi, versi, dan tanggal pembaruan.
- Sediakan loading, error handling, dan opsi coba lagi.
- Fitur unduh untuk akses offline bersifat opsional.
- Terapkan pemeriksaan hak akses dan aturan penyimpanan file.
- Rancang struktur agar modul mata pelajaran lain dapat ditambahkan nantinya.

## C. Ulasan Siswa

Buat halaman Ulasan Setelah Les yang hanya dapat diakses setelah sesi les selesai.

Field:
- Nama siswa: otomatis dari akun login dan tidak dapat diedit.
- Guru yang dinilai: diambil dari sesi les terkait.
- Rating: 1 sampai 5 bintang, wajib.
- Kesan: wajib.
- Pesan dan harapan: opsional.
- Waktu ulasan: server timestamp.

Validasi:
- Satu ulasan per siswa per sesi les.
- Sesi harus benar-benar terkait dengan siswa dan guru yang bersangkutan.
- Sesi harus berstatus selesai.
- Identitas pengguna dan relasi sesi divalidasi di backend.
- Batasi panjang teks untuk mencegah input berlebihan.
- Tampilkan konfirmasi setelah berhasil menyimpan.
- Izinkan pengeditan sesuai kebijakan yang ditentukan.
- Jangan tampilkan data pribadi siswa pada profil publik.

Struktur database:
- reviewId
- lessonSessionId
- studentUid
- teacherUid
- rating
- impression
- messageAndExpectation
- createdAt
- updatedAt
- moderationStatus

Cegah duplikasi dengan validasi backend dan aturan database yang sesuai.

## D. Integrasi dan Pengujian

- Periksa struktur kode yang sudah ada sebelum melakukan perubahan.
- Gunakan Riverpod dan repository pattern yang konsisten dengan proyek.
- Tambahkan navigasi dari dashboard yang sesuai dengan role.
- Terapkan Firestore Security Rules.
- Uji akses siswa, guru, dan admin.
- Uji tautan Google Drive yang tidak dapat diakses.
- Uji PDF gagal dimuat dan koneksi terputus.
- Uji rating kosong, ulasan duplikat, dan sesi yang belum selesai.
- Jalankan flutter analyze dan tes yang relevan.
- Jangan mengklaim fitur selesai sebelum implementasi dan pengujian berhasil.

Kerjakan fitur ini bertahap, mulai dari UI dan model data, kemudian integrasi penyimpanan, keamanan, dan pengujian.