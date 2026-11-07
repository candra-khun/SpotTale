import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../services/catch_store.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../widgets/catch_detail.dart';
import '../widgets/fish_pin.dart';
import 'catch_form_screen.dart';

enum MapViewMode { universal, pribadi }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();
  LatLng? _me;
  bool _locating = false;
  MapViewMode _mode = MapViewMode.universal;

  WeatherInfo? _weather;
  bool _loadingWeather = false;

  @override
  void initState() {
    super.initState();
    _initDeviceWeather();
  }

  Future<void> _initDeviceWeather() async {
    final r = await getCurrentLatLng();
    final p = r.pos;
    if (p != null && mounted) {
      setState(() => _me = p);
      _fetchWeather(p.latitude, p.longitude);
    }
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    if (!mounted) return;
    setState(() => _loadingWeather = true);
    final w = await WeatherService.fetchWeather(lat, lng);
    if (!mounted) return;
    setState(() {
      _weather = w;
      _loadingWeather = false;
    });
  }

  Future<void> _goToMe({bool silent = false}) async {
    setState(() => _locating = true);
    final r = await getCurrentLatLng();
    if (!mounted) return;
    setState(() => _locating = false);

    final p = r.pos;
    if (p != null) {
      setState(() => _me = p);
      _controller.move(p, 14);
      _fetchWeather(p.latitude, p.longitude);
    } else if (!silent && r.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatchStore>();
    final records = _mode == MapViewMode.universal
        ? store.universalCatches
        : store.myCatches;
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
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (store.pendingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PendingBanner(store: store),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SegmentedButton<MapViewMode>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.transparent,
                        selectedBackgroundColor: Colors.teal.shade700,
                        selectedForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: BorderSide.none,
                      ),
                      segments: [
                        ButtonSegment(
                          value: MapViewMode.universal,
                          label: Text(
                            'Universal (${store.universalCatches.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          icon: const Icon(Icons.public, size: 18),
                        ),
                        ButtonSegment(
                          value: MapViewMode.pribadi,
                          label: Text(
                            'Pribadi (${store.myCatches.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          icon: const Icon(Icons.person, size: 18),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (newSelection) {
                        setState(() => _mode = newSelection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _WeatherBadge(
                      weather: _weather,
                      loading: _loadingWeather,
                      onTap: () {
                        if (_me != null) {
                          _fetchWeather(_me!.latitude, _me!.longitude);
                        } else {
                          _goToMe();
                        }
                      },
                    ),
                  ),
                ],
              ),
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

class _WeatherBadge extends StatelessWidget {
  const _WeatherBadge({
    required this.weather,
    required this.loading,
    required this.onTap,
  });

  final WeatherInfo? weather;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (loading && weather == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withAlpha(235),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Cek cuaca…',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    if (weather == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withAlpha(235),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_outlined, size: 16, color: Colors.teal),
                SizedBox(width: 6),
                Text(
                  'Cek cuaca lokasi',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final w = weather!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(240),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.shade100, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(w.icon, size: 20, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${w.temperature.round()}°C',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          w.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (w.locationName != null) ...[
                        Flexible(
                          child: Text(
                            w.locationName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(fontSize: 10, color: Colors.black45),
                        ),
                      ],
                      Icon(Icons.air, size: 11, color: Colors.blueGrey.shade400),
                      const SizedBox(width: 2),
                      Text(
                        '${w.windSpeed.toStringAsFixed(0)} km/j',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (loading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
