import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationResult {
  const LocationResult({this.pos, this.error});

  final LatLng? pos;
  final String? error;
}

/// GPS tidak butuh sinyal seluler, jadi biasanya tetap jalan di spot mancing.
Future<LocationResult> getCurrentLatLng() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult(error: 'GPS mati. Nyalakan lokasi di HP.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return const LocationResult(error: 'Izin lokasi ditolak.');
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LocationResult(pos: LatLng(p.latitude, p.longitude));
  } catch (_) {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return LocationResult(
          pos: LatLng(last.latitude, last.longitude),
          error: 'Memakai lokasi terakhir yang diketahui. Cek di peta.',
        );
      }
    } catch (_) {}
    return const LocationResult(
      error: 'Belum dapat sinyal GPS. Tekan "Atur di peta" untuk isi manual.',
    );
  }
}
