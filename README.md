# Aplikasi Mobile Perpustakaan Polibatam
**Aplikasi Android Berbasis Flutter (Modular & Clean Architecture)**

Aplikasi mobile resmi untuk civitas akademika Politeknik Negeri Batam:
- Login native di dalam aplikasi dengan akun SSO `login.polibatam.ac.id` (Keycloak), tanpa browser
- Integrasi Layanan SIPP (`lib.polibatam.ac.id/sipp`)
- Penelusuran Repository Tugas Akhir & Karya Ilmiah DSpace (`repository.polibatam.ac.id`)
- In-App E-Book Reader (PDF & EPUB) dengan Keamanan Anti-Screenshot & Dynamic Watermark
- Kartu Anggota Digital dengan QR Code

---

## 1. Arsitektur Proyek (Feature-First)
Struktur proyek dirancang modular (*Feature-First*) agar mudah dipahami, dirawat, dan dikembangkan kembali oleh pengembang berikutnya tanpa takut merusak modul lain:

```text
lib/
├── core/
│   ├── constants/app_constants.dart      # Konfigurasi URL SIPP, Keycloak, & Repository
│   ├── network/api_client.dart           # Dio HTTP Client dengan Interceptor Bearer Token
│   ├── storage/secure_storage_service.dart# Enkripsi penyimpanan sesi & token
│   └── theme/app_theme.dart              # Desain & Warna Resmi Kampus Polibatam
│
├── features/
│   ├── auth/                             # Modul Login native (token Bearer dari SIPP)
│   ├── catalog/                          # Modul Katalog E-Book & Indikator Concurrency
│   ├── loans/                            # Modul Peminjaman Aktif & Timer Hitung Mundur
│   ├── reader/                           # Modul In-App Viewer (PDF & EPUB) + Watermark
│   ├── repository/                       # Modul Pencarian Karya Ilmiah DSpace
│   ├── profile/                          # Modul Kartu Anggota Digital (QR Code)
│   └── dashboard/                        # Modul Bottom Navigation
│
└── main.dart                             # Entrypoint & Routing Otentikasi
```

---

## 2. Cara Menjalankan Aplikasi
1. Pastikan Flutter SDK sudah terpasang di komputer Anda (`flutter --version` >= 3.20).
2. Masuk ke direktori aplikasi:
   ```bash
   cd /var/www/apps/polibatam_library_mobile
   ```
3. Unduh dependensi:
   ```bash
   flutter pub get
   ```
4. Jalankan di emulator / perangkat Android:
   ```bash
   flutter run
   ```
5. Untuk membuat APK rilis:
   ```bash
   flutter build apk --release
   ```

---

## 3. Fitur Keamanan Reader
- **`FLAG_SECURE`:** Mencegah pengguna mengambil tangkapan layar (*screenshot*) atau merekam layar (*screen record*) saat membaca dokumen berlisensi.
- **Dynamic Watermark:** Menampilkan cap semi-transparan `NIM - Nama Mahasiswa - Perpustakaan Polibatam` secara diagonal di setiap halaman agar dokumen tidak dapat difoto ulang secara anonim.
- **Controlled Digital Lending (CDL):** File dibaca secara streaming terenkripsi menggunakan token berwaktu. Kuota lisensi otomatis kembali saat masa pinjam berakhir.


---

## 4. Login
Aplikasi menampilkan form login sendiri (tanpa browser/webview) dengan **username & password SSO** `login.polibatam.ac.id`.

Alur: aplikasi → `POST index.php?p=api/digital/auth/login` (SIPP) → Keycloak realm `sso-polibatam`
(*Direct Access Grant*, memakai client & secret SSO yang sama dengan login web SIPP) → pencocokan/pendaftaran anggota
oleh `sipp/plugins/microsoft_oauth/sso_member.inc.php` (dipakai bersama login web) → SIPP menerbitkan token Bearer (30 hari).

Endpoint (plugin `sipp/plugins/digital_library`):
- `POST index.php?p=api/digital/auth/login`, body `{"username","password"}`
- `GET  index.php?p=api/digital/auth/me`
- `POST index.php?p=api/digital/auth/logout`

Endpoint pinjam/kembali/reservasi, daftar pinjaman, dan ringkasan anggota **wajib** menyertakan
`Authorization: Bearer <token>` dan hanya bisa mengakses data milik pemilik token.

> Syarat di Keycloak: client SSO SIPP harus mengaktifkan **Direct access grants**
> (Clients → *client* → Settings → Capability config).

---

## 5. Logo & Ikon Aplikasi
- Logo sumber: `assets/images/logo.png` (PNG persegi, latar transparan). Dipakai juga di layar login.
- Ikon launcher Android sudah dibuat dari logo tersebut:
  - `android/app/src/main/res/mipmap-*/ic_launcher.png`: ikon Android < 8 (logo di atas latar putih)
  - `android/app/src/main/res/drawable-*/ic_launcher_foreground.png`: ikon adaptif Android 8+ (logo diperkecil ke 64% agar tidak terpotong mask bulat)
  - Warna latar ikon adaptif: `ic_launcher_background` di `res/values/colors.xml` (putih)
- Untuk mengganti logo, cara termudah: Android Studio → klik kanan `android/app/src/main/res` → **New → Image Asset**,
  pilih `logo.png`, atur *Resize* sampai logo masuk lingkaran pratinjau, lalu Finish.
  (`flutter_launcher_icons` tidak dipakai: versi yang cocok dengan `epub_view` tidak bisa mengecilkan logo ikon adaptif.)
- Nama aplikasi di bawah ikon: `android:label` di `android/app/src/main/AndroidManifest.xml`.
# PolibatamLibrary
# PolibatamLibrary
