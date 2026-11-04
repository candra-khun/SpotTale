#!/usr/bin/env bash
# Membuat folder android/ (butuh Flutter terpasang), lalu menambahkan izin
# INTERNET dan LOKASI. Aman dijalankan ulang: dilewati jika android/ sudah ada.
set -euo pipefail

if [ -d android ]; then
  echo "android/ sudah ada, dilewati."
  exit 0
fi

TMP="$(mktemp -d)"
flutter create --org id.fishdex --project-name fishdex --platforms=android "$TMP/gen"
cp -r "$TMP/gen/android" ./android
cp "$TMP/gen/.metadata" ./.metadata 2>/dev/null || true
rm -rf "$TMP"

MANIFEST="android/app/src/main/AndroidManifest.xml"

# Izin: internet + lokasi. CAMERA sengaja tidak ditambahkan: image_picker memakai
# aplikasi kamera bawaan, dan mendeklarasikan CAMERA tanpa meminta izin runtime
# justru membuat kamera gagal dibuka.
perl -0pi -e 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>\n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>\n    <application#' "$MANIFEST"
perl -pi -e 's#android:label="fishdex"#android:label="FishDex"#' "$MANIFEST"

if ! grep -q "ACCESS_FINE_LOCATION" "$MANIFEST"; then
  echo "GAGAL menambah izin ke $MANIFEST" >&2
  exit 1
fi
echo "Selesai: android/ dibuat dan izin ditambahkan."
