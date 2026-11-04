import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../services/location_service.dart';

/// Geser peta sampai pin merah tepat di titik tangkapan, lalu tekan "Pakai titik ini".
/// Mengembalikan LatLng lewat Navigator.pop.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.initial,
    this.zoom = 15,
  });

  final LatLng initial;
  final double zoom;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _controller = MapController();
  late LatLng _center = widget.initial;

  Future<void> _goToMe() async {
    final r = await getCurrentLatLng();
    if (!mounted) return;
    final p = r.pos;
    if (p != null) {
      _controller.move(p, 16);
    } else if (r.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atur lokasi tangkapan')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.initial,
              initialZoom: widget.zoom,
              onPositionChanged: (camera, hasGesture) {
                _center = camera.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.tileUrl,
                userAgentPackageName: AppConfig.userAgentPackage,
              ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
                alignment: Alignment.bottomLeft,
              ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.location_on, size: 48, color: Colors.red),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 88,
            child: FloatingActionButton.small(
              heroTag: 'picker-me',
              onPressed: _goToMe,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_center),
              icon: const Icon(Icons.check),
              label: const Text('Pakai titik ini'),
            ),
          ),
        ],
      ),
    );
  }
}
