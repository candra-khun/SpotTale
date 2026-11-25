// ignore: uri_does_not_exist
import 'config.local.dart' as _local;

/// Supabase credentials dibaca dari config.local.dart (lokal, tidak masuk git).
/// Jika file tidak ada, fallback ke --dart-define saat build CI/release.
class AppConfig {
  static const _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const _envKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl =>
      _envUrl.isNotEmpty ? _envUrl : _local.kSupabaseUrl;
  static String get supabaseAnonKey =>
      _envKey.isNotEmpty ? _envKey : _local.kSupabaseAnonKey;
  static const photoBucket = 'catch-photos';
  static const speciesBucket = 'species-index';

  // Peta OpenStreetMap (gratis, tanpa API key). Cocok untuk pemakaian ringan;
  // untuk pengguna banyak, pindah ke penyedia tile berbayar/self-host.
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgentPackage = 'id.fishdex.fishdex';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
