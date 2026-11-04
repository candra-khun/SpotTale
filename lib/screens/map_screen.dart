import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../services/catch_store.dart';
import '../services/location_service.dart';
import '../widgets/catch_detail.dart';
import '../widgets/fish_pin.dart';
import 'catch_form_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();
  LatLng? _me;
  bool _locating = false;

  Future<void> _goToMe({bool silent = false}) async {
    setState(() => _locating = true);
    final r = await getCurrentLatLng();
    if (!mounted) return;
    setState(() => _locating = false);

    final p = r.pos;
    if (p != null) {
      setState(() => _me = p);
      _controller.move(p, 14);
    } else if (!silent && r.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatchStore>();
    final records = store.all;
    final hasCatches = records.isNotEmpty;
    final start = hasCatches
        ? LatLng(records.first.lat, records.first.lng)
        : const LatLng(-2.5, 118.0);

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: start,
            initialZoom: hasCatches ? 12 : 4.5,
            onMapReady: () => _goToMe(silent: true),
          ),
          children: [
            TileLayer(
              urlTemplate: AppConfig.tileUrl,
              userAgentPackageName: AppConfig.userAgentPackage,
            ),
            if (_me != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _me!,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final c in records)
                  Marker(
                    point: LatLng(c.lat, c.lng),
                    width: 52,
                    height: 68,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => showCatchDetail(context, c),
                      child: FishPin(record: c),
                    ),
                  ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
              alignment: Alignment.bottomLeft,
            ),
          ],
        ),
        if (store.pendingCount > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _PendingBanner(store: store),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'fab-me',
                onPressed: _locating ? null : () => _goToMe(),
                child: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.large(
                heroTag: 'fab-add',
                onPressed: () => startNewCatch(context),
                child: const Icon(Icons.add, size: 36),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.store});

  final CatchStore store;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.cloud_upload_outlined, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${store.pendingCount} tangkapan menunggu diunggah'),
            ),
            if (store.syncing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: () => store.refresh(),
                child: const Text('Kirim'),
              ),
          ],
        ),
      ),
    );
  }
}
