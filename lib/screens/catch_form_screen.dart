import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';
import '../models/catch_record.dart';
import '../models/species.dart';
import '../services/catch_store.dart';
import '../services/fish_scanner.dart';
import '../services/location_service.dart';
import '../utils.dart';
import 'location_picker_screen.dart';

/// Alur tombol "+": ambil foto -> isi form -> simpan (masuk peta + Dex).
Future<void> startNewCatch(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Foto ikan sekarang'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pilih dari galeri'),
            subtitle: const Text('Bisa pilih satu atau beberapa foto sekaligus'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  List<File> initialPhotos = [];
  if (source == ImageSource.gallery) {
    final List<XFile> files = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (files.isEmpty || !context.mounted) return;
    initialPhotos = files.map((f) => File(f.path)).toList();
  } else {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null || !context.mounted) return;
    initialPhotos = [File(file.path)];
  }

  final store = context.read<CatchStore>();

  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => CatchFormScreen(
        store: store,
        photos: initialPhotos,
        fromCamera: source == ImageSource.camera,
      ),
    ),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tersimpan. Akan diunggah otomatis saat ada sinyal.'),
      ),
    );
  }
}

class CatchFormScreen extends StatefulWidget {
  CatchFormScreen({
    super.key,
    required this.store,
    List<File>? photos,
    File? photo,
    required this.fromCamera,
  }) : photos = photos ?? (photo != null ? [photo] : const []);

  final CatchStore store;
  final List<File> photos;
  final bool fromCamera;

  @override
  State<CatchFormScreen> createState() => _CatchFormScreenState();
}

class _CatchFormScreenState extends State<CatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _custom = TextEditingController();

  late final List<File> _photos = List<File>.from(widget.photos);
  int _activePhotoIndex = 0;

  Species? _species;
  bool _speciesError = false;
  WaterType _water = WaterType.tawar;
  String? _rod;
  String? _reel;
  String? _bait;
  bool _isPublic = true;

  LatLng? _pos;
  String? _locNote;
  bool _locating = true;
  bool _saving = false;
  late DateTime _caughtAt = DateTime.now();
  late final Future<List<Species>> _suggestions =
      fishScanner.suggest(_photos.isNotEmpty ? _photos.first : File(''));

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _weight.dispose();
    _custom.dispose();
    super.dispose();
  }

  Future<void> _addMorePhotos() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Ambil foto dari kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari galeri'),
              subtitle: const Text('Bisa pilih beberapa foto sekaligus'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    if (source == ImageSource.gallery) {
      final List<XFile> picked = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _photos.addAll(picked.map((f) => File(f.path)));
        _activePhotoIndex = _photos.length - 1;
      });
    } else {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _photos.add(File(picked.path));
        _activePhotoIndex = _photos.length - 1;
      });
    }
  }

  void _removePhoto(int index) {
    if (_photos.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 foto tangkapan.')),
      );
      return;
    }
    setState(() {
      _photos.removeAt(index);
      if (_activePhotoIndex >= _photos.length) {
        _activePhotoIndex = _photos.length - 1;
      }
    });
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final r = await getCurrentLatLng();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (r.pos != null) _pos = r.pos;
      _locNote = r.error ??
          (r.pos == null
              ? 'Belum dapat sinyal GPS. Tekan "Atur di peta" untuk isi manual.'
              : null);
    });
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: _pos ?? const LatLng(-2.5, 118.0),
          zoom: _pos == null ? 5 : 15,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _pos = result;
        _locNote = null;
      });
    }
  }

  Future<void> _pickSpecies() async {
    final s = await showModalBottomSheet<Species>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SpeciesPickerSheet(),
    );
    if (s != null) _setSpecies(s);
  }

  void _setSpecies(Species s) {
    setState(() {
      _species = s;
      _speciesError = false;
      if (s.id != otherSpeciesId) _water = s.water;
    });
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _caughtAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_caughtAt),
    );
    if (t == null || !mounted) return;
    setState(() {
      _caughtAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  double? _parseWeight() {
    final t = _weight.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _speciesError = _species == null);
    if (!formOk || _species == null) return;
    if (_pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi belum ada. Tekan "Atur di peta".'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final species = _species!;
      final name = species.id == otherSpeciesId
          ? _custom.text.trim()
          : species.name;

      final user = Supabase.instance.client.auth.currentUser;
      final meta = user?.userMetadata;
      final metaName = (meta?['display_name'] as String?)?.trim();
      final anglerName = (metaName != null && metaName.isNotEmpty)
          ? metaName
          : (user?.email?.split('@').first ?? 'Angler');
      final anglerAvatarUrl = meta?['avatar_url'] as String?;

      final record = CatchRecord(
        id: const Uuid().v4(),
        userId: user?.id,
        isPublic: _isPublic,
        anglerName: anglerName,
        anglerAvatarUrl: anglerAvatarUrl,
        speciesId: species.id,
        speciesName: name,
        category: _water.name,
        weightKg: _parseWeight(),
        rod: _rod,
        reel: _reel,
        bait: _bait,
        lat: _pos!.latitude,
        lng: _pos!.longitude,
        caughtAt: _caughtAt,
        pending: true,
      );
      await widget.store.addCatch(record, _photos);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  Widget _buildPhotoSection() {
    final currentFile = _photos.isNotEmpty
        ? _photos[_activePhotoIndex.clamp(0, _photos.length - 1)]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentFile != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Image.file(currentFile, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_activePhotoIndex + 1} / ${_photos.length} foto',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              if (_photos.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 20),
                      tooltip: 'Hapus foto ini',
                      onPressed: () => _removePhoto(_activePhotoIndex),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 64,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < _photos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activePhotoIndex = i),
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: i == _activePhotoIndex
                                  ? Colors.teal
                                  : Colors.grey.shade300,
                              width: i == _activePhotoIndex ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              _photos[i],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (_photos.length > 1)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removePhoto(i),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              // Tombol tambah foto
              InkWell(
                onTap: _addMorePhotos,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.teal.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo_outlined,
                          color: Colors.teal, size: 22),
                      SizedBox(height: 2),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tangkapan baru')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(_saving ? 'Menyimpan…' : 'Simpan tangkapan'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPhotoSection(),
            const SizedBox(height: 16),

            // Tebakan hasil scan (kosong sampai model scan dipasang).
            FutureBuilder<List<Species>>(
              future: _suggestions,
              builder: (context, snap) {
                final list = snap.data ?? const <Species>[];
                if (list.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tebakan scan:'),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final s in list)
                            ActionChip(
                              label: Text(s.name),
                              onPressed: () => _setSpecies(s),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            InkWell(
              onTap: _pickSpecies,
              child: InputDecorator(
                isEmpty: _species == null,
                decoration: InputDecoration(
                  labelText: 'Jenis ikan',
                  hintText: 'Pilih jenis ikan…',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: _speciesError ? 'Pilih jenis ikan' : null,
                ),
                child: _species != null
                    ? Text(_species!.name)
                    : const SizedBox.shrink(),
              ),
            ),
            if (_species != null && _species!.id != otherSpeciesId)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  _species!.latin,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
              ),
            if (_species?.id == otherSpeciesId) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _custom,
                decoration: const InputDecoration(
                  labelText: 'Nama ikan',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Isi nama ikan'
                    : null,
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<WaterType>(
              segments: const [
                ButtonSegment(
                  value: WaterType.tawar,
                  label: Text('Air Tawar'),
                  icon: Icon(Icons.water_drop_outlined),
                ),
                ButtonSegment(
                  value: WaterType.asin,
                  label: Text('Air Asin'),
                  icon: Icon(Icons.waves),
                ),
              ],
              selected: {_water},
              onSelectionChanged: (s) => setState(() => _water = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weight,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Berat',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                final w = double.tryParse(t.replaceAll(',', '.'));
                if (w == null || w <= 0) return 'Berat tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _GearField(
              store: widget.store,
              kind: 'rod',
              label: 'Joran',
              value: _rod,
              onChanged: (v) => setState(() => _rod = v),
            ),
            const SizedBox(height: 12),
            _GearField(
              store: widget.store,
              kind: 'reel',
              label: 'Reel',
              value: _reel,
              onChanged: (v) => setState(() => _reel = v),
            ),
            const SizedBox(height: 12),
            _GearField(
              store: widget.store,
              kind: 'bait',
              label: 'Umpan',
              value: _bait,
              onChanged: (v) => setState(() => _bait = v),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Waktu tangkapan',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.edit_calendar),
                ),
                child: Text(fmtDateTime(_caughtAt)),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _isPublic
                      ? Colors.teal.shade300
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              color: _isPublic
                  ? Colors.teal.withAlpha(15)
                  : Colors.grey.withAlpha(15),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                secondary: Icon(
                  _isPublic ? Icons.public : Icons.lock_outline,
                  color: _isPublic ? Colors.teal : Colors.grey,
                  size: 28,
                ),
                title: const Text(
                  'Bagikan ke Universal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _isPublic
                      ? 'Dapat dilihat oleh semua pengguna di peta universal.'
                      : 'Hanya kamu yang bisa melihat tangkapan ini (pribadi).',
                  style: const TextStyle(fontSize: 12),
                ),
                value: _isPublic,
                onChanged: (val) => setState(() => _isPublic = val),
              ),
            ),
            const SizedBox(height: 12),
            _buildLocationCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final pos = _pos;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locating
                        ? 'Mencari lokasi…'
                        : pos == null
                            ? 'Lokasi belum didapat'
                            : '${pos.latitude.toStringAsFixed(5)}, '
                                '${pos.longitude.toStringAsFixed(5)}',
                  ),
                ),
                if (_locating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (_locNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _locNote!,
                  style: const TextStyle(color: Colors.deepOrange),
                ),
              ),
            if (!widget.fromCamera)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Foto dari galeri: lokasi memakai posisi HP saat ini. '
                  'Ubah bila tangkapan di tempat lain.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            if (pos != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: IgnorePointer(
                      child: FlutterMap(
                        key: ValueKey(pos),
                        options: MapOptions(
                          initialCenter: pos,
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: AppConfig.tileUrl,
                            userAgentPackageName: AppConfig.userAgentPackage,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: pos,
                                width: 40,
                                height: 40,
                                alignment: Alignment.topCenter,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _locating ? null : _locate,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Lokasi HP'),
                ),
                TextButton.icon(
                  onPressed: _pickOnMap,
                  icon: const Icon(Icons.edit_location_alt),
                  label: const Text('Atur di peta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ alat

const String _kAdd = '__add__';
const String _kNone = '__none__';

/// Field pilihan alat (joran/reel/umpan) dengan opsi "+ Tambah baru".
class _GearField extends StatefulWidget {
  const _GearField({
    required this.store,
    required this.kind,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final CatchStore store;
  final String kind;
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  State<_GearField> createState() => _GearFieldState();
}

class _GearFieldState extends State<_GearField> {
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final store = widget.store;

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final items = List<String>.from(store.gear[widget.kind] ?? const <String>[]);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Text(widget.label,
                                style: Theme.of(ctx).textTheme.titleMedium),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, _kNone),
                              child: const Text('Kosongkan'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _addController,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: 'Tambah ${widget.label.toLowerCase()} baru…',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () async {
                                final text = _addController.text.trim();
                                if (text.isEmpty) return;
                                _addController.clear();
                                final saved = await store.addGear(widget.kind, text);
                                if (ctx.mounted && saved != null) {
                                  Navigator.pop(ctx, saved);
                                }
                              },
                              child: const Text('Tambah'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            if (items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'Belum ada daftar tersimpan.\nKetik di atas untuk menambah.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              )
                            else
                              for (final i in items)
                                ListTile(
                                  title: Text(i),
                                  trailing: i == widget.value
                                      ? const Icon(Icons.check, color: Colors.teal)
                                      : null,
                                  onTap: () => Navigator.pop(ctx, i),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked == null || !mounted) return;

    if (picked == _kNone) {
      widget.onChanged(null);
    } else {
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _open,
      child: InputDecorator(
        isEmpty: widget.value == null,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: 'Pilih atau tambah…',
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: widget.value != null
            ? Text(widget.value!)
            : const SizedBox.shrink(),
      ),
    );
  }
}

// --------------------------------------------------------- pilih spesies

class _SpeciesPickerSheet extends StatefulWidget {
  const _SpeciesPickerSheet();

  @override
  State<_SpeciesPickerSheet> createState() => _SpeciesPickerSheetState();
}

class _SpeciesPickerSheetState extends State<_SpeciesPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = kDexSpecies
        .where((s) =>
            q.isEmpty ||
            s.name.toLowerCase().contains(q) ||
            s.latin.toLowerCase().contains(q))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari nama ikan…',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final s in list)
                    ListTile(
                      title: Text(s.name),
                      subtitle: Text(s.latin),
                      trailing: Text(
                        s.water.label,
                        style: TextStyle(color: s.water.color),
                      ),
                      onTap: () => Navigator.pop(context, s),
                    ),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text(kOtherSpecies.name),
                    subtitle: const Text('Ikan yang belum ada di daftar'),
                    onTap: () => Navigator.pop(context, kOtherSpecies),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
