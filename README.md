# KasKita Mobile Version
KasKita adalah aplikasi manajemen kas kelas yang kini bertransformasi dari platform web menjadi aplikasi mobile berbasis Flutter. Aplikasi ini dirancang untuk mempermudah pengelolaan keuangan kelas agar lebih rapi, transparan, dan mudah diakses secara langsung dari smartphone.
Proyek ini merupakan evolusi dari KasKita Web. Dengan berpindah ke Flutter, KasKita menawarkan pengalaman pengguna yang lebih responsif dan fitur yang lebih terintegrasi dengan fungsi smartphone (coming soon).

## Tech Stack
Frontend: Flutter (Dart)
IDE: Android Studio / VS Code
Backend: PHP (sebagai REST API)
Database: MySQL
Local Server: XAMPP
Networking: Http

## Instalasi & Konfigurasi
# Persiapan Database & API
  1. Pastikan XAMPP berjalan (Apache & MySQL).
  2. Import database db_kaskita.sql melalui phpMyAdmin.
  3. Letakkan folder backend API (PHP) di dalam direktori htdocs.
  4.  Sesuaikan konfigurasi koneksi database di file PHP Anda.

# Persiapan Flutter
  1. Buka proyek di Android Studio.
  2. Jalankan perintah berikut di terminal untuk mengambil dependensi:
   ```bash
    flutter pub get
   ```
  3. Sesuaikan Base URL API pada kode Dart.
     Catatan: Gunakan IP Laptop Anda (misal: 192.168.x.x) jika menggunakan perangkat fisik, atau 10.0.2.2 jika menggunakan emulator.

# Running
Hubungkan perangkat Android atau jalankan emulator
```bash
    flutter run
```
