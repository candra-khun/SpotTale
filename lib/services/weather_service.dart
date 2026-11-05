import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class WeatherInfo {
  const WeatherInfo({
    required this.temperature,
    required this.weatherCode,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.humidity,
    this.locationName,
  });

  final double temperature;
  final int weatherCode;
  final String description;
  final IconData icon;
  final double windSpeed;
  final int humidity;
  final String? locationName;

  static (String, IconData) parseWmoCode(int code) {
    switch (code) {
      case 0:
        return ('Cerah', Icons.wb_sunny);
      case 1:
        return ('Cerah Berawan', Icons.wb_cloudy_outlined);
      case 2:
        return ('Sebagian Berawan', Icons.cloud_outlined);
      case 3:
        return ('Mendung', Icons.cloud);
      case 45:
      case 48:
        return ('Berkabut', Icons.foggy);
      case 51:
      case 53:
      case 55:
        return ('Gerimis', Icons.grain);
      case 61:
      case 63:
      case 65:
        return ('Hujan', Icons.water_drop);
      case 80:
      case 81:
      case 82:
        return ('Hujan Lebat', Icons.umbrella);
      case 95:
      case 96:
      case 99:
        return ('Badai Petir', Icons.thunderstorm);
      default:
        return ('Berawan', Icons.cloud);
    }
  }
}

class WeatherService {
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  /// Mengambil data cuaca berdasarkan koordinat perangkat
  static Future<WeatherInfo?> fetchWeather(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=${lat.toStringAsFixed(4)}&longitude=${lng.toStringAsFixed(4)}'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      );

      final req = await _client.getUrl(url);
      final res = await req.close();
      if (res.statusCode != 200) return null;

      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      final temp = (current['temperature_2m'] as num).toDouble();
      final code = (current['weather_code'] as num).toInt();
      final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
      final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;

      final (desc, icon) = WeatherInfo.parseWmoCode(code);

      // Coba ambil nama kota/wilayah singkat
      String? locName;
      try {
        final geoUrl = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?'
          'latitude=${lat.toStringAsFixed(4)}&longitude=${lng.toStringAsFixed(4)}&localityLanguage=id',
        );
        final geoReq = await _client.getUrl(geoUrl);
        final geoRes = await geoReq.close();
        if (geoRes.statusCode == 200) {
          final geoBody = await geoRes.transform(utf8.decoder).join();
          final geoData = jsonDecode(geoBody) as Map<String, dynamic>;
          locName = (geoData['city'] as String?)?.isNotEmpty == true
              ? geoData['city'] as String
              : (geoData['locality'] as String?)?.isNotEmpty == true
                  ? geoData['locality'] as String
                  : (geoData['principalSubdivision'] as String?);
        }
      } catch (_) {}

      return WeatherInfo(
        temperature: temp,
        weatherCode: code,
        description: desc,
        icon: icon,
        windSpeed: wind,
        humidity: humidity,
        locationName: locName,
      );
    } catch (_) {
      return null;
    }
  }
}

