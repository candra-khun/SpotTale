/// Nilai Supabase diisi saat build/run lewat --dart-define, jadi tidak ada kunci di kode.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const photoBucket = 'catch-photos';

  // Peta OpenStreetMap (gratis, tanpa API key). Cocok untuk pemakaian ringan;
  // untuk pengguna banyak, pindah ke penyedia tile berbayar/self-host.
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgentPackage = 'id.fishdex.fishdex';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
