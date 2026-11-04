import 'dart:io';

import '../models/species.dart';

/// Antarmuka scan ikan. Mengembalikan beberapa tebakan teratas (bukan satu),
/// supaya angler tinggal memilih yang benar.
abstract class FishScanner {
  Future<List<Species>> suggest(File photo);
}

/// PLACEHOLDER: belum ada model AI yang terpasang, jadi tidak ada tebakan.
/// Form tetap berfungsi penuh dengan memilih jenis ikan secara manual.
///
/// Untuk mengaktifkan scan, buat kelas baru yang `implements FishScanner`
/// (misalnya model TFLite on-device yang dilatih untuk daftar di kDexSpecies,
/// atau panggilan ke Supabase Edge Function), lalu ganti nilai [fishScanner].
class NoopFishScanner implements FishScanner {
  @override
  Future<List<Species>> suggest(File photo) async => const <Species>[];
}

final FishScanner fishScanner = NoopFishScanner();
