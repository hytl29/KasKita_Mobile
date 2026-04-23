# KasKita Mobile Version
KasKita adalah aplikasi manajemen kas kelas yang kini bertransformasi dari platform web menjadi aplikasi mobile berbasis Flutter. Aplikasi ini dirancang untuk mempermudah pengelolaan keuangan kelas agar lebih rapi, transparan, dan mudah diakses secara langsung dari smartphone.
Proyek ini merupakan evolusi dari KasKita Web. Dengan berpindah ke Flutter, KasKita menawarkan pengalaman pengguna yang lebih responsif dan fitur yang lebih terintegrasi dengan fungsi smartphone (coming soon).

# Tech Stack
Frontend: Flutter (Dart)
IDE: Android Studio / VS Code
Backend: PHP (sebagai REST API)
Database: MySQL
Local Server: XAMPP
Networking: Http

# Instalasi & Konfigurasi
1. Persiapan Database & API
  Pastikan XAMPP berjalan (Apache & MySQL).
  Import database db_kaskita.sql melalui phpMyAdmin.
  Letakkan folder backend API (PHP) di dalam direktori htdocs.
  Sesuaikan konfigurasi koneksi database di file PHP Anda.

2. Persiapan Flutter
   Jalankan perintah berikut di terminal untuk mengambil dependensi:
   ```bash
    flutter pub get
    ```
