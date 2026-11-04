# Versi Windows PowerShell dari setup_android.sh (butuh Flutter terpasang).
# Membuat folder android/ lalu menambahkan izin INTERNET dan LOKASI.
# Aman dijalankan ulang: dilewati jika android/ sudah ada.
$ErrorActionPreference = 'Stop'

if (Test-Path 'android') {
    Write-Host 'android/ sudah ada, dilewati.'
    exit 0
}

$tmp = Join-Path $env:TEMP ('fishdex_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

flutter create --org id.fishdex --project-name fishdex --platforms=android "$tmp\gen"
if ($LASTEXITCODE -ne 0) { throw 'flutter create gagal. Pastikan Flutter sudah terpasang (flutter doctor).' }

Copy-Item "$tmp\gen\android" '.\android' -Recurse
if (Test-Path "$tmp\gen\.metadata") { Copy-Item "$tmp\gen\.metadata" '.\.metadata' }
Remove-Item $tmp -Recurse -Force

# CAMERA sengaja tidak ditambahkan: image_picker memakai aplikasi kamera bawaan.
$manifest = (Resolve-Path 'android\app\src\main\AndroidManifest.xml').Path
$text = [System.IO.File]::ReadAllText($manifest)
$perms = '<uses-permission android:name="android.permission.INTERNET"/>' + "`n    " +
         '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>' + "`n    " +
         '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>' + "`n    "
$text = $text.Replace('<application', $perms + '<application')
$text = $text.Replace('android:label="fishdex"', 'android:label="FishDex"')
[System.IO.File]::WriteAllText($manifest, $text, (New-Object System.Text.UTF8Encoding $false))

if (-not (Select-String -Path $manifest -Pattern 'ACCESS_FINE_LOCATION' -Quiet)) {
    throw "GAGAL menambah izin ke $manifest"
}
Write-Host 'Selesai: android/ dibuat dan izin ditambahkan.'
