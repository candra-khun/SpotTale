# FishDex

Dex ikan hasil tangkapan sendiri untuk angler Indonesia. Flutter + Supabase + OpenStreetMap.

Alur: foto ikan → isi form → tersimpan → pin foto muncul di peta + tercatat di Dex.

## 1. Siapkan Supabase (sekali saja, gratis)

1. Buat project di https://supabase.com.
2. **SQL Editor → New query**, tempel isi `supabase/schema.sql`, tekan **Run**.
3. **Authentication → Providers → Email**: aktif. Untuk uji coba, matikan
   "Confirm email" supaya bisa langsung masuk setelah daftar.
4. **Project Settings → API**: catat **Project URL** dan **anon public key**.

## 2. Dapatkan APK tanpa install Flutter (GitHub Actions)

1. Buat repo GitHub (boleh private), unggah seluruh isi folder ini, branch `main`.
2. Repo → **Settings → Secrets and variables → Actions → New repository secret**:
   - `SUPABASE_URL` = Project URL
   - `SUPABASE_ANON_KEY` = anon public key
3. Tab **Actions → Build APK → Run workflow** (juga jalan otomatis tiap push).
4. Setelah hijau, unduh artifact **fishdex-apk** (isinya `app-release.apk`), kirim ke HP, install.
   Android akan minta izin "pasang dari sumber tidak dikenal".

## 3. Atau build di komputer sendiri

```bash
# butuh Flutter + Android SDK (Linux/macOS/Git Bash)
bash setup_android.sh
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...

# APK rilis:
flutter build apk --release \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

APK ada di `build/app/outputs/flutter-apk/app-release.apk`.

## Cara kerja

- **Offline-first**: tangkapan disimpan di HP dulu, diunggah otomatis saat ada sinyal
  (saat aplikasi dibuka, setelah simpan, atau tombol "Kirim"). Pin oranye = belum terunggah.
- **Lokasi**: diambil dari GPS HP (GPS tidak butuh sinyal seluler). Bisa diubah lewat
  "Atur di peta". Waktu tangkapan juga bisa diubah.
- **Dex**: 40 spesies air tawar & air asin yang umum dipancing di Indonesia
  (`lib/models/species.dart`). Tambah spesies baru di **akhir** daftar agar nomor Dex tidak bergeser.
- **Alat** (joran, reel, umpan): pilih dari daftar atau "Tambah baru…", tersimpan per akun.

## Belum ada / langkah berikutnya

- **Scan ikan (AI)**: masih placeholder (`lib/services/fish_scanner.dart`), jadi jenis ikan
  dipilih manual. Pasang model klasifikasi (mis. TFLite yang dilatih untuk daftar spesies ini)
  dengan membuat kelas baru yang `implements FishScanner`; form sudah menampilkan tebakan
  sebagai chip yang bisa diketuk.
- Edit/hapus tangkapan, clustering pin saat banyak, mode pin privat/dikaburkan, profil & rekor sosial.
- Foto disimpan di bucket publik (URL acak). Ubah ke bucket privat + signed URL jika perlu.
- Tile OpenStreetMap gratis hanya untuk pemakaian ringan.
